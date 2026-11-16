#!/usr/bin/env python3
"""Opt-in Linux x86-64 M20 build. No downloads, no effect on historical commands."""
import argparse,json,os,shutil,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--godot-cpp',type=Path,required=True)
p.add_argument('--api',type=Path,required=True,help='Godot 4.6.3 --dump-extension-api output')
p.add_argument('--sanitize',action='store_true')
a=p.parse_args();native=ROOT/'native/m20';out=native/'bin';out.mkdir(exist_ok=True)
revision=subprocess.check_output(["git","-C",str(a.godot_cpp),"rev-parse","HEAD"],text=True).strip()
if revision!="abb196939767b7bbee0b3a380faefdcbdb118a54":raise SystemExit("Use pinned godot-cpp abb196939767b7bbee0b3a380faefdcbdb118a54")
api_header=json.loads(a.api.read_text())["header"]
if (api_header["version_major"],api_header["version_minor"])!=(4,6):raise SystemExit("Godot 4.6 API required")
rows=[]
def run(name,cmd,**kw):
    start=time.perf_counter();subprocess.run(cmd,check=True,**kw)
    rows.append(dict(component=name,seconds=time.perf_counter()-start,command=cmd))
run('cpp',['g++','-std=c++17','-O3','-fPIC','-shared','-fno-fast-math','-ffp-contract=off',str(native/'cpp/kernel.cpp'),'-o',str(out/'libm20_cpp.so')])
run('rust',['cargo','+1.91.1','build','--release','--offline','--manifest-path',str(native/'rust/Cargo.toml')],env={**os.environ,'RUSTFLAGS':'-C target-cpu=x86-64 -C target-feature=-fma'})
shutil.copy2(native/'rust/target/release/libm20_math.so',out/'libm20_math.so')
run('bridge',['python3','-m','SCons','-C',str(native),'-j2','platform=linux','target=template_release','arch=x86_64','custom_api_file='+str(a.api.resolve()),'build_profile='+str(native/'bridge/profile.json')],env={**os.environ,'GODOT_CPP':str(a.godot_cpp.resolve())})
if a.sanitize:
    run('cpp-sanitize',['g++','-std=c++17','-O1','-g','-fPIC','-shared','-fno-fast-math','-ffp-contract=off','-fsanitize=address,undefined',str(native/'cpp/kernel.cpp'),'-o',str(out/'libm20_cpp_sanitize.so')])
shutil.copy2(native/'math.gdextension.in',native/'math.gdextension')
print(json.dumps(rows));(out/'last-build.json').write_text(json.dumps(rows,indent=2))
