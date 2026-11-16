import ctypes,csv,hashlib,math,shutil,struct,subprocess,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from native_math import ROOT,Kernel,packet
from learning_audit import fresh
from verify_native_corpus import independent_forecast,independent_continuation

@unittest.skipUnless((ROOT/'native/m20/bin/libm20_math.so').exists() and (ROOT/'native/m20/bin/libm20_cpp.so').exists(),'M20 optional native libraries not built')
class NativeMathTests(unittest.TestCase):
    def test_forecasts_finances_and_no_mutation(self):
        job=dict(price=6,carry=3,b=fresh());raw=packet(1,[job]);expected=independent_forecast(job)
        for language in ('cpp','rust'):
            kernel=Kernel(language);buffers=kernel.prepare(raw);before=buffers[0].raw
            self.assertEqual(kernel.call(buffers),0);self.assertEqual(buffers[0].raw,before)
            actual=kernel.values(raw);self.assertLessEqual(max(abs(a-b) for a,b in zip(actual,[x for row in expected for x in row])),1e-9)
            self.assertLessEqual(max(abs(sum(actual[i:i+25])-1) for i in range(0,len(actual),25)),1e-12)
            for state in ([0,0,0,0],[54,0,24,0],[300,12,23.999999998,180]):
                task=dict(price=6,supply=12,state=state,forecast=[actual[i:i+25] for i in range(0,len(actual),25)])
                packed=packet(2,[task]);v=kernel.values(packed)
                self.assertEqual(v,kernel.values(packed));self.assertLessEqual(abs(v[0]-independent_continuation(task)),1e-9)
    def test_rejection_is_atomic_and_bounded(self):
        valid=packet(1,[dict(price=6,carry=3,b=fresh())])
        forecast=independent_forecast(dict(price=6,carry=3,b=fresh()))
        bad=[valid[:-1],b'BAD!'+valid[4:],valid[:4]+struct.pack('<I',2)+valid[8:],valid[:12]+struct.pack('<I',100001)+valid[16:]]
        for cash in (-1,math.nan,math.inf):bad.append(packet(2,[dict(price=6,supply=12,state=[cash,0,0,0],forecast=forecast)]))
        for p in (0,13):bad.append(packet(1,[dict(price=p,carry=3,b=fresh())]))
        malformed=fresh();malformed['local']['alpha'][0]=0;bad.append(packet(1,[dict(price=6,carry=3,b=malformed)]))
        malformed=fresh();malformed['visitor']['weights'][0]=-.1;bad.append(packet(1,[dict(price=6,carry=3,b=malformed)]))
        # A valid first job followed by an invalid second job must not publish partial output.
        invalid=packet(1,[dict(price=0,carry=3,b=fresh())]);bad.append(valid[:12]+struct.pack('<I',2)+valid[16:]+invalid[16:])
        for language in ('cpp','rust'):
            kernel=Kernel(language)
            for raw in bad:
                src=ctypes.create_string_buffer(raw);op,n=struct.unpack_from('<II',raw,8);capacity=16+n*(325 if op==1 else 1)*8 if n<=100000 else 16;dst=ctypes.create_string_buffer(b'X'*capacity,capacity);before=dst.raw
                self.assertNotEqual(kernel.function(src,len(raw),dst,len(dst)),0);self.assertEqual(dst.raw,before)
            self.assertEqual(kernel.values(packet(1,[])),[])
            self.assertEqual(kernel.values(packet(2,[])),[])

class NativeLoadingTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('godot'),'Godot unavailable')
    def test_optional_loading_fails_closed_and_default_is_historical(self):
        from profile_simulation import godot_environment
        descriptor=ROOT/'native/m20/math.gdextension';saved=descriptor.read_bytes() if descriptor.exists() else None
        try:
            descriptor.unlink(missing_ok=True)
            base=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_simulation.gd','--','--scenario','settlement_spatial_learning','--stage','D']
            unavailable=subprocess.run(base+['--backend','cpp','1','42','--report-json'],capture_output=True,env=godot_environment())
            self.assertEqual(unavailable.returncode,2);self.assertIn(b'Native backend unavailable',unavailable.stderr)
            default=subprocess.run(base+['1','42','--report-json'],capture_output=True,env=godot_environment())
            self.assertEqual(default.returncode,0);self.assertEqual(default.stderr,b'')
            with (ROOT/'docs/M18_RUNS.csv').open() as f:pin=next(r for r in csv.DictReader(f) if r['stage']=='D' and r['days']=='1')
            self.assertEqual(hashlib.sha256(default.stdout).hexdigest(),pin['summary_sha256'])
        finally:
            if saved is not None:descriptor.write_bytes(saved)
