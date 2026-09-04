#!/usr/bin/env python3
"""Wrap Japanese UI string literals in tr(...) and manage the translation table.

  scripts/i18n_codemod.py extract   → prints stats, writes scripts/i18n_keys.json (unique ja keys)
  scripts/i18n_codemod.py apply     → rewrites JiuFlow/Views/**/*.swift in place
  scripts/i18n_codemod.py leftovers → lists Japanese literals that were NOT wrapped (for manual review)

Rules
- Only files under JiuFlow/Views (UI). Models/Services/AppIntents are data — untouched.
- A literal is wrapped when the token right before it is a known UI construct (Text(, title:, …)
  or when it is an element of an array/tuple literal that is clearly display data.
- Never wrapped: comparisons (==, !=, contains, hasPrefix, case), dictionary keys, `page:` (analytics),
  `id:`/`key:`/`forKey:`/`type:`, print/log, interpolated strings ("\\(x)分" → manual), already-localized
  (lang.t( / tr( on the same line before the literal).
"""
import json, os, re, sys, glob

ROOT = os.path.join(os.path.dirname(__file__), "..")
VIEWS = os.path.join(ROOT, "JiuFlow", "Views")
KEYS_PATH = os.path.join(ROOT, "scripts", "i18n_keys.json")

JP = re.compile(r"[぀-ヿ一-鿿]")
LIT = re.compile(r'"((?:[^"\\]|\\.)*)"')

# callee( / label:  → wrap
WRAP_CALLEES = {
    "Text", "Button", "Label", "TextField", "SecureField", "TextEditor", "Section", "Picker", "Toggle",
    "DatePicker", "Stepper", "Menu", "Link", "NavigationLink", "ProgressView", "ContentUnavailableView",
    ".navigationTitle", ".confirmationDialog", ".alert", ".accessibilityLabel", ".accessibilityHint",
    ".help", ".badge", ".searchable",
}
WRAP_LABELS = {
    "classType", "dayLabel", "actionTitle", "tag", "tagLabel", "badgeText", "feature", "countUnit", "statLabel", "emptyTitle", "emptyMessage",
    "title", "subtitle", "description", "desc", "detail", "label", "message", "text", "prompt", "placeholder",
    "name", "value", "unit", "period", "hint", "caption", "footer", "header", "buttonTitle", "emptyText",
    "primaryLabel", "secondaryLabel", "tip", "body", "summary", "action", "cta", "line", "reason",
    "displayName", "question", "answer", "titleJa", "nameJa", "descJa", "descriptionJa",
}
# custom helper functions in this codebase whose first/any string arg is displayed
WRAP_HELPERS = {
    "filterChip", "actionBtn", "settingSectionHeader", "profileField", "tierFeatureRow", "SectionHeader",
    "MenuRow", "DashboardStat", "FeatureRow", "StatCard", "infoSection", "logCard", "quickButton", "statPill",
    "orgButton", "sectionHeader", "menuSection", "chip", "pill", "row", "card", "faqCard", "featureCard",
    "planCard", "metricCard", "statBox", "emptyState", "badge", "tag", "smallStat", "kv", "InfoRow", "StatRow",
    "SettingRow", "OnboardingPage", "FAQItem", "Feature", "Step", "Tip", "Benefit",
    "quickLogButton", "resultButton", "myStatItem", "statItem", "onError", "SharePreview", ".value", "return",
}
# Comparison / key contexts: a literal seen here anywhere in the codebase is an *identifier* → never wrapped.
COMPARE_BEFORE = re.compile(
    r"(==|!=|\bcase\s*$|\bcase\s+\.?\w*\s*,\s*$|forKey:|\bkey:|\bid:|\btype:|"
    r"\bslug:|\bidentifier:|\bswitch\b|\bvideo_type\b|UserDefaults|AppStorage|"
    r"\brawValue\b|\bfilter\s*=\s*$|\bselected\w*\s*=\s*$|\bcategory\s*=\s*$)"
)


def is_compare(pre: str) -> bool:
    """True when the nearest governing token before the literal is a comparison/key context.
    `days == 1 ? "昨日"` and `id: "x", name: "…"` are NOT comparisons for the literal."""
    window = pre[-60:]
    last = None
    for m in COMPARE_BEFORE.finditer(window):
        last = m
    if not last:
        return False
    tail = window[last.end():]
    if re.search(r"[?]", tail):                 # ternary → display value
        return False
    if re.search(r"\b\w+\s*:\s*$", tail):        # another label (name:, title:) governs the literal
        return False
    if re.search(r"\{\s*(return\s*)?$", tail):     # `if x == 0 { return "…"` → display
        return False
    return True
# Local-only skips: this occurrence is not UI (analytics label, symbol name, URL, log) but other occurrences may be.
LOCAL_SKIP = re.compile(r"(\bprint\(|\blog\(|\bpage:|\burl:|\bURL\(|\bsystemImage:|\bsystemName:|\.tag\(|\bdateFormat\s*=|\bformat:|"
                        r"\.contains\(|\.hasPrefix\(|\.hasSuffix\(|\.range\(|\.replacingOccurrences|NSPredicate)")
SKIP_BEFORE = re.compile("(" + COMPARE_BEFORE.pattern[1:-1] + "|" + LOCAL_SKIP.pattern[1:-1] + ")")


def classify(pre: str):
    """Return the token that governs the literal at the end of `pre`, or None."""
    p = pre.rstrip()
    m = re.search(r"([A-Za-z_][A-Za-z0-9_]*|\.[A-Za-z_][A-Za-z0-9_]*)\s*\(\s*$", p)
    if m:
        return ("callee", m.group(1))
    m = re.search(r"([A-Za-z_][A-Za-z0-9_]*)\s*:\s*$", p)
    if m:
        return ("label", m.group(1))
    m = re.search(r"([,\[\(\?:])\s*$", p)
    if m:
        return ("seq", m.group(1))
    m = re.search(r"\breturn\s*$", p)
    if m:
        return ("return", "return")
    return None


def enclosing_call(pre: str):
    """Best-effort: the innermost unclosed callee( on this line before the literal."""
    depth = 0
    for i in range(len(pre) - 1, -1, -1):
        c = pre[i]
        if c == ")":
            depth += 1
        elif c == "(":
            if depth == 0:
                m = re.search(r"([A-Za-z_][A-Za-z0-9_]*|\.[A-Za-z_][A-Za-z0-9_]*)\s*$", pre[:i])
                return m.group(1) if m else None
            depth -= 1
    return None


IDENTIFIERS = set()


def collect_identifiers(files):
    """JP literals that appear in comparison/key contexts anywhere → treated as identifiers, never wrapped."""
    for f in files:
        for line in open(f, encoding="utf-8"):
            cpe = case_pattern_end(line)
            for m in LIT.finditer(line):
                lit = m.group(1)
                if not JP.search(lit):
                    continue
                if is_compare(line[:m.start()]) or (cpe != -1 and m.start() < cpe):
                    IDENTIFIERS.add(lit)
                # `x == "…"` with the literal after the operator, and `"…":` dictionary keys
            for m in re.finditer(r'(==|!=)\s*"((?:[^"\\]|\\.)*)"', line):
                if JP.search(m.group(2)):
                    IDENTIFIERS.add(m.group(2))
            for m in re.finditer(r'[\[,]\s*"((?:[^"\\]|\\.)*)"\s*:', line):   # ["key": …] dictionary literal keys
                if JP.search(m.group(1)):
                    IDENTIFIERS.add(m.group(1))


def case_pattern_end(line: str):
    """For a line starting with `case`, index of the ':' that ends the pattern (ignoring quoted text), else -1."""
    if not line.lstrip().startswith("case "):
        return -1
    in_str = False
    i = 0
    while i < len(line):
        c = line[i]
        if c == "\\" and in_str:
            i += 2
            continue
        if c == '"':
            in_str = not in_str
        elif c == ":" and not in_str:
            return i
        i += 1
    return -1


def should_wrap(line: str, start: int, literal: str):
    if "\\(" in literal:
        return False, "interp"
    cpe = case_pattern_end(line)
    if cpe != -1 and start < cpe:
        return False, "case-pattern"
    if literal in IDENTIFIERS:
        return False, "identifier"
    pre = line[:start]
    if re.search(r"(lang|langMgr|L10n)\.t\(|\btr\(", pre):
        # already inside a localization call on this line (approximation)
        if pre.count("(") > pre.count(")"):
            return False, "localized"
    if is_compare(pre) or LOCAL_SKIP.search(pre[-60:]):
        return False, "skip-ctx"
    if pre.strip() == "":
        return True, "array-line"          # multi-line array: a line that is just "…",
    if re.search(r"\b(message|title|subtitle|text|label|placeholder|desc|description|hint|caption|prompt|greeting|emptyText|errorMessage|replyResult|toastMsg|result|resultMessage|statusMessage|content\.body|content\.title)\w*\s*(:\s*String)?\s*=\s*$", pre):
        return True, "default-value"
    k = classify(pre)
    if not k:
        return False, "no-ctx"
    kind, tok = k
    if kind == "callee" and (tok in WRAP_CALLEES or tok in WRAP_HELPERS):
        return True, tok
    if kind == "label" and (tok in WRAP_LABELS):
        return True, tok
    if kind == "return":
        return True, "return"
    if kind == "seq":
        enc = enclosing_call(pre)
        if enc and (enc in WRAP_CALLEES or enc in WRAP_HELPERS):
            return True, f"seq@{enc}"
        # array of display strings: ["A", "B"] used by ForEach/Picker → wrap
        if re.search(r"=\s*\[\s*$|\[\s*$", pre.rstrip()) or re.match(r"\s*\"", line):
            return True, "array"
        if tok == "," and re.search(r"\[[^\]]*\"[^\"]*\"[^\]]*$", pre):
            return True, "array"
        if tok in (",", "(") and re.search(r"[\(\[][^\)\]]*$", pre):
            return True, "tuple"           # (0, "未学習", "circle", .gray) style display data
        if tok == "?" or tok == ":":
            return True, "ternary"         # cond ? "A" : "B"
        return False, f"seq-{enc or '?'}"
    return False, f"{kind}-{tok}"


def process(path: str, apply: bool):
    src = open(path, encoding="utf-8").read()
    out_lines = []
    wrapped, left = [], []
    for line in src.split("\n"):
        comment_idx = None
        # strip trailing // comment (not inside a string) for analysis only
        in_str = False
        i = 0
        while i < len(line):
            c = line[i]
            if c == "\\" and in_str:
                i += 2
                continue
            if c == '"':
                in_str = not in_str
            elif not in_str and line.startswith("//", i):
                comment_idx = i
                break
            i += 1
        if line.lstrip().startswith("//") or line.lstrip().startswith("///"):
            out_lines.append(line)
            continue
        analysis = line if comment_idx is None else line[:comment_idx]
        new = ""
        pos = 0
        for m in LIT.finditer(analysis):
            lit = m.group(1)
            if not JP.search(lit):
                continue
            ok, why = should_wrap(analysis, m.start(), lit)
            if ok:
                wrapped.append((lit, why))
                new += analysis[pos:m.start()] + f'tr("{lit}")'
                pos = m.end()
            else:
                left.append((lit, why, line.strip()))
        new += line[pos:]
        out_lines.append(new if apply else line)
    if apply and wrapped:
        open(path, "w", encoding="utf-8").write("\n".join(out_lines))
    return wrapped, left


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "extract"
    files = sorted(glob.glob(os.path.join(VIEWS, "**", "*.swift"), recursive=True))
    collect_identifiers(sorted(glob.glob(os.path.join(ROOT, "JiuFlow", "**", "*.swift"), recursive=True)))
    all_w, all_l = [], []
    per_file = {}
    for f in files:
        w, l = process(f, apply=(mode == "apply"))
        all_w += w
        all_l += [(f,) + x for x in l]
        if w or l:
            per_file[os.path.relpath(f, VIEWS)] = (len(w), len(l))
    keys = sorted(set(k for k, _ in all_w))
    if mode in ("extract", "apply"):
        existing = {}
        if os.path.exists(KEYS_PATH):
            existing = json.load(open(KEYS_PATH, encoding="utf-8"))
        for k in keys:
            existing.setdefault(k, {"en": "", "pt": ""})
        json.dump(existing, open(KEYS_PATH, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print(f"wrapped={len(all_w)} unique_keys={len(keys)} leftovers={len(all_l)} files_touched={len(per_file)}")
        from collections import Counter
        print("wrap reasons:", Counter(w for _, w in all_w).most_common(12))
        print("leftover reasons:", Counter(x[2] for x in all_l).most_common(15))
        print(f"identifiers (never wrapped): {len(IDENTIFIERS)} e.g. {sorted(IDENTIFIERS)[:25]}")
    if mode == "leftovers":
        for f, lit, why, ln in all_l:
            print(f"{os.path.relpath(f, VIEWS)} | {why} | {lit} | {ln[:110]}")


if __name__ == "__main__":
    main()
