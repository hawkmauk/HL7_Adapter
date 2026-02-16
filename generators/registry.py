from __future__ import annotations

from dataclasses import dataclass, field

from .base import GeneratorTarget


@dataclass(slots=True)
class TargetRegistry:
    _targets: dict[str, GeneratorTarget] = field(default_factory=dict)

    def register(self, target: GeneratorTarget) -> None:
        key = target.name.lower().strip()
        if not key:
            raise ValueError("Target name must not be empty.")
        if key in self._targets:
            raise ValueError(f"Target '{key}' already registered.")
        self._targets[key] = target

    def get(self, name: str) -> GeneratorTarget:
        key = name.lower().strip()
        if key not in self._targets:
            supported = ", ".join(sorted(self._targets)) or "<none>"
            raise ValueError(f"Unknown target '{name}'. Supported targets: {supported}")
        return self._targets[key]

    def names(self) -> list[str]:
        return sorted(self._targets.keys())
