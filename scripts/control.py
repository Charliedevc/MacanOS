#!/usr/bin/env python3
"""Optional simulator control; visible on-screen buttons work without this script."""
import argparse,json,pathlib,uuid
p=argparse.ArgumentParser();p.add_argument('--state-dir',default='.runtime');p.add_argument('--role',choices=['driver','passenger'],default='passenger');p.add_argument('op',choices=['setMode','localApp','setBezelGap','screenshot','setUnifiedScene']);p.add_argument('value');a=p.parse_args()
key={'setMode':'mode','localApp':'app','setBezelGap':'gapDip','screenshot':'path','setUnifiedScene':'scene'}[a.op]
value=float(a.value) if a.op=='setBezelGap' else a.value
path=pathlib.Path(a.state_dir)/(a.role+'.control.json');path.parent.mkdir(parents=True,exist_ok=True);tmp=path.with_suffix('.new');tmp.write_text(json.dumps(dict(sequence=str(uuid.uuid4()),op=a.op,args={key:value})));tmp.replace(path)
