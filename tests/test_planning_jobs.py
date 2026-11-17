import csv,json,subprocess,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from measure_planning_jobs import capture,validate,ROOT
from profile_simulation import godot_environment
HAS_NATIVE=(ROOT/'native/m20/math.gdextension').exists()
class PlanningJobsTests(unittest.TestCase):
    def test_schema_and_worker_lifecycle(self):
        result=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_planning_jobs_tests.gd'],capture_output=True,env=godot_environment())
        self.assertEqual(result.returncode,0,result.stderr.decode());self.assertEqual(result.stderr,b'')
        data=json.loads(result.stdout);self.assertEqual(data['failures'],0);self.assertGreaterEqual(data['checks'],10)
    @unittest.skipUnless(HAS_NATIVE,'optional M20 native library absent')
    def test_delayed_worker_heartbeats_hold_exact_world_barrier(self):
        reference=capture('D',1,'sync');data=capture('D',1,'scheduled',500)
        validate(reference);validate(data)
        self.assertEqual(reference['report'],data['report']);self.assertEqual(reference['events'],data['events'])
        m=data['measurement'];self.assertGreaterEqual(m['barrier_heartbeats'],25)
        self.assertGreaterEqual(m['jobs'][0]['worker_wall_usec'],500000)
        self.assertLess(max(x['usec'] for x in m['callbacks'] if x['barrier']),50000)
    @unittest.skipUnless(HAS_NATIVE,'optional M20 native library absent')
    def test_stale_and_cancel_fixtures(self):
        for fixture in ('funds','inventory','quote','supplier','beliefs','presence','cancel'):
            with self.subTest(fixture=fixture):
                data=capture('D',1,'scheduled',100,fixture);validate(data)
                jobs=data['measurement']['jobs']
                self.assertEqual(jobs[0]['day'],jobs[1]['day']);self.assertEqual(jobs[0]['minute'],jobs[1]['minute'])
                if fixture in ('supplier','presence'):
                    self.assertEqual(jobs[0]['input_hash'],jobs[1]['input_hash'])
                    self.assertNotEqual(jobs[0]['validity_hash'],jobs[1]['validity_hash'])
    @unittest.skipUnless(HAS_NATIVE,'optional M20 native library absent')
    def test_three_day_proposal_and_ledger_replay(self):
        for stage in 'CD':
            reference=capture(stage,3,'sync');data=capture(stage,3,'scheduled');validate(reference);validate(data)
            self.assertEqual(reference['report'],data['report']);self.assertEqual(reference['events'],data['events'])
            self.assertEqual([j['id'] for j in data['measurement']['jobs']],[1,2,3])
