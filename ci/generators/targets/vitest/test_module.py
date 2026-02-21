"""Build Vitest test file content from verification case descriptors."""
from __future__ import annotations

import re


def _class_name_to_module_file(class_name: str) -> str:
    """PascalCase class name to module file stem, e.g. ErrorHandler -> error_handler."""
    return re.sub(r"(?<!^)(?=[A-Z])", "_", class_name).lower()


def _default_config_value_ts(ts_type: str) -> str:
    """Return a TypeScript literal for a test default (no model defaults here)."""
    if ts_type == "string":
        return "''"
    if ts_type == "number":
        return "0"
    if ts_type == "boolean":
        return "false"
    return "''"


def _step_title(step_name: str) -> str:
    """Humanise step name for it() title, e.g. validFrame -> 'valid frame'."""
    words: list[str] = []
    for i, ch in enumerate(step_name):
        if ch.isupper() and i > 0:
            words.append(" ")
        words.append(ch.lower())
    return "".join(words).strip()


def build_test_file(
    module_file: str,
    class_name: str,
    descriptors: list[dict],
    config_attrs: list[dict[str, str]] | None = None,
    extra_imports: list[str] | None = None,
    preamble: str | None = None,
) -> str:
    """Generate a single .test.ts file for one component (e.g. mllp_receiver.test.ts)."""
    lines: list[str] = []
    config_attrs = config_attrs or []
    extra_imports = extra_imports or []
    # Tests live in src/__tests__/, components in src/
    import_path = f"../{module_file}"
    lines.append("import { describe, it, expect, beforeEach } from 'vitest';")
    import_symbols = [class_name]
    if config_attrs or preamble:
        import_symbols.append(f"{class_name}Config")
    import_symbols.extend(extra_imports)
    lines.append(f"import {{ {', '.join(import_symbols)} }} from '{import_path}';")
    lines.append("")
    if preamble:
        for line in preamble.strip().splitlines():
            lines.append(line)
        lines.append("")
    elif config_attrs:
        config_type = f"{class_name}Config"
        default_config_lines = [
            f"  {attr['name']}: {_default_config_value_ts(attr['type'])},"
            for attr in config_attrs
        ]
        lines.append(f"const defaultConfig: {config_type} = {{")
        lines.extend(default_config_lines)
        lines.append("};")
        lines.append("")

    for desc in descriptors:
        lines.append(f"describe('{desc['name']}', () => {{")
        if desc.get("requirement_ids"):
            req_comment = " ".join(desc["requirement_ids"])
            lines.append(f"  // Verifies: {req_comment}")
        lines.append(f"  let {desc['subject_name']}: {class_name};")
        lines.append("")
        lines.append("  beforeEach(() => {")
        if config_attrs:
            config_var = desc.get("config_var") or "defaultConfig"
            lines.append(f"    {desc['subject_name']} = new {class_name}({config_var});")
        else:
            lines.append(f"    {desc['subject_name']} = new {class_name}();")
        lines.append("  });")
        lines.append("")

        for step in desc.get("action_steps", []):
            step_title = _step_title(step.get("name", "step"))
            step_doc = (step.get("doc") or "").strip()
            ts_body = step.get("ts_body")
            lines.append(f"  it('{step_title}', () => {{")
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


def build_service_test_file(
    service_class_name: str,
    descriptors: list[dict],
    service_constructor_params: list[dict],
) -> str:
    """Generate service.test.ts with constructor args from get_service_constructor_params.

    Reuses the same component/config logic as service.ts so the service is instantiated
    with one config arg per component that has config (e.g. new Hl7AdapterService(...)).
    """
    lines: list[str] = []
    lines.append("import { describe, it, expect, beforeEach } from 'vitest';")
    lines.append(f"import {{ {service_class_name} }} from '../service';")
    # Import each component Config type and build default config (same shape as service.ts constructor).
    for param in service_constructor_params:
        config_type = param["config_type"]
        class_name = param["class_name"]
        module_file = _class_name_to_module_file(class_name)
        lines.append(f"import {{ {config_type} }} from '../{module_file}';")
    lines.append("")

    # Default config per component (same defaults as component tests).
    for param in service_constructor_params:
        param_class_name = param["class_name"]
        config_type = param["config_type"]
        config_attrs = param.get("config_attrs") or []
        default_lines = [
            f"  {a['name']}: {_default_config_value_ts(a['type'])},"
            for a in config_attrs
        ]
        lines.append(f"const default{param_class_name}Config: {config_type} = {{")
        lines.extend(default_lines)
        lines.append("};")
    lines.append("")

    for desc in descriptors:
        lines.append(f"describe('{desc['name']}', () => {{")
        if desc.get("requirement_ids"):
            req_comment = " ".join(desc["requirement_ids"])
            lines.append(f"  // Verifies: {req_comment}")
        subject_name = desc["subject_name"]
        lines.append(f"  let {subject_name}: {service_class_name};")
        lines.append("")
        lines.append("  beforeEach(() => {")
        # Same constructor call shape as service.ts: one arg per config param.
        args = [f"default{p['class_name']}Config" for p in service_constructor_params]
        args_str = ", ".join(args)
        lines.append(f"    {subject_name} = new {service_class_name}({args_str});")
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
