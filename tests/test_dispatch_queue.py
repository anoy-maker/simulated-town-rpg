import json,subprocess,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from planning_load_tools import capture,quantiles
from profile_simulation import ROOT,godot_environment
from performance_smoke import regression_warnings
class GuardrailTests(unittest.TestCase):
    def test_relative_warnings_are_diagnostics(self):
        host=dict(godot='4.6',machine='x86',cpu_max='two',rust_sha256='same')
        base=dict(host=host,cases=dict(queue10=dict(run_seconds=1,peak_rss_kib=65536,callback_ms=quantiles([1]*100))))
        worse=dict(host=host,cases=dict(queue10=dict(run_seconds=2,peak_rss_kib=131072,callback_ms=quantiles([20]*100))))
        comparable,warnings=regression_warnings(worse,base)
        self.assertTrue(comparable);self.assertEqual(len(warnings),3)
        worse['host']=dict(host,cpu_max='different');self.assertFalse(regression_warnings(worse,base)[0])
    def test_sample_size_quantiles(self):
        self.assertIsNone(quantiles([1,2,3])['p95']);self.assertIsNone(quantiles(list(range(20)))['p99'])
        self.assertEqual(quantiles(list(range(100)))['p99'],98)
class DispatchTests(unittest.TestCase):
    def test_schema_and_lifecycle(self):
        result=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_dispatch_queue_tests.gd'],capture_output=True,env=godot_environment())
        self.assertEqual(result.returncode,0,result.stderr.decode());self.assertEqual(result.stderr,b'')
        self.assertEqual(json.loads(result.stdout)['failures'],0)
    @unittest.skipUnless((ROOT/'native/m20/math.gdextension').exists(),'optional native library absent')
    def test_pool_and_order_parity(self):
        one=capture(10,1);four=capture(10,4)
        self.assertEqual(one['proposal_digest'],four['proposal_digest']);self.assertEqual(one['release_digest'],four['release_digest'])
        changed=capture(10,2,'ordering');self.assertEqual([x['id'] for x in changed['ledger']],[f'work-{i:03d}' for i in range(10)])
