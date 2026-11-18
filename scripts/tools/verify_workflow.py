#!/usr/bin/env python3
"""M31 explicit verification levels. No economic policy or assertion is replaced."""
import argparse
import csv
import gzip
import hashlib
import importlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
BASE = 'f142f7b665206ef490d5da046510d672f9f5f466'
PROFILES = {
    'wages': ('run_wage_tests.gd', 'test_wages.py', 'wage', ['fixed10_instrumented', 'worker_bids']),
    'inputs': ('run_input_tests.gd', 'test_input_reliability.py', 'input', ['R_baseline_instrumented', 'R_input_aware']),
    'contracts': ('run_binding_tests.gd', 'test_binding.py', 'binding', ['matching', 'obligations_only']),
    'queue': ('run_dispatch_queue_tests.gd', 'test_planning_jobs.py', None, []),
    'workflow': (None, 'test_verification_workflow.py', 'wage', ['fixed10_instrumented']),
}
DEFERRED = ['complete Godot/Python suites', '169 historical byte pins', '88 M23–M25 pinned pairs',
            '36 M26/M27 controls, 48 proofs and 16 certificates', '76 M28/M29 controls',
            'full 28-case M30 matrix and 14 economic parities', '12 original C/D independent audits']


def sha(path):
    with Path(path).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def read_csv(path):
    with Path(path).open() as f:return list(csv.DictReader(f))


def save(path, value):
    Path(path).write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def dependencies(root=ROOT):
    """Conservative whole-repository closure; unknown/symlink directories fail closed.

    Exclude only documented generated outputs. Include dirty/untracked sources,
    all pins, native binaries/build commands and new directories, without git-diff inference.
    """
    files = {}
    for directory, dirs, names in os.walk(root):
        rel = Path(directory).relative_to(root)
        dirs[:] = sorted(d for d in dirs if d != '__pycache__' and
                         not (rel == Path('.') and d in ('.git', '.godot', 'work')) and
                         not (rel == Path('native/m20/rust') and d == 'target'))
        for d in dirs:
            if (Path(directory) / d).is_symlink():
                raise ValueError('Uncertain directory dependency: ' + str(rel / d))
        for name in sorted(names):
            path = Path(directory) / name
            if path.is_symlink():raise ValueError('Uncertain symlink dependency: '+str(path))
            if rel.parts[:2] == ('native', 'm20') and (name.endswith('.os') or name == '.sconsign.dblite'):
                continue
            files[str(rel / name)] = sha(path)
    if not files:
        raise ValueError('Empty dependency closure')
    return files


def shared_libraries(binaries):
    libraries = {}
    for binary in binaries:
        result = subprocess.run(['ldd',str(binary)],capture_output=True,text=True,env={**os.environ,'LC_ALL':'C'})
        if result.returncode or 'not found' in result.stdout:
            raise ValueError('Uncertain runtime libraries: '+str(binary))
        found = []
        for line in result.stdout.splitlines():
            line=line.strip()
            if line.startswith('linux-vdso.'):continue
            target=line.split('=>',1)[-1].rsplit(' (0x',1)[0].strip()
            if not target.startswith('/'):
                raise ValueError('Unrecognized runtime dependency: '+line)
            path=Path(target).resolve(strict=True);found.append(path);libraries[str(path)]=sha(path)
        if not found:raise ValueError('No runtime dependency proof: '+str(binary))
    return libraries


def source_attested():
    # This fixed profile's external-input closure is reviewed at M30. Changed or
    # new economic/capture code is uncertain: always recapture, even on later runs.
    allowed={'scripts/tools/verify_workflow.py','tests/test_verification_workflow.py'}
    paths=['scripts','native','tests','project.godot','.gitignore']
    diff=subprocess.run(['git','diff','--quiet',BASE,'--',*paths,*[':(exclude)'+p for p in sorted(allowed)]],cwd=ROOT)
    unknown=subprocess.check_output(['git','ls-files','--others','--exclude-standard','--',*paths],cwd=ROOT,text=True).splitlines()
    config=ROOT/'native/m20/math.gdextension'
    extensions=list(ROOT.glob('**/*.gdextension'))
    known_config=all(p==config for p in extensions) and (not config.exists() or config.read_bytes()==(ROOT/'native/m20/math.gdextension.in').read_bytes())
    autoload=ROOT/'.godot/extension_list.cfg'
    known_autoload=not autoload.exists() or all(line.strip() in ('','res://native/m20/math.gdextension') for line in autoload.read_text().splitlines())
    return diff.returncode==0 and not (set(unknown)-allowed) and known_config and known_autoload


def require_assertions():
    if sys.flags.optimize:
        raise RuntimeError('Verification requires Python assertions; remove -O/PYTHONOPTIMIZE')


def fingerprint():
    require_assertions()
    from profile_simulation import godot_environment
    binary = Path(shutil.which('godot') or 'missing-godot').resolve(strict=True)
    env = godot_environment()
    binaries=[binary,Path(sys.executable).resolve(),*sorted((ROOT/'native/m20/bin').glob('*.so'))]
    return dict(source_attested=source_attested(),runtime_libraries=shared_libraries(binaries),schema=1, files=dependencies(), engine=dict(path=str(binary), sha256=sha(binary),
                version=subprocess.check_output([str(binary), '--version'], text=True, env=env).strip()),
                python=dict(version=sys.version, executable_sha256=sha(Path(sys.executable).resolve())),
                platform=platform.platform(), machine=platform.machine(),
                environment_sha256=digest(env),
                extension_autoload_sha256=sha(ROOT/'.godot/extension_list.cfg') if (ROOT/'.godot/extension_list.cfg').exists() else None)


def expected(case):
    if case.get('seed')!=42 or case.get('allocation')!='original' or case.get('days') not in (1,3):
        raise ValueError('Short control inputs must explicitly use seed42, original funds and1/3 days')
    table, armkey = {'wage': ('M30_RUNS.csv', 'arm'), 'cash': ('M29_RUNS.csv', 'arm'),
                     'input': ('M28_RUNS.csv', 'arm'), 'binding': ('M25_RUNS.csv', 'mode'),
                     'demand': ('M26_RUNS.csv', 'arm')}[case['kind']]
    matches = [r for r in read_csv(ROOT / 'docs' / table)
               if r['condition'] == case['condition'] and int(r['days']) == case['days'] and
               r[armkey] == case['arm'] and r.get('allocation', 'original') == 'original' and
               r.get('fixture', 'none') == 'none']
    if len(matches) != 1:
        raise ValueError(('Missing/ambiguous historical expectation', case))
    row = matches[0]
    return dict(table=table, summary_sha256=row['summary_sha256'], ledger_sha256=row['ledger_sha256'])


def capture(case):
    module = importlib.import_module({'wage': 'run_wages', 'cash': 'run_cash_allocation',
                                     'input': 'run_input', 'binding': 'run_binding', 'demand': 'run_demand'}[case['kind']])
    return module.capture(case['condition'], case['days'], case['arm'])


def validate(data, case, pin):
    require_assertions()
    module = importlib.import_module({'wage': 'wage_audit', 'cash': 'cash_allocation_audit',
                                     'input': 'input_audit', 'binding': 'binding_audit', 'demand': 'demand_audit'}[case['kind']])
    (module.analyze if hasattr(module, 'analyze') else module.audit)(data)
    r = data['report']
    from run_brewery import digest as report_digest
    if report_digest(dict(report=r)) != pin['summary_sha256'] or r['ledger_sha256'] != pin['ledger_sha256']:
        raise AssertionError(('Historical complete report/ledger drift', case))


def load_case(case, proof, cache, repeat):
    """Reuse raw native inputs only; always run the original independent audit again."""
    pin = expected(case)
    provenance = dict(dependencies=proof, inputs=case, repeat=repeat, expected=pin)
    key = digest(provenance)
    trusted = proof.get('source_attested',False)
    path = Path(cache) / (key + '.json.gz') if cache and trusted else None
    meta = path.with_suffix('.receipt.json') if path else None
    status, data = ('unattested_source_recapture' if cache and not trusted else 'disabled'), None
    if path:
        status = 'miss'
        if path.exists() and meta.exists():
            try:
                receipt = json.loads(meta.read_text())
                if receipt['provenance'] == provenance and receipt['payload_sha256'] == sha(path):
                    with gzip.open(path, 'rt') as f:
                        data = json.load(f)
                    status = 'verified_hit'
                else:
                    status = 'invalid_receipt_recapture'
            except (OSError, ValueError, KeyError, EOFError):
                status = 'corrupt_recapture'
    stamp = time.perf_counter()
    if data is None:
        data = capture(case)
    capture_seconds = time.perf_counter() - stamp if status != 'verified_hit' else 0
    stamp = time.perf_counter()
    validate(data, case, pin)
    audit_seconds = time.perf_counter() - stamp
    if path and status != 'verified_hit':
        path.parent.mkdir(parents=True, exist_ok=True)
        with gzip.open(path, 'wt', compresslevel=3) as f:
            json.dump(data, f, separators=(',', ':'))
        save(meta, dict(provenance=provenance, payload_sha256=sha(path)))
    return data, dict(case=case, repeat=repeat, cache=status, proof_sha256=digest(provenance),
                      capture_seconds=capture_seconds, audit_seconds=audit_seconds,
                      events=len(data['events']), **pin)


def smoke(profile, days, proof, cache):
    kind, arms = PROFILES[profile][2:]
    results, parities = [], []
    for day in days:
        for arm in arms:
            case = dict(kind=kind, condition='scarce', days=day, arm=arm, allocation='original', seed=42)
            first = None
            for repeat in (1, 2):
                data, row = load_case(case, proof, cache, repeat)
                results.append(row)
                if first is not None and (first['report'] != data['report'] or first['events'] != data['events']):
                    raise AssertionError(('Complete deterministic replay drift', case))
                first = data
            # Full existing normalization, not aggregate meal/money equality.
            if kind == 'wage' and arm == 'fixed10_instrumented' or kind == 'input' and arm == 'R_baseline_instrumented':
                control = dict(case, kind='cash' if kind == 'wage' else 'demand',
                               arm='R_input_aware' if kind == 'wage' else 'requests_smoothed')
                old, row = load_case(control, proof, cache, 1)
                results.append(row)
                module = importlib.import_module('run_wages' if kind == 'wage' else 'run_input')
                result = (module.parity if kind == 'wage' else module.economic_parity)(first, old)
                parities.append(dict(case=case, **result))
    return dict(captures=results, actual_native_processes=sum(r['cache'] != 'verified_hit' for r in results),
                independent_audits=len(results), deterministic_cases=len(days)*len(arms), full_economic_parities=parities)


def full_plan(output):
    """The existing comprehensive M30 certification path, not a new audit framework."""
    py = [sys.executable, '-B', 'scripts/tools/']
    def cmd(tool, *args):return py[:2] + [py[2]+tool+'.py', *map(str, args)]
    def out(name):return output / name
    return [
        ('full-godot', ['godot','--headless','--no-header','--path','.', '--script','res://tests/run_tests.gd']),
        ('full-python', [sys.executable,'-B','-m','unittest','discover','-s','tests','-p','test_*.py']),
        ('historical', cmd('check_historical','--output',out('historical.csv'))),
        ('m23', cmd('run_labor_market','--legacy-controls','--output',out('m23'))),
        ('m24', cmd('run_labor_market','--verify-pins','docs/M24_RUNS.csv','--output',out('m24'))),
        ('m24-fixtures', cmd('run_labor_market','--fixtures','--verify-pins','docs/M24_VACANCIES.csv','--output',out('m24-fixtures'))),
        ('m25', cmd('run_binding','--verify-pins','docs/M25_RUNS.csv','--output',out('m25'))),
        ('m25-fixtures', cmd('run_binding','--fixtures','--verify-pins','docs/M25_FIXTURES.csv','--output',out('m25-fixtures'))),
        ('m25-lifecycle', cmd('check_binding_lifecycle','--output',out('m25-lifecycle'))),
        ('m26-fixtures', cmd('check_demand_fixtures','--output',out('m26-fixtures'))),
        ('m26-extra', cmd('check_diagnostic_controls','--output',out('m26-extra'))),
        ('m26-m27', cmd('check_input_controls','--output',out('m26-m27'))),
        ('m28-m29', cmd('check_wage_controls','--output',out('m28-m29'))),
        ('cd-capture', cmd('check_diagnostic_controls','--cd','--output',out('cd'))),
        ('cd-independent-audits', cmd('measure_planning_jobs','--phase','audit','--output',out('cd'))),
        ('m30-matrix', cmd('run_wages','--output',out('m30'),'--traces',out('m30-traces'))),
        ('performance-smoke', cmd('performance_smoke','--output',out('smoke.json'))),
    ]


def compare_pins(actual, historical, keys):
    observed = read_csv(actual)
    pins = read_csv(historical)
    def index(rows):
        out = {tuple(r[k] for k in keys): (r['summary_sha256'], r['ledger_sha256']) for r in rows}
        if len(out) != len(rows):raise AssertionError('Duplicate control case')
        return out
    if index(observed) != index(pins):raise AssertionError(('Published control drift', str(actual)))
    return len(observed)


def run_command(name, command, output):
    from profile_simulation import godot_environment
    log = output / (name+'.log')
    stamp = time.perf_counter()
    with log.open('w') as f:
        result = subprocess.run(command, cwd=ROOT, env=godot_environment(), stdout=f, stderr=subprocess.STDOUT)
    text = log.read_text()
    counts = re.findall(r'(?:Ran (\d+) tests|checks: (\d+)|Tests: (\d+) checks)', text)
    row = dict(name=name, command=command, seconds=time.perf_counter()-stamp, status=result.returncode,
               reported_checks=[int(next(v for v in c if v)) for c in counts], log=log.name)
    if result.returncode or re.search(r'OK \(skipped=|SCRIPT ERROR:|^FAIL:', text, re.M):
        raise RuntimeError(row)
    return row


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('level', choices=['development','checkpoint','full'])
    p.add_argument('--subsystem', choices=list(PROFILES))
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--cache-dir', type=Path)
    p.add_argument('--plan', action='store_true')
    a=p.parse_args()
    if a.level!='full' and not a.subsystem:p.error('--subsystem is required for development/checkpoint')
    for path in [a.output,a.cache_dir]:
        if path and path.resolve().is_relative_to(ROOT) and not path.resolve().is_relative_to(ROOT/'work'):
            p.error('Generated output/cache must be under work/ or outside the repository')
    a.output.mkdir(parents=True,exist_ok=False)
    started=time.perf_counter()
    summary=dict(level=a.level, subsystem=a.subsystem, base=BASE, status='planned' if a.plan else 'running',
                 full_acceptance=False, deferred=[] if a.level=='full' else DEFERRED,
                 commands=[], full_commands=[dict(name=n,command=c) for n,c in full_plan(a.output)] if a.level=='full' else [])
    try:
        if not a.plan:
            proof=fingerprint();save(a.output/'dependencies.json',proof);summary['dependencies_sha256']=digest(proof)
            if a.level=='full':
                for name,command in full_plan(a.output):
                    summary['commands'].append(run_command(name,command,a.output))
                    save(a.output/'summary.json',summary)
                summary['pinned_pair_counts']={}
                for folder,file,table,keys in [('m23','controls.csv','M23_RUNS.csv',['condition','days']),('m24','runs.csv','M24_RUNS.csv',['condition','days','mode','tie','fixture']),('m24-fixtures','runs.csv','M24_VACANCIES.csv',['condition','days','mode','tie','fixture']),('m25','runs.csv','M25_RUNS.csv',['condition','days','mode','fixture']),('m25-fixtures','runs.csv','M25_FIXTURES.csv',['condition','days','mode','fixture']),('m25-lifecycle','results.csv','M25_LIFECYCLES.csv',['fixture']),('m30','runs.csv','M30_RUNS.csv',['condition','days','arm','allocation'])]:
                    summary['pinned_pair_counts'][folder]=compare_pins(a.output/folder/file,ROOT/'docs'/table,keys)
                summary['full_acceptance']=True
            else:
                native,pattern,kind,_=PROFILES[a.subsystem]
                if a.level=='checkpoint' or native is None:
                    command=[sys.executable,'-B','-m','unittest','discover','-s','tests','-p',pattern]
                else:command=['godot','--headless','--no-header','--path','.', '--script','res://tests/'+native]
                summary['commands'].append(run_command('focused',command,a.output))
                if kind:
                    summary['smoke']=smoke(a.subsystem,[1] if a.level=='development' else [1,3],proof,a.cache_dir)
                else:
                    command=[sys.executable,'-B','scripts/tools/performance_smoke.py','--output',str(a.output/'queue-smoke.json')]
                    summary['commands'].append(run_command('queue-smoke',command,a.output))
                    q=json.loads((a.output/'queue-smoke.json').read_text())
                    summary['queue_smoke']=dict(warnings=q['warnings'],cases={name:{k:v for k,v in value.items() if k in ('canonical_sha256','proposal_digest','release_digest','run_seconds','peak_rss_kib')} for name,value in q['cases'].items()})
            if fingerprint()!=proof:raise RuntimeError('Dependencies changed during verification; result is not certified')
            summary['status']='passed'
    except Exception as error:
        summary['status']='failed';summary['full_acceptance']=False;summary['error']=repr(error)
        if error.args and isinstance(error.args[0],dict):summary['failed_command']=error.args[0]
    finally:
        summary['command_seconds']=time.perf_counter()-started;save(a.output/'summary.json',summary)
    print(json.dumps(summary,sort_keys=True))
    return 1 if summary['status']=='failed' else 0


if __name__=='__main__':sys.exit(main())
