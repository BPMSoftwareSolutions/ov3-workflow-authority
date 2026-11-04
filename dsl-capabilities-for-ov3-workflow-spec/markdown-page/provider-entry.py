"""Fixed private provider entry. The bundle checksum is pinned by its declaration."""
import base64
import hashlib
import io
import json
import pathlib
import sys
import tempfile
import zipfile

BUNDLE = "__BUNDLE_SHA256__"

def main():
    wire = json.load(sys.stdin)
    raw = base64.b64decode(wire["bundle"], validate=True)
    if hashlib.sha256(raw).hexdigest() != BUNDLE:
        raise ValueError("PACKAGE_CLOSURE_MISMATCH")
    with tempfile.TemporaryDirectory(prefix="sidefx-markdown-") as directory:
        root = pathlib.Path(directory)
        with zipfile.ZipFile(io.BytesIO(raw)) as outer:
            for name in ("page_provider.py", "verify_page.py"):
                (root/name).write_bytes(outer.read(name))
            profile_bytes = outer.read("presentation.json")
            pins = json.loads(outer.read("provider-lock.json"))
            for pin in pins:
                wheel = outer.read(pin["file"])
                if hashlib.sha256(wheel).hexdigest() != pin["sha256"]:
                    raise ValueError("WHEEL_DIGEST_MISMATCH")
                with zipfile.ZipFile(io.BytesIO(wheel)) as package:
                    for name in package.namelist():
                        path = pathlib.PurePosixPath(name)
                        if path.is_absolute() or ".." in path.parts or "\\" in name:
                            raise ValueError("INVALID_PACKAGE_MEMBER")
                    package.extractall(root)
        sys.path.insert(0, directory)
        from page_provider import digest, render
        from verify_page import verify
        request, profile = wire["request"], json.loads(profile_bytes)
        if wire["phase"] == "render":
            result = render(request, profile)
            result["status"] = "RENDERED"
        elif wire["phase"] == "verify":
            result = verify(request, wire["html"], wire["receipt"], profile)
        else:
            raise ValueError("UNKNOWN_PAGE_OPERATION")
        import platform
        from importlib.metadata import version
        result.update(bundleDigest="sha256:"+BUNDLE, profileDigest=digest(profile_bytes),
                      inputDigest=wire.get("inputDigest"), filename=request["filename"],
                      renderer={"python":platform.python_version(),"Markdown":version("Markdown"),"nh3":version("nh3")})
        return result

try:
    print(json.dumps(main(),ensure_ascii=True,separators=(",",":")))
except Exception as error:
    print(json.dumps({"status":"FAILED","finding":str(error)[:300]}))
