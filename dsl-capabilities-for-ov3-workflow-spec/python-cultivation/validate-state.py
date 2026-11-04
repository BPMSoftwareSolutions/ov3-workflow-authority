"""Validate the exact state bytes submitted to Jev and all case-to-declaration references."""
import json
import sys
from pathlib import Path
from jsonschema import Draft202012Validator

validator = Draft202012Validator(json.loads(Path(__file__).with_name("state.schema.json").read_text()))
keys = {"REUSE", "COMPOSE", "NEW_MECHANIC_CANDIDATE", "UNRESOLVED"}
count = 0
for path in sorted(Path(sys.argv[1]).glob("batch-*.json")):
    req = json.loads(path.read_text(encoding="utf-8"))
    state = req["state"]
    validator.validate(state)
    if set(state["cases"]) != set(req["questions"]):
        raise ValueError(f"Case and question mismatch in {path}")
    for key, case in state["cases"].items():
        if not set(case["candidates"]) <= set(state["declarations"]):
            raise ValueError(f"Missing candidate in {path}")
        question = req["questions"][key]
        if question["type"] != "choice" or set(question["criteria"]) != keys:
            raise ValueError(f"Invalid Jev question in {path}")
        count += 1
print(count, "structured decisions validated")
