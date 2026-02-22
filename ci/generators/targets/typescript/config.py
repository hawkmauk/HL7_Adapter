"""Config file generators: package.json, tsconfig.json, index.ts, main.ts."""
from __future__ import annotations

import json

from ...ir import ModelGraph


def generated_ts_header(version: str) -> str:
    """Header comment for generated TypeScript/Vitest files (same versioning as LaTeX: git tag, short commit, or 'undefined')."""
    return f"""// Generated from SysML model. Do not edit by hand.
// Version: {version}

"""

from .service import _derive_service_class_name, get_service_constructor_params
from .naming import _to_camel
from .queries import (
    get_adapter_state_machine,
    get_component_map,
    get_initialize_from_binding_calls,
    get_service_lifecycle_initial_do_action,
    get_service_lifecycle_action_params,
    _find_psm_node,
    _get_config_attributes,
)


def _default_config_value_json(ts_type: str, model_default: str | None = None) -> str | int | bool:
    """Return a JSON-serializable default for a config attribute.

    Prefer model_default when present (from model attribute default).
    Otherwise use a type-based fallback only; no project-specific values.
    """
    if model_default is not None and model_default.strip():
        raw = model_default.strip()
        if ts_type == "number":
            try:
                return int(raw) if "." not in raw else float(raw)
            except ValueError:
                return 0
        if ts_type == "boolean":
            return raw.lower() in ("true", "1", "yes")
        return raw.strip("'\"")
    if ts_type == "string":
        return ""
    if ts_type == "number":
        return 0
    if ts_type == "boolean":
        return False
    return ""


def _build_config_json(graph: ModelGraph, document: object | None = None) -> str:
    """Build default config as JSON keyed by component (camelCase). Returns empty string if no service."""
    if not get_adapter_state_machine(graph, document=document):
        return ""
    component_map = get_component_map(graph, document=document)
    config: dict[str, dict[str, str | int | bool]] = {}
    for comp in component_map:
        psm = _find_psm_node(graph, comp["psm_short"], comp.get("part_def_qname"))
        attrs = _get_config_attributes(psm) if psm else []
        if not attrs:
            continue
        key = _to_camel(comp["class_name"])
        config[key] = {}
        for attr in attrs:
            name = attr["name"]
            ts_type = attr["type"]
            default = attr.get("default")
            config[key][name] = _default_config_value_json(ts_type, default)
    return json.dumps(config, indent=2) + "\n"


def _build_main_module(graph: ModelGraph, document: object | None = None) -> str:
    """Generate main.ts: load config, create the service, and call service.<do_action>() when the model defines a service lifecycle do action."""
    if not get_adapter_state_machine(graph, document=document):
        return ""
    service_class = _derive_service_class_name(graph, document)
    constructor_params = get_service_constructor_params(graph, document=document)
    do_action = get_service_lifecycle_initial_do_action(graph, document=document)
    lines: list[str] = [
        "import { readFileSync } from 'fs';",
        "import { join } from 'path';",
        f"import {{ {service_class} }} from './service';",
        "",
        "function main(): void {",
        "  const configPath = join(process.cwd(), 'config.json');",
        "  const config = JSON.parse(readFileSync(configPath, 'utf-8'));",
        f"  const service = new {service_class}(",
    ]
    args = [f"    config.{p['param_name']}," for p in constructor_params]
    if args:
        args[-1] = args[-1].rstrip(",")
    lines.extend(args)
    lines.append("  );")
    if do_action:
        accepts_config = (
            bool(get_service_lifecycle_action_params(graph, document=document))
            and bool(get_initialize_from_binding_calls(graph, document=document))
            and bool(constructor_params)
        )
        if accepts_config:
            lines.append("  service.initialize(config);")
        else:
            lines.append(f"  service.{do_action}();")
    lines.append("}")
    lines.append("")
    lines.append("main();")
    lines.append("")
    return "\n".join(lines)


def _build_package_json() -> str:
    """Generate package.json with dependencies from PSM technology bindings."""
    pkg = {
        "name": "hl7-adapter",
        "version": "0.1.0",
        "description": "HL7 Adapter service generated from SysML model",
        "main": "dist/main.js",
        "scripts": {
            "build": "tsc",
            "start": "node dist/main.js",
            "test": "vitest run",
            "test:watch": "vitest",
        },
        "dependencies": {
            "hl7-standard": "^1.0.0",
            "undici": "^7.0.0",
            "pino": "^9.0.0",
        },
        "devDependencies": {
            "@types/node": "^22.0.0",
            "@vitest/coverage-v8": "^2.0.0",
            "typescript": "^5.7.0",
            "vitest": "^2.0.0",
        },
    }
    return json.dumps(pkg, indent=2) + "\n"


def _build_tsconfig() -> str:
    """Generate tsconfig.json."""
    config = {
        "compilerOptions": {
            "target": "ES2022",
            "module": "Node16",
            "moduleResolution": "Node16",
            "outDir": "dist",
            "rootDir": "src",
            "strict": True,
            "esModuleInterop": True,
            "declaration": True,
            "sourceMap": True,
            "skipLibCheck": True,
        },
        "include": ["src"],
    }
    return json.dumps(config, indent=2) + "\n"


def _build_index(graph: ModelGraph, document: object | None = None) -> str:
    """Generate src/index.ts that re-exports all component modules and the service."""
    lines: list[str] = []
    for comp in get_component_map(graph, document=document):
        module = comp["output_file"].replace(".ts", "")
        lines.append(f"export {{ {comp['class_name']} }} from './{module}';")
    if get_adapter_state_machine(graph, document=document):
        service_class = _derive_service_class_name(graph, document)
        lines.append(f"export {{ {service_class} }} from './service';")
    lines.append("")
    return "\n".join(lines)
