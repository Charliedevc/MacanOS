#!/usr/bin/env python3
"""Real executable tests, not an in-process imitation of either display."""
import argparse, itertools, json, os, pathlib, signal, socket, subprocess, tempfile, time, unittest
P=argparse.ArgumentParser();P.add_argument('--build',default='build');P.add_argument('--artifacts',default='docs/test-results/processes');P.add_argument('--screenshots',default='docs/screenshots');ARGS,REST=P.parse_known_args()
BUILD=pathlib.Path(ARGS.build).resolve();ART=pathlib.Path(ARGS.artifacts).resolve();SHOTS=pathlib.Path(ARGS.screenshots).resolve()
for d in (ART,SHOTS):d.mkdir(parents=True,exist_ok=True)
def atomic(path,data):
    tmp=path.with_suffix('.new');tmp.write_text(json.dumps(data));tmp.replace(path)
def read(path):
    try:return json.loads(path.read_text())
    except (FileNotFoundError,json.JSONDecodeError):return {}
def wait_for(fn,timeout=8,description='condition'):
    end=time.monotonic()+timeout
    while time.monotonic()<end:
        value=fn()
        if value:return value
        time.sleep(.04)
    raise AssertionError('Timed out: '+description)
class MultiProcessTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='macanos-v06-');cls.root=pathlib.Path(cls.tmp.name);cls.procs={};cls.logs=[];cls.seq=0
        os.environ.setdefault('QT_QPA_PLATFORM','offscreen');os.environ.setdefault('QT_QUICK_BACKEND','software')
        os.environ['XDG_CACHE_HOME']=str(cls.root/'cache')
        cls.port=0;cls.start_server()
        for role in ('driver','passenger'):cls.start_client(role)
        cls.wait_pair()
    @classmethod
    def tearDownClass(cls):
        for p in cls.procs.values():
            if p.poll() is None:p.terminate()
        for p in cls.procs.values():
            try:p.wait(timeout=3)
            except subprocess.TimeoutExpired:p.kill();p.wait()
        for f in cls.logs:f.close()
        cls.tmp.cleanup()
    @classmethod
    def start_server(cls):
        err=open(ART/'server.log','a');cls.logs.append(err)
        p=subprocess.Popen([str(BUILD/'macanos-display-server'),'--port',str(cls.port),'--settings',str(cls.root/'mode.json')],stdout=subprocess.PIPE,stderr=err,text=True)
        cls.procs['server']=p
        line=p.stdout.readline();p.stdout.close();assert line,'Server did not start: '+(ART/'server.log').read_text()
        info=json.loads(line);cls.port=info['listeningPort'];cls.server_info=info
    @classmethod
    def start_client(cls,role,width=1280,height=480):
        log=open(ART/(role+'.log'),'a');cls.logs.append(log)
        args=[str(BUILD/'macanos-display-client'),'--role',role,'--port',str(cls.port),'--width',str(width),'--height',str(height)]
        for key,suffix in [('settings','.ini'),('diagnostic','.json'),('control','.control.json')]:args += ['--'+key,str(cls.root/(role+suffix))]
        args += ['--presence',str(cls.root/'presence.json')]
        cls.procs[role]=subprocess.Popen(args,stdout=log,stderr=log)
    @classmethod
    def state(cls,role='driver'):return read(cls.root/(role+'.json'))
    @classmethod
    def wait_pair(cls):
        for role in ('driver','passenger'):
            wait_for(lambda:cls.state(role).get('online') and cls.state(role).get('state',{}).get('bothReady'),description=role+' registration')
    @classmethod
    def control(cls,role,op,args=None):
        cls.seq+=1;seq=str(cls.seq);atomic(cls.root/(role+'.control.json'),dict(sequence=seq,op=op,args=args or {}))
        wait_for(lambda:cls.state(role).get('controlResult',{}).get('sequence')==seq,description='client command '+op)
    @classmethod
    def request(cls,op,args=None):
        with socket.create_connection(('127.0.0.1',cls.port),timeout=2) as s:
            s.sendall((json.dumps(dict(id=1,op=op,args=args or {}))+'\n').encode());f=s.makefile('rb')
            while True:
                j=json.loads(f.readline())
                if j.get('id')==1:return j
    @classmethod
    def settle(cls):
        def settled():
            d=cls.state();s=d.get('state',{});t=s.get('transition',{});return d.get('serverTime',-1)>=t.get('startMs',0)+t.get('durationMs',0)+80
        wait_for(settled,description='scheduled transition settled')
    @classmethod
    def mode(cls,m):
        cls.settle();cls.control('passenger','setMode',{'mode':m})
        for r in ('driver','passenger'):wait_for(lambda:cls.state(r).get('mode')==m,description=r+' mode '+m)
        cls.settle()
    def test_01_all_modes_and_screenshots(self):
        session=self.state()['state']['sessionId'];pid=self.procs['server'].pid
        for a,b in itertools.permutations(('INDEPENDENT','UNIFIED','SHARED'),2):
            self.mode(a);self.mode(b)
            self.assertEqual(self.state()['state']['sessionId'],session);self.assertEqual(self.procs['server'].pid,pid)
        for mode in ('INDEPENDENT','UNIFIED','SHARED'):
            self.mode(mode)
            for role in ('driver','passenger'):
                path=SHOTS/(mode.lower()+'-'+role+'.png');self.control(role,'screenshot',{'path':str(path)})
                wait_for(lambda:path.exists() and path.stat().st_size>10000,description='Qt-rendered screenshot')
        atomic(ART/'mode-evidence.json',self.state())
    def test_02_independent_and_shared_apps(self):
        self.mode('INDEPENDENT');self.control('driver','localApp',{'app':'navigation'});self.control('passenger','localApp',{'app':'media'})
        self.assertEqual(self.state('driver')['selectedApp'],'navigation');self.assertEqual(self.state('passenger')['selectedApp'],'media')
        self.mode('SHARED');self.control('passenger','localApp',{'app':'media'});self.settle()
        for role in ('driver','passenger'):wait_for(lambda:self.state(role)['selectedApp']=='media')
        self.mode('UNIFIED');self.control('driver','localApp',{'app':'media'});self.settle()
        for role in ('driver','passenger'):
            wait_for(lambda:self.state(role)['selectedApp']=='media');path=SHOTS/('unified-media-'+role+'.png');self.control(role,'screenshot',{'path':str(path)});wait_for(path.exists)
        self.mode('INDEPENDENT');self.assertEqual(self.state()['localApp'],'navigation');self.assertEqual(self.state('passenger')['localApp'],'media')
    def test_03_navigation_approval_and_media(self):
        self.control('passenger','model',{'method':'proposeDestination','destination':'Mountain lodge'})
        wait_for(lambda:self.state()['state']['model']['navigation']['pending']=='Mountain lodge')
        self.control('passenger','model',{'method':'approveDestination'})
        self.assertEqual(self.state()['state']['model']['navigation']['pending'],'Mountain lodge')
        self.control('driver','model',{'method':'approveDestination'})
        for role in ('driver','passenger'):wait_for(lambda:self.state(role)['state']['model']['navigation']['destination']=='Mountain lodge')
        self.control('passenger','model',{'method':'setVolume','volume':57})
        self.control('driver','model',{'method':'nextTrack'})
        for role in ('driver','passenger'):
            wait_for(lambda:self.state(role)['state']['model']['media']['volume']==57)
            self.assertEqual(self.state(role)['state']['model']['media']['title'],'Red horizon')
        self.control('passenger','model',{'method':'togglePlayback'});wait_for(lambda:not self.state()['state']['model']['media']['playing'])
        a=self.state()['state']['model']['media']['position'];time.sleep(.4);b=self.state()['state']['model']['media']['position'];self.assertAlmostEqual(a,b,places=2)
        self.control('driver','model',{'method':'togglePlayback'})
    def test_04_output_disappearance_and_explicit_resume(self):
        self.mode('UNIFIED');atomic(self.root/'presence.json',{'driver':True,'passenger':False})
        wait_for(lambda:self.state()['mode']=='INDEPENDENT');self.assertTrue(self.state()['state']['resumeRequired']);self.assertEqual(self.state()['state']['requestedMode'],'UNIFIED')
        atomic(self.root/'presence.json',{'driver':True,'passenger':True});self.wait_pair();self.assertEqual(self.state()['mode'],'INDEPENDENT');self.mode('UNIFIED')
    def test_05_process_crash_survivor_and_reconnect(self):
        self.mode('SHARED');driver_pid=self.procs['driver'].pid;backend_pid=self.procs['server'].pid
        self.procs['passenger'].kill();self.procs['passenger'].wait();wait_for(lambda:self.state()['mode']=='INDEPENDENT')
        self.assertIsNone(self.procs['driver'].poll());self.assertEqual(self.procs['driver'].pid,driver_pid);self.assertEqual(self.procs['server'].pid,backend_pid)
        self.control('driver','model',{'method':'setVolume','volume':63})
        self.start_client('passenger');self.wait_pair();wait_for(lambda:self.state('passenger')['state']['model']['media']['volume']==63);self.assertEqual(self.state()['mode'],'INDEPENDENT');self.mode('SHARED')
    def test_05b_driver_close_survivor_and_local_persistence(self):
        self.mode('SHARED');passenger_pid=self.procs['passenger'].pid;backend_pid=self.procs['server'].pid
        self.procs['driver'].terminate();self.procs['driver'].wait();wait_for(lambda:self.state('passenger')['mode']=='INDEPENDENT')
        self.assertIsNone(self.procs['passenger'].poll());self.assertEqual(self.procs['passenger'].pid,passenger_pid);self.assertEqual(self.procs['server'].pid,backend_pid)
        self.control('passenger','model',{'method':'setVolume','volume':71});self.assertTrue(self.state('passenger')['controlResult']['ok'])
        self.start_client('driver');self.wait_pair();wait_for(lambda:self.state()['state']['model']['media']['volume']==71)
        self.assertEqual(self.state()['localApp'],'navigation');self.assertEqual(self.state()['mode'],'INDEPENDENT')
    def test_06_silent_backend_stale_and_restart(self):
        self.mode('UNIFIED');old_session=self.state()['state']['sessionId']
        os.kill(self.procs['server'].pid,signal.SIGSTOP)
        try:
            wait_for(lambda:not self.state()['online'] and self.state()['mode']=='INDEPENDENT',timeout=4,description='stale fallback')
            wait_for(lambda:not self.state('passenger')['online'],timeout=4)
        finally:os.kill(self.procs['server'].pid,signal.SIGCONT)
        self.procs['server'].terminate();self.procs['server'].wait();self.start_server();self.wait_pair()
        wait_for(lambda:self.state()['state']['sessionId']!=old_session);self.assertEqual(self.state()['state']['requestedMode'],'UNIFIED');self.settle()
        self.mode('SHARED')
    def test_07_reject_unsupported_and_duplicate_roles(self):
        self.assertFalse(self.request('clearDTC')['ok']);self.assertFalse(self.request('setMode',{'mode':'SHARED'})['ok'])
        duplicate=self.request('register',{'role':'driver','display':dict(widthPx=1280,heightPx=480,scale=1,outputId='spoof')})
        self.assertFalse(duplicate['ok']);self.assertIn('owned',duplicate['error'])
        self.control('driver','clearDTC');self.assertIn('prohibited',self.state()['controlResult']['error'])
        self.assertIsNone(self.procs['server'].poll())
    def test_08_clock_schedule_and_resolutions(self):
        self.mode('UNIFIED')
        for role in ('driver','passenger'):
            wait_for(lambda:self.state(role)['clockUncertaintyMs']<30)
        a=self.state();b=self.state('passenger');self.assertEqual(a['state']['transition'],b['state']['transition']);self.assertLess(abs(a['serverTime']-b['serverTime']),350)
        atomic(ART/'clock-evidence.json',{'driver':a,'passenger':b,'note':'Separate diagnostic samples; <30 ms measured loopback half-RTT, not hardware frame-lock.'})
        for width,height in ((1920,720),(1920,1080)):
            self.procs['passenger'].terminate();self.procs['passenger'].wait();self.start_client('passenger',width,height);self.wait_pair()
            wait_for(lambda:self.state('passenger')['windowWidth']==width and self.state('passenger')['windowHeight']==height)
            self.mode('UNIFIED');g=self.state()['state']['geometry'];self.assertEqual(g['width'],1280+24+width);self.assertEqual(g['height'],height)
            path=SHOTS/(f'responsive-{width}x{height}-passenger.png');self.control('passenger','screenshot',{'path':str(path)});wait_for(path.exists)
    def test_09_touch_coordinate_protocol(self):
        self.mode('UNIFIED');state=self.state()['state'];generation=state['transition']['generation']
        self.control('passenger','touch',{'x':320,'y':120,'generation':generation})
        reply=self.state('passenger')['controlResult'];self.assertTrue(reply['ok']);mapped=reply['result'];origin=state['geometry']['viewports']['passenger']['x']
        self.assertAlmostEqual(mapped['canvasX'],origin+320);self.assertAlmostEqual(mapped['canvasY'],120)
        self.control('passenger','touch',{'x':320,'y':120,'generation':generation-1});self.assertFalse(self.state('passenger')['controlResult']['ok'])
    def test_10_offline_startup(self):
        # Reserve a currently unused local port, then close it before launching the offline client.
        with socket.socket() as reserve:reserve.bind(('127.0.0.1',0));port=reserve.getsockname()[1]
        with tempfile.TemporaryDirectory() as temp:
            root=pathlib.Path(temp);log=open(ART/'offline.log','w')
            process=subprocess.Popen([str(BUILD/'macanos-display-client'),'--role','driver','--port',str(port),'--settings',str(root/'layout.ini'),'--diagnostic',str(root/'state.json')],stdout=log,stderr=log)
            try:
                wait_for(lambda:read(root/'state.json').get('role')=='driver',description='offline initial render')
                state=read(root/'state.json');self.assertFalse(state['online']);self.assertEqual(state['mode'],'INDEPENDENT');self.assertIsNone(process.poll())
            finally:process.terminate();process.wait(timeout=3);log.close()
    def test_11_no_qml_runtime_errors(self):
        for role in ('driver','passenger'):
            log=(ART/(role+'.log')).read_text();self.assertNotIn('ReferenceError',log);self.assertNotIn('TypeError',log);self.assertNotIn('Unable to assign',log);self.assertNotIn('QQmlApplicationEngine failed',log)
if __name__=='__main__':unittest.main(argv=[__file__]+REST,verbosity=2)
