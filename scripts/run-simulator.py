#!/usr/bin/env python3
"""Launch three independent processes. A closed frontend is deliberately not restarted."""
import argparse,json,os,pathlib,signal,subprocess,sys,time
p=argparse.ArgumentParser();p.add_argument('--build',default=str(pathlib.Path(__file__).resolve().parents[1]/'build'));p.add_argument('--state-dir',default='.runtime');p.add_argument('--width',type=int,default=1280);p.add_argument('--height',type=int,default=480);p.add_argument('--port',type=int,default=45670);p.add_argument('--driver-screen',type=int);p.add_argument('--passenger-screen',type=int);p.add_argument('--fullscreen',action='store_true');a=p.parse_args()
build=pathlib.Path(a.build).resolve();state=pathlib.Path(a.state_dir).resolve();state.mkdir(parents=True,exist_ok=True)
if a.driver_screen is not None and a.driver_screen==a.passenger_screen:p.error('Select distinct physical Qt screens')
processes=[];logs=[]
def stop(*_):
 for child in reversed(processes):
  if child.poll() is None:child.terminate()
 for child in processes:
  try:child.wait(timeout=3)
  except subprocess.TimeoutExpired:child.kill();child.wait()
 for log in logs:log.close()
signal.signal(signal.SIGTERM,lambda *_:sys.exit(0))
try:
 err=open(state/'backend.log','a');logs.append(err)
 server=subprocess.Popen([str(build/'macanos-display-server'),'--port',str(a.port),'--settings',str(state/'modes.json')],stdout=subprocess.PIPE,stderr=err,text=True);processes.append(server)
 line=server.stdout.readline();server.stdout.close()
 if not line:raise RuntimeError('Server failed. See '+str(state/'backend.log'))
 port=json.loads(line)['listeningPort']
 for role in ('driver','passenger'):
  log=open(state/(role+'.log'),'a');logs.append(log)
  cmd=[str(build/'macanos-display-client'),'--role',role,'--port',str(port),'--width',str(a.width),'--height',str(a.height)]
  for key,suffix in [('settings','.ini'),('control','.control.json'),('diagnostic','.json')]:cmd+=['--'+key,str(state/(role+suffix))]
  cmd+=['--presence',str(state/'presence.json')]
  screen=getattr(a,role+'_screen')
  if screen is not None:cmd+=['--screen',str(screen)]
  if a.fullscreen:cmd+=['--fullscreen']
  processes.append(subprocess.Popen(cmd,stdout=log,stderr=log))
 print('MacanOS display simulator on loopback port',port,'— Ctrl+C stops this session.',flush=True)
 print('Settings, logs and simulator controls:',state,flush=True)
 while server.poll() is None and any(child.poll() is None for child in processes[1:]):time.sleep(.25)
except KeyboardInterrupt:pass
finally:stop()
