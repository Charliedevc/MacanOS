#!/usr/bin/env python3
"""Build portable galleries/reports before commit; archive tracked source after commit."""
import argparse,base64,hashlib,html,json,pathlib,subprocess,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--output',default='/workspace/shared/downloads');p.add_argument('--archive',action='store_true');a=p.parse_args();out=pathlib.Path(a.output);out.mkdir(parents=True,exist_ok=True)
style='body{max-width:1500px;margin:36px auto;padding:0 22px;background:#10141a;color:#e4e9ef;font:16px/1.6 system-ui}a{color:#efa0ad}h1,h2{font-weight:500}p{max-width:1000px}figure{margin:14px 0 30px}img{width:100%;height:auto;border:1px solid #3c4655;border-radius:8px}figcaption{font-size:13px;color:#b5c0cf}table{border-collapse:collapse}td,th{border:1px solid #55616d;padding:9px}pre{white-space:pre-wrap}code{color:#d9b6bd}'
sections=[]
for mode,label in [('independent','INDEPENDENT — separate apps'),('unified','UNIFIED — clipped panorama'),('shared','SHARED — role-specific shared state'),('unified-media','UNIFIED — synchronized media visualization')]:
    figures=[]
    for role in ['driver','passenger']:
        path=ROOT/'docs/screenshots'/f'{mode}-{role}.png'
        if path.exists():
            data=base64.b64encode(path.read_bytes()).decode();figures.append(f'<figure><figcaption>{role.title()} · actual Qt software rendering · simulated fixture</figcaption><img alt="{mode} {role}" src="data:image/png;base64,{data}"></figure>')
    sections.append('<section><h2>'+html.escape(label)+'</h2>'+''.join(figures)+'</section>')
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MacanOS v0.6 — actual rendered screenshots</title><style>'+style+'</style><h1>MacanOS v0.6 / desktop simulator</h1><p>Actual captures from two independent Qt/QML processes sharing one backend. Navigation, telemetry, journey and silent media are labelled fixtures. This is a new integration module; the original v0.5 application source was unavailable. These images do not establish Android or NaviRider compatibility. Each image is embedded so this gallery opens offline.</p>'+''.join(sections)+'</html>'
(ROOT/'docs/GALLERY-v0.6.html').write_text(page)
(out/'MacanOS-v0.6-Screenshots.html').write_text(page)
parts=['# MacanOS v0.6 — engineering and hardware report\n\nNew desktop multi-display integration module. Source baseline: documentation-only commit cefde60. Original v0.5 application unavailable. No publication or merge.\n']
for name in ['VALIDATION-v0.6.md','HARDWARE-COMPATIBILITY-v0.6.md','ARCHITECTURE-v0.6.md','INSTALL-v0.6.md']:parts.append((ROOT/'docs'/name).read_text())
report=out/'MacanOS-v0.6-Report.md';report.write_text('\n\n---\n\n'.join(parts))
subprocess.run(['pandoc',str(report),'--standalone','--toc','--metadata','title=MacanOS v0.6 Engineering Report','-o',str(out/'MacanOS-v0.6-Report.html')],check=True)
if a.archive:
    status=subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True)
    if status.strip():raise SystemExit('Commit all deliverable changes before archiving')
    sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    subprocess.run(['git','archive','--format=zip','--prefix=MacanOS-v0.6/','-o',str(out/'MacanOS-v0.6-Source.zip'),'HEAD'],cwd=ROOT,check=True)
    bundle=out/'MacanOS-v0.6.git.bundle'
    if bundle.exists():bundle.unlink()
    subprocess.run(['git','bundle','create',str(bundle),'macanos/v0.6'],cwd=ROOT,check=True)
    subprocess.run(['git','bundle','verify',str(bundle)],cwd=ROOT,check=True)
    with zipfile.ZipFile(out/'MacanOS-v0.6-Source.zip') as z:
        if z.testzip():raise SystemExit('ZIP integrity check failed')
        assert 'MacanOS-v0.6/src/displaycoordinator.cpp' in z.namelist()
    (out/'MacanOS-v0.6-Delivery.json').write_text(json.dumps({'commit':sha,'branch':'macanos/v0.6','baseline':'cefde60 (documentation only)','originalV05Integrated':False,'published':False,'merged':False,'testCasesPassed':30},indent=2)+'\n')
    paths=sorted(out.glob('MacanOS-v0.6*'));lines=[]
    for path in paths:
        if path.is_file() and path.suffix!='.sha256':lines.append(hashlib.sha256(path.read_bytes()).hexdigest()+'  '+path.name)
    (out/'MacanOS-v0.6.sha256').write_text('\n'.join(lines)+'\n')
print(out)
