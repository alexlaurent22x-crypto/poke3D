"""Restore the exact previously downloaded assets with TLS and SHA-256 verification."""
import pathlib,json,urllib.request,hashlib
root=pathlib.Path(__file__).resolve().parents[1]
for record in json.loads((root/'Documentation/downloads.json').read_text()):
 target=root/record['file']
 if target.exists():
  if hashlib.sha256(target.read_bytes()).hexdigest()==record['sha256']:print('Verified',record['name']);continue
  raise SystemExit('Existing file differs; preserve and inspect before replacing: '+str(target))
 data=urllib.request.urlopen(record['url'],timeout=90).read()
 if hashlib.sha256(data).hexdigest()!=record['sha256']:raise SystemExit('SHA-256 mismatch: '+record['name'])
 target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data);print('Restored',record['name'])
