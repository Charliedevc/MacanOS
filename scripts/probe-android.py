#!/usr/bin/env python3
"""Collect read-only Android display evidence using an already authorized ADB device.
No root, firmware changes, grants, launches, vehicle commands or security bypasses.
Requires adb installed by the operator. Outputs are bench evidence, not compatibility.
"""
import argparse,json,pathlib,shutil,subprocess,datetime
p=argparse.ArgumentParser();p.add_argument('--serial',required=True);p.add_argument('--output',default='android-display-evidence.json');a=p.parse_args()
if not shutil.which('adb'):p.error('adb is not installed; no probe was run')
commands={
 'androidVersion':['getprop','ro.build.version.release'],
 'androidApi':['getprop','ro.build.version.sdk'],
 'abiList':['getprop','ro.product.cpu.abilist'],
 'features':['pm','list','features'],
 'displays':['dumpsys','display'],
 'primaryWindowMetrics':['wm','size'],
 'inputDevices':['dumpsys','input'],
}
result={'capturedUtc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'RAW BENCH EVIDENCE — requires review','commands':{}}
for name,cmd in commands.items():
 try:
  r=subprocess.run(['adb','-s',a.serial,'shell']+cmd,capture_output=True,text=True,timeout=15)
  result['commands'][name]={'command':cmd,'returnCode':r.returncode,'stdout':r.stdout,'stderr':r.stderr}
 except subprocess.TimeoutExpired:result['commands'][name]={'command':cmd,'error':'timeout'}
pathlib.Path(a.output).write_text(json.dumps(result,indent=2));print(a.output)
