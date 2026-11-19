"""Opt-in profiling observes, never changes economic/model output."""
import csv,sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/tools'))
from profile_simulation import capture

class ProfilingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.plain=capture(ROOT,'D',1,'learning',False)
        cls.profiled=capture(ROOT,'D',1,'learning',True)
    def test_opt_in_preserves_complete_report_and_ledger(self):
        self.assertEqual(self.plain['report'],self.profiled['report'])
        self.assertEqual(self.plain['events'],self.profiled['events'])
        with (ROOT/'docs/M18_RUNS.csv').open() as stream:
            row=next(r for r in csv.DictReader(stream) if r['stage']=='D' and r['days']=='1')
        self.assertEqual(self.profiled['measurement']['canonical_sha256'],row['summary_sha256'])
    def test_disabled_instrumentation_is_empty(self):
        self.assertEqual(self.plain['measurement']['run_profile'],dict(phases={},counts={},decisions=[]))
    def test_exclusive_timings_counters_and_rss_are_consistent(self):
        m=self.profiled['measurement'];p=m['run_profile']
        self.assertLessEqual(sum(x['exclusive_usec'] for x in p['phases'].values()),m['run_usec'])
        self.assertTrue(all(x['inclusive_usec']>=x['exclusive_usec']>=0 for x in p['phases'].values()))
        self.assertEqual(p['counts']['events']+1,m['event_count'])
        self.assertEqual(p['counts']['candidates'],3)
        self.assertEqual(p['counts']['continuation_calls'],189)
        self.assertGreater(p['counts']['full_mean_hits'],0)
        self.assertGreater(m['command_peak_rss_kib'],0)
        self.assertGreaterEqual(m['command_peak_rss_kib'],m['run_hwm_kib'])

if __name__=='__main__':unittest.main()
