#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
import os
import re
import secrets
import sys
from dataclasses import dataclass
from typing import Dict, List, Pattern, Tuple, Optional

TOKEN_PREFIX = "⟦"
TOKEN_SUFFIX = "⟧"


@dataclass
class Rule:
    name: str
    pattern: Pattern[str]


def compile_rules(enabled: Optional[List[str]] = None) -> List[Rule]:
    raw_rules: List[Tuple[str, str]] = [
        ("email", r"\b[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+\b"),
        ("phone", r"(?<!\d)(?:\+?\d{1,3}[- ]?)?(?:\d[- ]?){9,12}\d(?!\d)"),
        ("ipv4", r"\b(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\b"),
        ("url", r"\bhttps?://[^\s<>()\"']+\b"),
        ("jwt", r"\beyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\b"),
        ("bearer", r"(?i)\bBearer\s+[A-Za-z0-9._-]{12,}\b"),
        ("api_key", r"\bsk-[A-Za-z0-9]{16,}\b"),
        ("aws_access_key", r"\bAKIA[0-9A-Z]{16}\b"),
    ]
    rules = [Rule(name, re.compile(p)) for name, p in raw_rules]
    if enabled:
        enabled_set = set(enabled)
        rules = [r for r in rules if r.name in enabled_set]
    return rules


def read_text(path: Optional[str]) -> str:
    if path:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    return sys.stdin.read()


def write_text(path: Optional[str], text: str) -> None:
    if path:
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.write(text)


def make_token(label: str, counter: int) -> str:
    rid = secrets.token_hex(3)
    return f"{TOKEN_PREFIX}{label.upper()}_{counter}_{rid}{TOKEN_SUFFIX}"


def save_mapping(map_path: str, mapping: Dict[str, str], meta: Dict[str, str]) -> None:
    os.makedirs(os.path.dirname(os.path.abspath(map_path)), exist_ok=True)
    payload = {"meta": meta, "mapping": mapping}
    tmp = map_path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    os.replace(tmp, map_path)


def load_mapping(map_path: str) -> Dict[str, str]:
    with open(map_path, "r", encoding="utf-8") as f:
        obj = json.load(f)
    if not isinstance(obj, dict) or "mapping" not in obj or not isinstance(obj["mapping"], dict):
        raise SystemExit("[ERROR] Invalid mapping file format. Expect JSON with top-level key: mapping")
    return obj["mapping"]


def mask_text_by_rules(text: str, rules: List[Rule]) -> Tuple[str, Dict[str, str]]:
    mapping: Dict[str, str] = {}
    counters: Dict[str, int] = {r.name: 0 for r in rules}
    token_guard = re.compile(re.escape(TOKEN_PREFIX) + r".+?" + re.escape(TOKEN_SUFFIX))

    for rule in rules:
        def repl(m: re.Match) -> str:
            s = m.group(0)
            if token_guard.fullmatch(s or ""):
                return s
            counters[rule.name] += 1
            token = make_token(rule.name, counters[rule.name])
            mapping[token] = s
            return token

        text = rule.pattern.sub(repl, text)

    return text, mapping


def unmask_text(text: str, mapping: Dict[str, str], strict: bool = False) -> str:
    missing = [t for t in mapping.keys() if t not in text]
    if strict and missing:
        raise SystemExit(
            f"[ERROR] Some tokens from mapping were not found in text (strict mode). "
            f"Missing (first 5): {missing[:5]}{'...' if len(missing) > 5 else ''}"
        )

    for token in sorted(mapping.keys(), key=len, reverse=True):
        text = text.replace(token, mapping[token])

    if missing and not strict:
        sys.stderr.write(
            f"[WARN] {len(missing)} tokens in mapping not found in input text. "
            f"(This can happen if ChatGPT altered tokens.)\n"
        )
    return text


def _load_list_from_csv(csv_value: str) -> List[str]:
    if not csv_value:
        return []
    return [x.strip() for x in csv_value.split(",") if x.strip()]


def _load_list_from_file(path: str) -> List[str]:
    items: List[str] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            items.append(s)
    return items


def _mask_phrases(
    text: str,
    phrases: List[str],
    label: str,
    mapping: Dict[str, str],
    ignore_case: bool,
) -> str:
    if not phrases:
        return text

    phrases = sorted(set([p for p in phrases if p]), key=len, reverse=True)
    flags = re.IGNORECASE if ignore_case else 0
    token_guard = re.compile(re.escape(TOKEN_PREFIX) + r".+?" + re.escape(TOKEN_SUFFIX))

    counter = 0
    for ph in phrases:
        if re.fullmatch(r"[A-Za-z0-9_-]+", ph):
            pat = re.compile(rf"\b{re.escape(ph)}\b", flags)
        else:
            pat = re.compile(re.escape(ph), flags)

        def repl(m: re.Match) -> str:
            s = m.group(0)
            if token_guard.fullmatch(s or ""):
                return s
            nonlocal counter
            counter += 1
            token = make_token(label, counter)
            mapping[token] = s
            return token

        text = pat.sub(repl, text)

    return text


def cmd_mask(args: argparse.Namespace) -> None:
    text = read_text(args.input)

    # 1) Load phrase lists (your maintained file + optional temp phrases)
    phrases: List[str] = []
    if args.phrase_file:
        phrases += _load_list_from_file(args.phrase_file)
    if args.phrase:
        phrases += _load_list_from_csv(args.phrase)

    # 2) Apply phrase masking FIRST (explicit list wins)
    custom_mapping: Dict[str, str] = {}
    text = _mask_phrases(
        text=text,
        phrases=phrases,
        label="PHRASE",
        mapping=custom_mapping,
        ignore_case=args.phrase_ignore_case,
    )

    # 3) Apply built-in regex rules
    rules = compile_rules(args.enable)
    masked, rules_mapping = mask_text_by_rules(text, rules)

    merged_mapping = {**custom_mapping, **rules_mapping}
    meta = {
        "token_format": f"{TOKEN_PREFIX}...{TOKEN_SUFFIX}",
        "rules_enabled": ",".join([r.name for r in rules]),
        "phrase_file": args.phrase_file or "",
        "phrase_ignore_case": str(bool(args.phrase_ignore_case)),
        "phrase_count": str(len(set(phrases))),
        "note": "Keep this file locally. Do NOT send it to the LLM.",
    }

    save_mapping(args.map, merged_mapping, meta)
    write_text(args.output, masked)
    sys.stderr.write(f"[OK] Masked with {len(merged_mapping)} replacements. Mapping saved to: {args.map}\n")


def cmd_unmask(args: argparse.Namespace) -> None:
    text = read_text(args.input)
    mapping = load_mapping(args.map)
    restored = unmask_text(text, mapping, strict=args.strict)
    write_text(args.output, restored)
    sys.stderr.write("[OK] Unmasked.\n")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="llm_mask",
        description="Local reversible masking tool for sending text to ChatGPT/LLMs safely.",
    )
    sub = p.add_subparsers(dest="command", required=True)

    p_mask = sub.add_parser("mask", help="Mask sensitive info and output masked text.")
    p_mask.add_argument("--map", required=True, help="Path to write mapping JSON.")
    p_mask.add_argument("-i", "--input", help="Input file path. If omitted, read stdin.")
    p_mask.add_argument("-o", "--output", help="Output file path. If omitted, write stdout.")

    p_mask.add_argument(
        "--enable",
        nargs="+",
        help="Enable only specific built-in rules (space-separated). Example: --enable email phone ipv4",
    )

    # Your maintained phrase list + temp phrases
    p_mask.add_argument(
        "--phrase-file",
        help="File containing phrases to mask (one per line, # comments).",
    )
    p_mask.add_argument(
        "--phrase",
        help='Comma-separated temporary phrases to mask. Example: --phrase "ProjectX,cn40"',
    )
    p_mask.add_argument(
        "--phrase-ignore-case",
        action="store_true",
        default=True,
        help="Case-insensitive matching for phrase list (default: true).",
    )
    p_mask.add_argument(
        "--phrase-case-sensitive",
        action="store_true",
        help="Override: make phrase matching case-sensitive.",
    )

    p_mask.set_defaults(func=cmd_mask)

    p_unmask = sub.add_parser("unmask", help="Restore masked tokens using mapping JSON.")
    p_unmask.add_argument("--map", required=True, help="Path to read mapping JSON.")
    p_unmask.add_argument("-i", "--input", help="Input file path. If omitted, read stdin.")
    p_unmask.add_argument("-o", "--output", help="Output file path. If omitted, write stdout.")
    p_unmask.add_argument("--strict", action="store_true", help="Fail if some tokens are not found.")
    p_unmask.set_defaults(func=cmd_unmask)

    return p


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    # resolve phrase case flags
    if hasattr(args, "phrase_case_sensitive") and args.phrase_case_sensitive:
        args.phrase_ignore_case = False

    args.func(args)


if __name__ == "__main__":
    main()
