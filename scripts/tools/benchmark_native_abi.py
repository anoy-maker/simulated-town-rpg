#!/usr/bin/env python3
"""One fresh pure-library workload process; no disk/packing inside compute timer."""
import argparse,hashlib,json,time
from pathlib import Path
from native_math import Kernel,HEADER
p=argparse.ArgumentParser();p.add_argument('corpus',type=Path);p.add_argument('case');p.add_argument('copies',type=int);p.add_argument('backend',choices=['cpp','rust']);a=p.parse_args()
kernel=Kernel(a.backend);buffers=[]
for i in (1,2,3):
    raw=(a.corpus/f'{a.case}-pass{i}.bin').read_bytes();magic,v,op,n=HEADER.unpack_from(raw)
    raw=HEADER.pack(magic,v,op,n*a.copies)+raw[16:]*a.copies;buffers.append(kernel.prepare(raw))
# One unmeasured full batch; retain outputs to detect eliminated/drifting work.
for pair in buffers:assert kernel.call(pair)==0
expected=[pair[1].raw for pair in buffers]
start=time.perf_counter_ns()
for pair in buffers:assert kernel.call(pair)==0
elapsed=(time.perf_counter_ns()-start)/1000
digest=hashlib.sha256()
for pair,ref in zip(buffers,expected):
    assert pair[1].raw==ref;digest.update(pair[1].raw)
print(json.dumps(dict(kind='pure_abi',case=a.case,copies=a.copies,backend=a.backend,total_usec=elapsed,compute_usec=elapsed,pack_usec=0,call_usec=0,unpack_usec=0,digest=digest.hexdigest())))
