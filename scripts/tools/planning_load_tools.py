"""Shared M22 fresh-process capture and quantiles; no economic authority."""
import json,math,os,subprocess,tempfile,time
from pathlib import Path
from profile_simulation import ROOT,godot_environment

def quantiles(values):
    values=sorted(values);n=len(values)
    if not n:return dict(n=0,min=None,median=None,p95=None,p99=None,worst=None)
    import statistics
    return dict(n=n,min=values[0],median=statistics.median(values),p95=values[math.ceil(.95*n)-1] if n>=20 else None,p99=values[math.ceil(.99*n)-1] if n>=100 else None,worst=values[-1])
def capture(count,workers,kind='homogeneous'):
    cmd=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_planning_load.gd','--',str(count),str(workers),kind]
    start=time.perf_counter()
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        child=subprocess.Popen(cmd,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
        wall=time.perf_counter()-start;err.seek(0);error=err.read();assert child.returncode==0 and not error,(cmd,child.returncode,error.decode())
        out.seek(0);data=json.loads(out.read())
    data.update(command_seconds=wall,peak_rss_kib=usage.ru_maxrss)
    validate(data)
    return data

def validate(data):
    assert data['count']==len(data['records'])==len(data['ledger'])
    ids=[r['id'] for r in data['ledger']];assert ids==[f'work-{i:03d}' for i in range(data['count'])]
    assert all(r['status']=='completed' for r in data['ledger']) and data['world_events']==0
    assert data['maxima']['outstanding']<=16 and data['maxima']['running']<=data['workers']
    assert data['maxima']['input_bytes']<=16*65536 and data['maxima']['output_bytes']<=16*524288
    assert all(r['status']=='acknowledged' and r['owner']=='cora' for r in data['records'])
    if data['kind']=='homogeneous':
        for r in data['records']:
            assert sum(b['jobs'] for b in r['batches'] if b['op']==1)==150
            assert sum(b['jobs'] for b in r['batches'] if b['op']==2)==306
    if data['kind']=='ordering':
        finished=[r['id'] for r in sorted(data['records'],key=lambda r:r['finished_usec'])]
        assert finished!=ids and finished.index('work-000')>0

def _optional_cgroup_limit(path):
    """Unavailable cgroup metadata must not fail correctness checks or invent a quota."""
    try:
        return path.read_text().strip() or 'unavailable'
    except OSError:
        return 'unavailable'


def host():
    import platform,hashlib
    return dict(godot=subprocess.check_output(['godot','--version'],text=True,env=godot_environment()).strip(),platform=platform.platform(),machine=platform.machine(),cpus=os.cpu_count(),cpu_max=_optional_cgroup_limit(Path('/sys/fs/cgroup/cpu.max')),memory_max=_optional_cgroup_limit(Path('/sys/fs/cgroup/memory.max')),rust_sha256=hashlib.sha256((ROOT/'native/m20/bin/libm20_math.so').read_bytes()).hexdigest(),bridge_sha256=hashlib.sha256((ROOT/'native/m20/bin/libm20_bridge.so').read_bytes()).hexdigest())
