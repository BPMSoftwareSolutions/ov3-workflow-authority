"""Fixed launcher. Runs the provider entry named by argv[1] under a deadline and answers one JSON object whatever it does."""
import json
import subprocess
import sys

DEADLINE_SECONDS = 80

def run():
    wire = sys.stdin.buffer.read()
    try:
        done = subprocess.run([sys.executable, "-I", "-S", "-B", "-c", sys.argv[1]], input=wire,
                              capture_output=True, timeout=DEADLINE_SECONDS)
    except subprocess.TimeoutExpired:
        return {"status": "FAILED", "finding": "PROVIDER_DEADLINE_EXCEEDED"}
    if done.returncode != 0:
        return {"status": "FAILED", "finding": "PROVIDER_EXITED_%d" % done.returncode,
                "detail": done.stderr.decode("utf-8", "replace")[-300:]}
    try:
        answer = json.loads(done.stdout)
    except ValueError:
        return {"status": "FAILED", "finding": "PROVIDER_OUTPUT_INVALID"}
    if not isinstance(answer, dict) or not isinstance(answer.get("status"), str):
        return {"status": "FAILED", "finding": "PROVIDER_OUTPUT_INVALID"}
    return done.stdout.strip()

answer = run()
if isinstance(answer, bytes):
    sys.stdout.buffer.write(answer)
else:
    print(json.dumps(answer, ensure_ascii=True, separators=(",", ":")))
