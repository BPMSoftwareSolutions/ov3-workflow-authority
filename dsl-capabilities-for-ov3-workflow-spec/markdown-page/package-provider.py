"""Build the immutable provider asset from the reviewed sources and wheel pins."""
import base64
import hashlib
import io
import json
from pathlib import Path
import sys
import zipfile

src = Path(__file__).parent
wheels, destination = map(Path, sys.argv[1:])
files = {n: (src/n).read_bytes() for n in ("page_provider.py","verify_page.py","presentation.json","provider-lock.json")}
for pin in json.loads(files["provider-lock.json"]):
    data = (wheels/pin["file"]).read_bytes()
    if hashlib.sha256(data).hexdigest() != pin["sha256"]:
        raise ValueError("WHEEL_DIGEST_MISMATCH")
    files[pin["file"]] = data
buf = io.BytesIO()
with zipfile.ZipFile(buf,"w") as archive:
    for name, data in sorted(files.items()):
        entry = zipfile.ZipInfo(name, date_time=(1980,1,1,0,0,0))
        entry.external_attr = 0o644 << 16
        archive.writestr(entry,data)
raw = buf.getvalue()
encoded = base64.b64encode(raw)
destination.mkdir(parents=True, exist_ok=True)
(destination/"provider.b64").write_bytes(encoded)
pins = {"bundleDigest":"sha256:"+hashlib.sha256(raw).hexdigest(),
        "assetDigest":"sha256:"+hashlib.sha256(encoded).hexdigest(),
        "profileDigest":"sha256:"+hashlib.sha256(files["presentation.json"]).hexdigest(),
        "wheels":json.loads(files["provider-lock.json"])}
(destination/"provider-identity.json").write_text(json.dumps(pins,indent=2),encoding="utf-8")
