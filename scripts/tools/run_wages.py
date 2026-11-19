#!/usr/bin/env python3
"""M30 frozen direct wage bidding capture, audits and F economic controls."""
import argparse,copy,csv,gzip,hashlib,json,os,subprocess,tempfile,time
from pathlib import Path
from profile_simulation import ROOT,godot_environment
from run_input import identity as input_identity
from run_cash_allocation import capture as capture_old
from cash_allocation_audit import analyze as audit_old
from wage_audit import analyze,BASE,NEW
from wage_calculation import ARMS
from run_brewery import digest
from run_economic_diagnostics import write_json,write_rows


def capture(condition='scarce',days=3,arm='fixed10_instrumented',allocation='original',script='res://scripts/tools/run_wages.gd',fixture=''):
 cmd=['godot','--headless','--no-header','--path',str(ROOT),'--script',script,'--','--condition',condition,'--arm',arm,'--allocation',allocation,*(['--fixture',fixture] if fixture else []),str(days),'42','--measure'];stamp=time.perf_counter()
 with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
  child=subprocess.Popen(cmd,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status);wall=time.perf_counter()-stamp
  err.seek(0);error=err.read();assert child.returncode==0 and not error,(cmd,child.returncode,error.decode());out.seek(0);data=json.loads(out.read())
 data['measurement'].update(command_seconds=wall,peak_rss_kib=usage.ru_maxrss);return data


def parity(new,old):
 events=[e for e in new['events'] if e['action'] not in NEW];ids={e['id']:i for i,e in enumerate(events,1)}
 vectors={'sample_ids','order_ids','sale_ids','source_ids','receipt_ids','witness_clock_ids','empty_inspection_ids','purchase_event_ids','sample_order_ids'}
 def walk(v,key=''):
  if isinstance(v,dict):return {k:walk(x,k) for k,x in v.items() if k!='wage_market'}
  if isinstance(v,list):return [ids[x] if key in vectors and type(x) is int else walk(x,key[:-1] if key.endswith('_ids') else key) for x in v]
  if type(v) is int and (key=='id' or key.endswith('event_id') or key.endswith('receipt_id')):return ids[v] if v else v
  return v
 kept=walk(events);assert kept==old['events'],'F native economic event/receipt drift'
 r=walk(new['report']);r['scenario']='settlement_cash_allocation';r['event_count']=len(kept);r['ledger_sha256']=hashlib.sha256(json.dumps(kept,sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
 assert r==old['report'],('F full economic report drift',[k for k in r if r[k]!=old['report'].get(k)])
 return dict(all_native_events=True,full_normalized_report=True,normalized_ledger_sha256=r['ledger_sha256'],instrumented_ledger_sha256=new['report']['ledger_sha256'])


def load_trace(path):
 with gzip.open(path,'rt') as f:return json.load(f)

def save_trace(path,data):
 path.parent.mkdir(parents=True,exist_ok=True)
 with gzip.open(path,'wt',compresslevel=3) as f:json.dump(data,f,separators=(',',':'),sort_keys=True)


def identity():
 result=input_identity();result.update(base=BASE,wage_cli=digest((ROOT/'scripts/tools/run_wages.gd').read_text()),wage_policy=digest((ROOT/'scripts/sim/wage_policy.gd').read_text()))
 return result


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--traces',type=Path,required=True);p.add_argument('--checkpoint',action='store_true');p.add_argument('--reuse-checkpoint',action='store_true');p.add_argument('--old-traces',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);a.traces.mkdir(parents=True,exist_ok=True);model=identity();start=time.perf_counter()
 cases=[(c,d,arm,'original') for d in ([1,3] if a.checkpoint else [1,3,30]) for c in ['reference','tight','scarce','no_brew_request'] for arm in ARMS]
 if not a.checkpoint:cases +=[(c,30,arm,'households_330') for c in ['scarce','no_brew_request'] for arm in ARMS]
 pins={(r['condition'],r['days'],r['allocation']):r for r in csv.DictReader((ROOT/'docs/M30_CONTROL_PINS.csv').open())}
 runs=[];perf=[];parities=[]
 for c,d,arm,allocation in cases:
  tag=dict(condition=c,days=d,arm=arm,allocation=allocation,seed=42,stratum='core' if allocation=='original' else 'household_sensitivity');name=f'{c}-{d}-{arm}-{allocation}';first=None
  for repeat in [1,2]:
   path=a.traces/(name+f'-{repeat}.json.gz');meta=path.with_name(path.name+'.meta.json');reused=a.reuse_checkpoint and d in [1,3] and path.exists()
   if reused:assert json.loads(meta.read_text())==model;data=load_trace(path)
   else:data=capture(c,d,arm,allocation);save_trace(path,data);write_json(meta,model)
   stamp=time.perf_counter();diagnostic=analyze(data);audit_seconds=time.perf_counter()-stamp;m=data['measurement']
   perf.append(dict(**tag,repeat=repeat,reused_checkpoint=reused,run_seconds=m['run_usec']/1e6,report_seconds=m['report_usec']/1e6,command_seconds=m['command_seconds'],peak_rss_kib=m['peak_rss_kib'],events=len(data['events']),audit_seconds=audit_seconds,worst_appointment_ms=max(x['usec'] for x in m['appointments'])/1000,worst_tick_ms=max(x['usec'] for x in m['ticks'])/1000))
   if first is None:first=data;write_json(a.output/'analyses'/(name+'.json'),diagnostic)
   else:assert first['report']==data['report'] and first['events']==data['events']
  if arm==ARMS[0]:
   cached=a.old_traces/f'{c}-{d}-R_input_aware-{allocation}-1.json' if a.old_traces else None
   old=json.loads(cached.read_text()) if cached and cached.exists() else capture_old(c,d,'R_input_aware',allocation);audit_old(old);pin=pins[c,str(d),allocation]
   control=copy.deepcopy(old['report'])
   if pin['source_table']=='M28_RUNS.csv':control.pop('cash_allocation');control['scenario']='settlement_input_reliability'
   assert digest(dict(report=control))==pin['summary_sha256'] and old['report']['ledger_sha256']==pin['ledger_sha256'];parities.append(dict(**tag,source_table=pin['source_table'],**parity(first,old)))
  r=first['report'];ds=r['day_results'];workers=r['contracts']['workers']
  runs.append(dict(**tag,meals=sum(x['resident_meals'] for x in ds),missed=sum(x['unmet_meals'] for x in ds),visitor_bread=sum(x['visitor_bread'] for x in ds),productive=sum(x['shifts'] for x in ds),standby=sum(x['standby'] for x in workers.values()),cash_wages=sum(x['cash_wages'] for x in workers.values()),arrears=sum(x['arrears'] for x in workers.values()),**r['totals']['produced'],circulation=r['money']['circulation'],currency=r['money']['final'],active_jobs=len(r['final']['affiliations']),successful_purchases=r['purchases']['successful'],rejected_purchases=r['purchases']['rejected'],**r['contracts']['counts'],summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256']))
  for label,values in [('runs',runs),('performance',perf),('parity',parities)]:
   if values:write_rows(a.output/(label+'.csv'),values)
  write_json(a.output/'reports'/(name+'.json'),dict(report=r));print(name,'full audit/replay PASS'+('; M29 F economic parity PASS' if arm==ARMS[0] else ''),flush=True)
 write_json(a.output/'verification.json',dict(cases=len(cases),captures=2*len(cases),F_parity_cases=len(parities),model=model,command_seconds=time.perf_counter()-start))

if __name__=='__main__':main()
