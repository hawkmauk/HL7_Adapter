"""Config file generators: package.json, tsconfig.json, index.ts."""
from __future__ import annotations

import json

from ...ir import ModelGraph
from .queries import COMPONENT_MAP


def _build_package_json() -> str:
    """Generate package.json with dependencies from PSM technology bindings."""
    pkg = {
        "name": "hl7-adapter",
        "version": "0.1.0",
        "description": "HL7 Adapter service generated from SysML model",
        "main": "dist/adapter.js",
        "scripts": {
            "build": "tsc",
            "start": "node dist/adapter.js",
        },
        "dependencies": {
            "hl7-standard": "^1.0.0",
            "undici": "^7.0.0",
            "pino": "^9.0.0",
        },
        "devDependencies": {
            "@types/node": "^22.0.0",
            "typescript": "^5.7.0",
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
        },
        "include": ["src"],
    }
    return json.dumps(config, indent=2) + "\n"


def _build_index(graph: ModelGraph) -> str:
    """Generate src/index.ts that re-exports all component modules and the adapter."""
    lines: list[str] = []
    for comp in COMPONENT_MAP:
        module = comp["output_file"].replace(".ts", "")
        lines.append(f"export {{ {comp['class_name']} }} from './{module}';")
    lines.append("export { HL7Adapter } from './adapter';")
    lines.append("")
    return "\n".join(lines)
