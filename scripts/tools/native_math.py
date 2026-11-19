"""M20 schema helper for independent tests/benchmarks; not simulation authority."""
import ctypes,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
HEADER=struct.Struct('<4sIII')
def packet(op,jobs):
    out=bytearray(HEADER.pack(b'M20K',1,op,len(jobs)))
    for job in jobs:
        out.extend(struct.pack('<4I',job['price'],job['carry'] if op==1 else job['supply'],13,0))
        values=([x for c in ('local','visitor') for field in ('alpha','weights') for x in job['b'][c][field]] if op==1
                else job['state']+[x for row in job['forecast'] for x in row])
        out.extend(struct.pack('<%dd'%len(values),*values))
    return bytes(out)
def parse(raw):
    magic,version,op,n=HEADER.unpack_from(raw);assert magic==b'M20K' and version==1
    stride=432 if op==1 else 2648;assert len(raw)==16+n*stride
    jobs=[]
    for j in range(n):
        off=16+j*stride;p,aux,periods,reserved=struct.unpack_from('<4I',raw,off);assert periods==13 and reserved==0
        if op==1:
            v=struct.unpack_from('<52d',raw,off+16)
            jobs.append(dict(price=p,carry=aux,b={c:dict(alpha=list(v[i*26:i*26+13]),weights=list(v[i*26+13:(i+1)*26])) for i,c in enumerate(('local','visitor'))}))
        else:
            v=struct.unpack_from('<329d',raw,off+16)
            jobs.append(dict(price=p,supply=aux,state=list(v[:4]),forecast=[list(v[4+t*25:4+(t+1)*25]) for t in range(13)]))
    return op,jobs
def flatten(values):
    for v in values:
        if isinstance(v,list):yield from flatten(v)
        else:yield v
class Kernel:
    def __init__(self,backend,sanitize=False):
        suffix='cpp_sanitize' if sanitize else 'cpp' if backend=='cpp' else 'math'
        self.lib=ctypes.CDLL(str(ROOT/'native/m20/bin'/f'libm20_{suffix}.so'))
        self.function=getattr(self.lib,f'm20_{backend}_compute')
        self.function.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t]
        self.function.restype=ctypes.c_int
    def prepare(self,raw):
        _,_,op,n=HEADER.unpack_from(raw)
        return ctypes.create_string_buffer(raw),ctypes.create_string_buffer(16+n*(325 if op==1 else 1)*8)
    def call(self,buffers):
        src,dst=buffers
        return self.function(src,len(src)-1,dst,len(dst))
    def values(self,raw):
        buffers=self.prepare(raw);status=self.call(buffers)
        if status:raise ValueError(f'kernel status {status}')
        out=buffers[1].raw;assert out[:16]==raw[:16]
        return list(struct.unpack_from('<%dd'%((len(out)-16)//8),out,16))
