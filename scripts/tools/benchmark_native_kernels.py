#!/usr/bin/env python3
"""Three-repetition pure and Godot-boundary M20 replay, rotating language order."""
import argparse,json,os,subprocess,tempfile,time
from pathlib import Path
from native_math import ROOT
from profile_simulation import godot_environment,write_csv
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--corpus',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--source',type=Path,help='Pinned D30 canonical report; defaults to corpus parent/source.json');a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
# Export/validate the predeclared corpus before any isolated timing, never concurrently.
subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/native_corpus.gd','--',str(a.source or a.corpus.parent/'source.json'),str(a.corpus)],check=True,env=godot_environment())
def capture(command):
 start=time.perf_counter()
 with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
  child=subprocess.Popen(command,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
  err.seek(0);error=err.read();assert child.returncode==0 and not error,(command,child.returncode,error.decode())
  out.seek(0);data=json.loads(out.read())
 data.update(command_seconds=time.perf_counter()-start,peak_rss_kib=usage.ru_maxrss)
 return data
rows=[];details=[]
# Actual four recorded days; the day-15 second probe additionally scales to 10/100.
cases=[(f'D-day{d}',1) for d in (1,3,15,30)]+[('high-branch',1),('D-day15',10),('D-day15',100)]
for repeat in range(3):
 for name,copies in cases:
  order=['gdscript','cpp','rust'];order=order[repeat:]+order[:repeat]
  for backend in order:
   if backend!='gdscript':
    pure=capture(['python3','-B',str(ROOT/'scripts/tools/benchmark_native_abi.py'),str(a.corpus),name,str(copies),backend])
    pure['repeat']=repeat+1;rows.append(pure)
   cmd=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/benchmark_kernel.gd','--',str(a.corpus),name,str(copies),backend]
   data=capture(cmd);data['repeat']=repeat+1;details.append(data)
   row=dict(kind='godot_batch',case=name,copies=copies,backend=backend,repeat=repeat+1,total_usec=data['total_usec'],**{k:sum(b[k] for b in data['batches']) for k in ('compute_usec','pack_usec','call_usec','unpack_usec')},digest=data['digest'],command_seconds=data['command_seconds'],peak_rss_kib=data['peak_rss_kib']);rows.append(row)
   write_csv(a.output/'kernel-runs.csv',rows);(a.output/'kernel-details.json').write_text(json.dumps(details,separators=(',',':')))
   print(name,copies,backend,repeat+1,round(data['total_usec']/1e6,5),flush=True)
print('complete',len(rows),'samples')
