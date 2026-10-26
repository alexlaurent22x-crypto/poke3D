"""Convert embedded WEBP textures to PNG for portable Blender FBX conversion.
Original downloaded GLB is preserved. Pillow verifies/decodes the image bytes.
"""
from pathlib import Path
import json,struct,io
from PIL import Image
p=Path(__file__).resolve().parent/'SourceAssets/SheenWoodLeatherSofa.glb'
d=p.read_bytes();assert d[:4]==b'glTF';jl=struct.unpack_from('<I',d,12)[0];g=json.loads(d[20:20+jl]);at=20+jl
bl=struct.unpack_from('<I',d,at)[0];buf=bytearray(d[at+8:at+8+bl])
for im in g.get('images',[]):
 if im.get('mimeType')!='image/webp':continue
 v=g['bufferViews'][im['bufferView']];start=v.get('byteOffset',0);image=Image.open(io.BytesIO(buf[start:start+v['byteLength']])).convert('RGBA');out=io.BytesIO();image.save(out,format='PNG');raw=out.getvalue()
 while len(buf)%4:buf.append(0)
 im['bufferView']=len(g['bufferViews']);im['mimeType']='image/png';g['bufferViews'].append({'buffer':0,'byteOffset':len(buf),'byteLength':len(raw)});buf.extend(raw)
for tex in g.get('textures',[]):
 ext=tex.get('extensions',{}).pop('EXT_texture_webp',None)
 if ext:tex['source']=ext['source']
for k in ['extensionsUsed','extensionsRequired']:
 if k in g:g[k]=[x for x in g[k] if x!='EXT_texture_webp']
g['buffers'][0]['byteLength']=len(buf)
while len(buf)%4:buf.append(0)
s=json.dumps(g,separators=(',',':')).encode();s+=b' '*((-len(s))%4)
result=struct.pack('<4sII',b'glTF',2,12+8+len(s)+8+len(buf))+struct.pack('<I4s',len(s),b'JSON')+s+struct.pack('<I4s',len(buf),b'BIN\x00')+buf
p.with_name(p.stem+'-Unity.glb').write_bytes(result)
print('Converted embedded WEBP to PNG:',len(result),'bytes')
