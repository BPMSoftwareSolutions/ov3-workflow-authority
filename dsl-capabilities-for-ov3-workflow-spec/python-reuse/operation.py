"""Source embedded in each declared dependency with one fixed OPERATION literal."""
import base64
import binascii
import hashlib
import html
import json
import sys
import textwrap

OPERATION = "__OPERATION__"
KEYS = {
    "textwrap": ({"text"}, {"width"}),
    "html": ({"text"}, {"quote"}),
    "base64": ({"data"}, {"padded", "wrapcol"}),
    "binascii": ({"data"}, {"initialCrc"}),
    "hashlib": ({"data", "algorithm"}, {"usedforsecurity"}),
}


def require(valid):
    if not valid:
        raise ValueError("invalid request")


def integer(value, low, high):
    require(type(value) is int and low <= value <= high)
    return value


def compute(req):
    required, optional = KEYS[OPERATION]
    require(type(req) is dict and required <= req.keys() <= required | optional)
    value = req["text"] if "text" in required else req["data"]
    require(type(value) is str)
    # Verify Unicode scalar values before returning JSON or passing data to a library.
    raw = value.encode("utf-8")
    require(len(raw) <= (8192 if OPERATION in {"binascii", "hashlib"} else 6144))
    if OPERATION == "textwrap":
        width = integer(req.get("width", 70), 1, 256)
        lines = textwrap.TextWrapper(width=width).wrap(value)
        return {"lines": lines, "line_count": len(lines)}
    if OPERATION == "html":
        quote = req.get("quote", True)
        require(type(quote) is bool)
        escaped = html.escape(value, quote=quote)
        return {"escaped": escaped, "quoteApplied": quote,
                "inputLength": len(value), "outputLength": len(escaped)}
    if OPERATION == "base64":
        require(req.get("padded", True) is True)
        integer(req.get("wrapcol", 0), 0, 0)
        encoded = base64.b64encode(raw).decode("ascii")
        return {"encoded": encoded, "inputBytes": len(raw), "outputBytes": len(encoded),
                "padded": True, "wrapcol": 0}
    data = base64.b64decode(value, validate=True)
    require(base64.b64encode(data).decode("ascii") == value)
    if OPERATION == "binascii":
        seed = integer(req.get("initialCrc", 0), 0, 2**32 - 1)
        crc = binascii.crc32(data, seed)
        return {"crc": crc, "hex": format(crc, "08x"), "byteLength": len(data)}
    require(req["algorithm"] == "sha256" and req.get("usedforsecurity", True) is True)
    digest = hashlib.new("sha256", data, usedforsecurity=True)
    return {"algorithm": digest.name, "hexdigest": digest.hexdigest(),
            "digestSize": digest.digest_size, "blockSize": digest.block_size}


def unique(pairs):
    result = dict(pairs)
    require(len(pairs) == len(result))
    return result


if __name__ == "__main__":
    outcome = {"contractId": "python-" + OPERATION + "-result.v1",
               "runtime": {"implementation": sys.implementation.name,
                           "version": ".".join(map(str, sys.version_info[:3]))}}
    try:
        wire = sys.stdin.buffer.read(65537)
        require(len(wire) <= 65536)
        req = json.loads(wire.decode("utf-8"), object_pairs_hook=unique)
        outcome.update(status="COMPUTED", value=compute(req))
    except (KeyError, ValueError, TypeError, RecursionError):
        outcome.update(status="INVALID", reason="OUTSIDE_BOUNDED_CONTRACT")
    print(json.dumps(outcome, ensure_ascii=True, allow_nan=False, separators=(",", ":")))
