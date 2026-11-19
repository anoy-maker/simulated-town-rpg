"""M31 orchestration and immutable-raw-evidence boundaries; original audits stay strict."""
import contextlib
import copy
import csv
import gzip
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
import verify_workflow as flow

CASE=dict(kind='wage',condition='scarce',days=1,arm='worker_bids',allocation='original',seed=42)
PIN=dict(table='fixture',summary_sha256='expected',ledger_sha256='ledger')
RAW=dict(report=dict(result=1),events=[dict(id=1)])

class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup);self.cache=Path(self.temp.name)/'cache'
        self.proof=dict(source_attested=True,files={'policy.gd':'source'},engine={'version':'4.6.3','sha256':'engine'},build={'library':'binary','flags':'release'})

    def fake(self):
        stack=contextlib.ExitStack();self.addCleanup(stack.close)
        stack.enter_context(patch.object(flow,'expected',return_value=PIN))
        capture=stack.enter_context(patch.object(flow,'capture',side_effect=lambda c:copy.deepcopy(RAW)))
        audit=stack.enter_context(patch.object(flow,'validate'))
        return capture,audit

    def test_cache_reuses_two_distinct_captures_but_never_audit_conclusions(self):
        capture,audit=self.fake()
        for _ in range(2):
            for repeat in (1,2):flow.load_case(CASE,self.proof,self.cache,repeat)
        self.assertEqual(capture.call_count,2);self.assertEqual(audit.call_count,4)
        self.assertEqual(len(list(self.cache.glob('*.json.gz'))),2)

    def test_source_engine_build_inputs_and_expectations_invalidate(self):
        capture,audit=self.fake();flow.load_case(CASE,self.proof,self.cache,1)
        for field in ('files','engine','build'):
            changed=copy.deepcopy(self.proof);changed[field]['new_dependency']='changed'
            _,row=flow.load_case(CASE,changed,self.cache,1);self.assertEqual(row['cache'],'miss')
        _,row=flow.load_case(dict(CASE,arm='fixed10_instrumented'),self.proof,self.cache,1);self.assertEqual(row['cache'],'miss')
        with patch.object(flow,'expected',return_value=dict(PIN,summary_sha256='changed')):
            _,row=flow.load_case(CASE,self.proof,self.cache,1);self.assertEqual(row['cache'],'miss')
        self.assertEqual(capture.call_count,6);self.assertEqual(audit.call_count,6)

    def test_uncertain_modified_source_is_never_reused(self):
        capture,audit=self.fake();unknown=dict(self.proof,source_attested=False)
        for _ in range(2):
            _,row=flow.load_case(CASE,unknown,self.cache,1)
            self.assertEqual(row['cache'],'unattested_source_recapture')
        self.assertEqual(capture.call_count,2);self.assertEqual(audit.call_count,2)
        self.assertFalse(self.cache.exists())

    def test_missing_or_corrupt_receipt_recaptures_explicitly(self):
        capture,_=self.fake();flow.load_case(CASE,self.proof,self.cache,1)
        meta=next(self.cache.glob('*.receipt.json'));meta.write_text('{bad')
        _,row=flow.load_case(CASE,self.proof,self.cache,1);self.assertEqual(row['cache'],'corrupt_recapture')
        next(self.cache.glob('*.json.gz')).write_bytes(b'broken')
        _,row=flow.load_case(CASE,self.proof,self.cache,1);self.assertEqual(row['cache'],'invalid_receipt_recapture')
        meta.unlink()
        _,row=flow.load_case(CASE,self.proof,self.cache,1);self.assertEqual(row['cache'],'miss')
        self.assertEqual(capture.call_count,4)

    def test_rehashed_cache_cannot_bypass_reauditing(self):
        capture,_=self.fake();flow.load_case(CASE,self.proof,self.cache,1)
        payload=next(self.cache.glob('*.json.gz'));meta=next(self.cache.glob('*.receipt.json'))
        with gzip.open(payload,'wt') as f:json.dump(dict(RAW,events=[dict(id=999)]),f)
        receipt=json.loads(meta.read_text());receipt['payload_sha256']=flow.sha(payload);flow.save(meta,receipt)
        with patch.object(flow,'validate',side_effect=AssertionError('forged native evidence')):
            with self.assertRaises(AssertionError):flow.load_case(CASE,self.proof,self.cache,1)
        self.assertEqual(capture.call_count,1)

    def test_untracked_new_dependencies_and_deletion_change_closure(self):
        root=Path(self.temp.name);(root/'policy.gd').write_text('original')
        before=flow.dependencies(root);(root/'untracked.py').write_text('new import')
        self.assertNotEqual(before,flow.dependencies(root));(root/'policy.gd').unlink()
        self.assertNotIn('policy.gd',flow.dependencies(root))

    def test_uncertain_symlink_or_runtime_dependency_fails_closed(self):
        root=Path(self.temp.name);(root/'outside').symlink_to('/tmp',target_is_directory=True)
        with self.assertRaises(ValueError):flow.dependencies(root)
        broken=subprocess.CompletedProcess([],0,stdout='libunknown.so => not found',stderr='')
        with patch.object(flow.subprocess,'run',return_value=broken):
            with self.assertRaises(ValueError):flow.shared_libraries(['engine'])

    def test_wrong_seed_or_missing_expected_case_is_not_a_cache_hit(self):
        with self.assertRaises(ValueError):flow.expected(dict(CASE,seed=7))
        with self.assertRaises(ValueError):flow.expected(dict(CASE,arm='unknown'))

    def test_optimized_python_cannot_disable_independent_assertions(self):
        with patch.object(flow.sys,'flags',type('Flags',(),dict(optimize=1))()):
            with self.assertRaises(RuntimeError):flow.require_assertions()

    def test_real_subprocess_failure_is_reported_and_nonzero(self):
        with self.assertRaises(RuntimeError) as error:
            flow.run_command('failing',[sys.executable,'-c','raise SystemExit(7)'],Path(self.temp.name))
        self.assertEqual(error.exception.args[0]['status'],7)

    def test_json_counters_report_counts_and_cannot_hide_failure_behind_zero_exit(self):
        output=Path(self.temp.name)
        row=flow.run_command('json-pass',[sys.executable,'-c','print(\'{"checks":3,"failures":0}\')'],output)
        self.assertEqual(row['reported_checks'],[3]);self.assertEqual(row['reported_failures'],[0])
        with self.assertRaises(RuntimeError) as error:
            flow.run_command('json-fail',[sys.executable,'-c','print(\'{"checks":3,"failures":1}\')'],output)
        self.assertEqual(error.exception.args[0]['status'],0)
        self.assertEqual(error.exception.args[0]['reported_failures'],[1])

    def test_failed_stage_cannot_certify_full_acceptance(self):
        output=Path(self.temp.name)/'output';row=dict(status=9,name='focused')
        args=['verify_workflow.py','development','--subsystem','wages','--output',str(output)]
        with patch.object(sys,'argv',args),patch.object(flow,'fingerprint',return_value=self.proof),patch.object(flow,'run_command',side_effect=RuntimeError(row)),contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(flow.main(),1)
        value=json.loads((output/'summary.json').read_text())
        self.assertEqual(value['status'],'failed');self.assertFalse(value['full_acceptance']);self.assertEqual(value['failed_command']['status'],9)

    def test_full_plan_keeps_expensive_controls_and_has_no_reuse_shortcut(self):
        plan=dict(flow.full_plan(Path(self.temp.name)))
        self.assertEqual(set(plan),{'full-godot','full-python','historical','m23','m24','m24-fixtures','m25','m25-fixtures','m25-lifecycle','m26-fixtures','m26-extra','m26-m27','m28-m29','cd-capture','cd-independent-audits','m30-matrix','performance-smoke'})
        self.assertIn('run_wages.py',' '.join(plan['m30-matrix']))
        self.assertNotIn('--checkpoint',plan['m30-matrix']);self.assertFalse(any('--reuse' in a for argv in plan.values() for a in argv))

    def test_queue_checkpoint_audits_every_capture_and_detects_nonaggregate_drift(self):
        for corrupt in (False,True):
            def capture(stage,days,mode):
                return dict(report=dict(profitable=dict(ledger_sha256='ledger')),events=[dict(id=1)]+([dict(id=2)] if corrupt and stage=='D' and days==3 and mode=='scheduled' else []),measurement=dict(run_usec=1,command_seconds=1,canonical_sha256='report'))
            with patch('measure_planning_jobs.capture',side_effect=capture),patch('measure_planning_jobs.validate'),patch('learning_audit.audit') as audit:
                if corrupt:
                    with self.assertRaises(AssertionError):flow.queue_checkpoint()
                else:self.assertEqual(flow.queue_checkpoint()['independent_audits'],8)
                self.assertEqual(audit.call_count,8)

    def test_full_pin_comparison_checks_complete_case_set_and_duplicates(self):
        actual=Path(self.temp.name)/'actual.csv';old=Path(self.temp.name)/'old.csv'
        text='case,summary_sha256,ledger_sha256\na,full,events\n';actual.write_text(text);old.write_text(text)
        self.assertEqual(flow.compare_pins(actual,old,['case']),1)
        actual.write_text(text+'a,full,events\n')
        with self.assertRaises(AssertionError):flow.compare_pins(actual,old,['case'])
        actual.write_text(text.replace('events','wrong'))
        with self.assertRaises(AssertionError):flow.compare_pins(actual,old,['case'])

    def test_original_auditor_rejects_a_rehashed_real_money_forgery(self):
        from run_wages import capture
        from test_wages import rehash
        data=capture('scarce',1,'worker_bids');pin=flow.expected(CASE);flow.validate(data,CASE,pin)
        forged=copy.deepcopy(data)
        next(e for e in forged['events'] if e['action']=='transfer_money' and e['success'])['details']['amount']+=1
        rehash(forged)
        with self.assertRaises(AssertionError):flow.validate(forged,CASE,pin)


if __name__=='__main__':unittest.main()
