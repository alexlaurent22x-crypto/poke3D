"""Validate local project assets and provenance without claiming a Unity import."""
from pathlib import Path
import json,hashlib,re,wave
from PIL import Image
root=Path(__file__).resolve().parents[1];checks=0

def check(ok,message):
 global checks
 checks+=1
 if not ok:raise SystemExit('FAIL: '+message)
manifest=json.loads((root/'Packages/manifest.json').read_text())
check(manifest['dependencies']['com.unity.render-pipelines.high-definition']=='17.0.4','HDRP pin')
for record in json.loads((root/'Documentation/downloads.json').read_text()):
 p=root/record['file'];check(p.exists(),'download exists: '+str(p));check(hashlib.sha256(p.read_bytes()).hexdigest()==record['sha256'],'download integrity: '+str(p))
cat=json.loads((root/'Assets/POKS/Resources/ArtCatalog.json').read_text())['materials'];names=[m['name'] for m in cat]
check(len(names)==len(set(names)),'unique material names')
for mat in cat:
 for slot in ['baseMap','normalMap','maskMap']:
  if mat[slot]:check((root/'Assets/POKS/Resources'/(mat[slot]+'.png')).exists(),'texture exists: '+mat[slot])
for p in (root/'Assets/POKS/Resources').rglob('*.png'):
 with Image.open(p) as image:image.verify();checks+=1
for p in (root/'Assets/POKS/Resources/Audio').rglob('*.wav'):
 with wave.open(str(p)) as sound:check(sound.getnframes()>0,'nonempty audio '+p.name)
report=json.loads((root/'Documentation/art-validation.json').read_text())
check(len(report)==13,'all 13 FBX files were inspected')
for m in report:
 check(m['meshes']>0,'model meshes '+m['model'])
 check(m.get('sha256')==hashlib.sha256((root/'Assets/POKS/Resources/Models'/m['model']).read_bytes()).hexdigest(),'FBX matches validated report '+m['model'])
 if m['model'] in ['AvatarMale.fbx','AvatarFemale.fbx']:
  check(all(n in m['morphs'] for n in ['Build','Eyes','Nose','Mouth','Jaw','Face']),'avatar morphs')
  check(any('idle' in a for a in m['actions']) and any('deal' in a for a in m['actions']),'skeletal clips')
scene=(root/'Assets/POKS/Scenes/Salon.unity').read_text();meta=(root/'Assets/POKS/Scripts/Runtime/PoksGame.cs.meta').read_text();guid=re.search(r'guid: ([a-f0-9]+)',meta).group(1)
check(guid in scene,'scene references game bootstrap')
check((root/'Assets/POKS/Resources/Cards/back.png').exists(),'card back')
for i in range(52):check((root/f'Assets/POKS/Resources/Cards/{i:02}.png').exists(),'card face')
for p in (root/'Assets').rglob('*.asmdef'):json.loads(p.read_text());checks+=1
print(f'PASS: {checks} project/provenance/media checks. Unity import, rendering and Windows execution remain UNTESTED.')
