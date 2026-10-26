"""Create the complete Unity delivery archive, excluding local build caches."""
from pathlib import Path
import zipfile,hashlib,json
root=Path(__file__).resolve().parents[1];out=root.parent.parent/'POKS-Unity6-HDRP.zip'
files=[]
for p in root.rglob('*'):
 if not p.is_file():continue
 rel=p.relative_to(root)
 if any(x in {'bin','obj','__pycache__','.git','Library','Temp','Logs'} for x in rel.parts) or p.suffix=='.pyc':continue
 files.append(p)
with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for p in sorted(files):z.write(p,Path('UnityPoker')/p.relative_to(root))
with zipfile.ZipFile(out) as z:
 bad=z.testzip()
 if bad:raise SystemExit('Corrupt archive entry: '+bad)
 names=z.namelist()
 for required in ['Assets/POKS/Scenes/Salon.unity','Packages/manifest.json','Tools/CoreChecks/CoreChecks.csproj']:
  assert 'UnityPoker/'+required in names,required
 assert not any(n.endswith(('.gd','.godot')) for n in names)
 for p in files:
  if p.suffix=='.cs':assert z.read(str(Path('UnityPoker')/p.relative_to(root)))==p.read_bytes(),p
sha=hashlib.sha256(out.read_bytes()).hexdigest();out.with_suffix(out.suffix+'.sha256').write_text(sha+'  '+out.name+'\n')
print(json.dumps({'archive':str(out),'files':len(files),'bytes':out.stat().st_size,'sha256':sha,'zip_crc_and_Csharp_contents':'passed'},indent=2))
