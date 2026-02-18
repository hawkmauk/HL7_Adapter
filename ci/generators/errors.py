from __future__ import annotations


class GenerationError(Exception):
    """Base error for all generation-related failures."""


class ParsingError(GenerationError):
    """Errors raised while parsing SysML model files."""


class ValidationError(GenerationError):
    """Errors raised while validating the model index or extraction graph."""

