#!/usr/bin/env python3
"""Check every recorded output; independently recompute selected raw-input jobs."""
import argparse,json,math,time
from pathlib import Path
from native_math import Kernel,parse,flatten
from learning_audit import hazard,demand,sales,operate,close

def independent_forecast(job):
    b=job['b'];out=[]
    for _ in range(13):b=hazard(b);out.append(sales(demand(b,job['price'],job['carry']),24))
    return out

def independent_continuation(job):
    # Raw sales-PMF inputs, independently written financial transitions, no native code.
    f=job['forecast'];first=operate(job['state'],True,job['supply'])['state'];stock=int(first[2]);totals=[0.]*(min(24,stock)+1)
    for q,p in enumerate(f[0]):totals[min(q,stock)]+=p
    value=0.
    for sold,prob in enumerate(totals):
        if prob<1e-12:continue
        result=close(first,job['price'],sold);s=result['state'];branch=result['payout']
        for t in range(1,13):
            s=operate(s,True,job['supply'])['state'];expected=sum(min(s[2],q)*p for q,p in enumerate(f[t]))
            result=close(s,job['price'],expected);s=result['state'];branch+=.99**t*result['payout']
        value+=prob*(branch+.99**12*s[0])
    return value

def verify(folder,sanitize=False):
    rows=[]
    for backend in (['cpp'] if sanitize else ['cpp','rust']):
        kernel=Kernel(backend,sanitize)
        for name in json.loads((folder/'manifest.json').read_text()):
            raw=(folder/(name+'.bin')).read_bytes();expected=list(flatten(json.loads((folder/(name+'.json')).read_text())))
            actual=kernel.values(raw);assert len(actual)==len(expected)
            error=max((abs(a-b) for a,b in zip(actual,expected)),default=0);assert error<=1e-9,(backend,name,error)
            assert actual==kernel.values(raw),(backend,name,'nondeterministic')
            op,jobs=parse(raw);independent_error=0
            # Every boundary job, and first/middle/last job of each actual batch.
            for j in (range(len(jobs)) if name=='boundaries' else sorted({0,len(jobs)//2,len(jobs)-1})):
                oracle=list(flatten(independent_forecast(jobs[j]))) if op==1 else [independent_continuation(jobs[j])]
                values=actual[j*325:(j+1)*325] if op==1 else [actual[j]]
                delta=max(abs(a-b) for a,b in zip(values,oracle));assert delta<=1e-9,(backend,name,j,delta)
                independent_error=max(independent_error,delta)
            if op==1:
                assert max(abs(sum(actual[i:i+25])-1) for i in range(0,len(actual),25))<=1e-12
            rows.append(dict(backend=backend,case=name,jobs=len(jobs),values=len(actual),max_gdscript_error=error,max_python_error=independent_error))
    return rows
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('corpus',type=Path);p.add_argument('--sanitize',action='store_true');a=p.parse_args()
    rows=verify(a.corpus,a.sanitize);print(json.dumps(rows,indent=2))
