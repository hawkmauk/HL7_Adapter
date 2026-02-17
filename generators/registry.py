from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, List

from .base import GeneratorTarget


@dataclass(slots=True)
class TargetRegistry:
    """In-memory registry of generation targets keyed by their canonical name."""

    _targets: dict[str, GeneratorTarget] = field(default_factory=dict)

    def register(self, target: GeneratorTarget) -> None:
        """Register a concrete target instance."""
        key = target.name.lower().strip()
        if not key:
            raise ValueError("Target name must not be empty.")
        if key in self._targets:
            raise ValueError(f"Target '{key}' already registered.")
        self._targets[key] = target

    def get(self, name: str) -> GeneratorTarget:
        """Look up a target by name (case-insensitive)."""
        key = name.lower().strip()
        if key not in self._targets:
            supported = ", ".join(sorted(self._targets)) or "<none>"
            raise ValueError(f"Unknown target '{name}'. Supported targets: {supported}")
        return self._targets[key]

    def names(self) -> list[str]:
        """Return all registered target names in sorted order."""
        return sorted(self._targets.keys())


_TARGET_FACTORIES: List[Callable[[], GeneratorTarget]] = []


def register_target(factory: Callable[[], GeneratorTarget]) -> Callable[[], GeneratorTarget]:
    """
    Register a GeneratorTarget factory.

    This is intended to be used as a decorator in target modules, e.g.:

        @register_target
        def make_target() -> GeneratorTarget:
            return MyTarget()
    """
    _TARGET_FACTORIES.append(factory)
    return factory


def build_default_registry() -> TargetRegistry:
    """
    Build a TargetRegistry populated with all statically-registered targets.

    Target modules should call register_target() at import time so that
    they are included here. The CLI is responsible for importing the
    built-in targets before invoking this function.
    """
    registry = TargetRegistry()
    for factory in _TARGET_FACTORIES:
        registry.register(factory())
    return registry
