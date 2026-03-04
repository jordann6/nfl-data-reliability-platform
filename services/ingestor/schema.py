from jsonschema import Draft202012Validator

SCOREBOARD_SCHEMA = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "required": ["leagues", "events"],
    "properties": {
        "leagues": {"type": "array"},
        "events": {"type": "array"},
    },
    "additionalProperties": True,
}

_validator = Draft202012Validator(SCOREBOARD_SCHEMA)

def validate_payload(payload: dict) -> tuple[bool, str]:
    errors = sorted(_validator.iter_errors(payload), key=lambda e: e.path)
    if not errors:
        return True, ""
    first = errors[0]
    path = ".".join([str(p) for p in first.path]) if first.path else "root"
    return False, f"{path}: {first.message}"
