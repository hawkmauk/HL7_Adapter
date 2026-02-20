"""SysML parser: regex-based extraction of model elements from .sysml files."""

from .driver import parse_model_directory
from .model import ModelAttribute, ModelElement, ModelIndex

__all__ = [
    "ModelAttribute",
    "ModelElement",
    "ModelIndex",
    "parse_model_directory",
]
