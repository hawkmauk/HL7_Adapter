"""Build Vitest test file content from verification case descriptors."""
from __future__ import annotations


def build_test_file(module_file: str, class_name: str, descriptors: list[dict]) -> str:
    """Generate a single .test.ts file for one component (e.g. mllp_receiver.test.ts)."""
    lines: list[str] = []
    # Tests live in src/__tests__/, components in src/
    import_path = f"../{module_file}"
    lines.append("import { describe, it, expect, beforeEach } from 'vitest';")
    lines.append(f"import {{ {class_name} }} from '{import_path}';")
    lines.append("")

    for desc in descriptors:
        lines.append(f"describe('{desc['name']}', () => {{")
        if desc.get("requirement_ids"):
            req_comment = " ".join(desc["requirement_ids"])
            lines.append(f"  // Verifies: {req_comment}")
        lines.append(f"  let {desc['subject_name']}: {class_name};")
        lines.append("")
        lines.append("  beforeEach(() => {")
        lines.append(f"    {desc['subject_name']} = new {class_name}();")
        lines.append("  });")
        lines.append("")

        it_title = _it_title(desc)
        lines.append(f"  it('{it_title}', () => {{")
        for step in desc.get("action_steps", []):
            step_doc = (step.get("doc") or "").strip()
            ts_body = step.get("ts_body")
            if ts_body:
                for body_line in ts_body.splitlines():
                    lines.append("    " + body_line)
            elif step_doc:
                lines.append(f"    // {step['name']}: {step_doc}")
                lines.append("    // TODO: implement step")
            else:
                lines.append(f"    // {step['name']}")
                lines.append("    // TODO: implement step")
        lines.append("  });")
        lines.append("});")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def _it_title(desc: dict) -> str:
    """Produce a short it() title from the verification case name."""
    name = desc.get("name", "verification")
    if name.endswith("Test"):
        name = name[:-4]
    words: list[str] = []
    for i, ch in enumerate(name):
        if ch.isupper() and i > 0:
            words.append(" ")
        words.append(ch)
    spaced = "".join(words).strip().split()
    lower = " ".join(w.lower() for w in spaced)
    return f"should {lower}" if lower else "should pass"
