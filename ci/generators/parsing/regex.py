"""All compiled regex constants used by the SysML parser."""
from __future__ import annotations

import re

BLOCK_DECL_RE = re.compile(
    r"(?m)^(?P<indent>\s*)(?P<kind>package|view|viewpoint|concern|requirement|part|port|interface|constraint|use\s+case|occurrence|action|state|attribute|item|verification)\s+"
    r"(?:(?:def)\s+)?"
    r"(?:(?:<(?P<short>[^>]+)>)\s+)?"
    r"(?P<name>'[^']+'|[A-Za-z_][A-Za-z0-9_]*)"
    r"(?P<tail>[^{;\n]*)\{"
)

ID_DECL_RE = re.compile(
    r"(?m)^\s*(?P<kind>view|viewpoint|concern|requirement|part|state)\s+"
    r"(?:(?:def)\s+)?"
    r"(?P<name>[A-Z]+_[A-Za-z0-9_]+)\b"
)

DOC_RE = re.compile(r"doc\s*/\*(?P<doc>.*?)\*/", re.DOTALL)
EXPOSE_RE = re.compile(r"(?m)^\s*expose\s+(?P<ref>[^;]+);")
SATISFY_RE = re.compile(r"(?m)^\s*satisfy\s+(?P<ref>[^;]+);")
FRAME_RE = re.compile(r"(?m)^\s*frame\s+(?P<ref>[^;]+);")
RENDER_RE = re.compile(r"(?m)^\s*render\s+as(?P<kind>[A-Za-z0-9_]+)\s*;")
ATTRIBUTE_RE = re.compile(
    r"(?m)^\s*attribute\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_]*(?:\[\*\])?)"
    r"\s*:\s*(?P<type>[^;{]+);"
)
ATTRIBUTE_NO_SEMICOLON_RE = re.compile(
    r"(?m)^\s*attribute\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_]*(?:\[\*\])?)"
    r"\s*:\s*(?P<type>[^{]+)\s*\{\s*doc\s*/\*.*?\*/\s*\}",
)
# constant name : Type = value (value up to ; or {)
CONSTANT_RE = re.compile(
    r"(?m)^\s*constant\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_]*)"
    r"\s*:\s*(?P<type>[^=]+)=\s*(?P<value>[^;{]+?)\s*[;{]",
)
ALIAS_RE = re.compile(r"(?m)^\s*alias\s+(?P<alias>[A-Za-z_][A-Za-z0-9_]*)\s+for\s+(?P<target>[A-Za-z_][A-Za-z0-9_]*)\s*;")
FLOW_PROPERTY_RE = re.compile(
    r"(?m)^\s*(?P<dir>in|out)\s+(?P<kind>item|attribute)\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_']*)\s*:\s*(?P<type>[^;]+);"
)
INTERFACE_END_RE = re.compile(
    r"(?m)^\s*end\s+(?P<role>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?P<port_type>[A-Za-z_][A-Za-z0-9_]*)\s*;"
)
ALLOCATION_SATISFY_RE = re.compile(
    r"(?m)^\s*satisfy\s+requirement\s+'([^']+)'\s+by\s+([^;]+);"
)
REFINEMENT_DEPENDENCY_RE = re.compile(
    r"(?m)#refinement\s+dependency\s+'([^']+)'\s+to\s+'([^']+)';"
)
PART_INLINE_RE = re.compile(
    r"(?m)^\s*part\s+(?::>>\s*)?(?:<(?P<short>[^>]+)>)?\s*"
    r"(?P<name>'[^']+'|[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?P<types>[^;]+);"
)
CONSTRAINT_PARAM_RE = re.compile(
    r"(?m)^\s*in\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?P<type>[^;]+);"
)
ATTR_VALUE_ASSIGN_RE = re.compile(r"attribute\s+::>\s+value\s*=\s*([\d.]+)")
ATTR_WEIGHT_ASSIGN_RE = re.compile(r"attribute\s+::>\s+weight\s*=\s*([\d.]+)")

ATTR_DEF_SIGNAL_RE = re.compile(
    r"(?m)^\s*attribute\s+def\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*;"
)

ACCEPT_THEN_RE = re.compile(
    r"(?m)^\s*accept\s+(?P<signal>[A-Za-z_][A-Za-z0-9_]*)\s+then\s+(?P<target>[A-Za-z_][A-Za-z0-9_]*)\s*;"
)

STATE_OR_ACCEPT_RE = re.compile(
    r"(?m)(?:^\s*state\s+(?P<state_name>[A-Za-z_][A-Za-z0-9_]*)\s*[;{])"
    r"|(?:^\s*accept\s+(?P<signal>[A-Za-z_][A-Za-z0-9_]*)\s+then\s+(?P<target>[A-Za-z_][A-Za-z0-9_]*)\s*;)"
)

ENTRY_THEN_RE = re.compile(
    r"(?m)^\s*entry\s*;\s*then\s+(?P<target>[A-Za-z_][A-Za-z0-9_]*)\s*;"
)

ENTRY_ACTION_RE = re.compile(
    r"(?m)^\s*entry\s+(?P<action>[A-Za-z_][A-Za-z0-9_]*)"
)

DO_ACTION_RE = re.compile(
    r"(?m)^\s*do\s+(?P<action>[A-Za-z_][A-Za-z0-9_]*)"
)

STATE_PORT_RE = re.compile(
    r"(?m)^\s*(?P<dir>in|out)\s+(?P<name>'[^']+'|[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?P<type>[^;{]+);"
)

ACTION_USAGE_RE = re.compile(
    r"(?m)^\s*action\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?P<type>[^;{]+);"
)

PERFORM_ACTION_RE = re.compile(
    r"(?m)^\s*perform\s+action\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?P<type>[^;{]+);"
)

ACTION_PARAM_RE = re.compile(
    r"(?m)^\s*(?P<dir>in|out)\s+(?:attribute\s+)?(?::>\s*)?(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*(?::\s*(?P<type>[^;{]+))?\s*;"
)

INLINE_STATE_RE = re.compile(
    r"(?m)^\s*state\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*;"
)

STATE_DEF_RE = re.compile(
    r"(?m)^\s*state\s+def\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*;"
)

# Verification case: objective { verify <requirement>; }
VERIFY_REF_RE = re.compile(r"verify\s+([A-Za-z0-9_:]+)\s*;")
# Verification case: subject <name> : <type>;
SUBJECT_RE = re.compile(r"(?m)^\s*subject\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^;]+);")

# exhibit state <usage_name>; or exhibit <usage_name> { ... }
EXHIBIT_RE = re.compile(
    r"(?m)^\s*exhibit\s+(?:state\s+)?(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*[;{]"
)

# SysML v2 named rep blocks: rep <name> language "lang" /* body */
NAMED_REP_RE = re.compile(
    r"rep\s+(\w+)\s+language\s+\"([^\"]+)\"\s*/\*(.*?)\*/",
    re.DOTALL,
)
TEXTUAL_REPRESENTATION_RE = NAMED_REP_RE
