#!/usr/bin/env python3
"""
Prüft die Konsistenz der Projektdokumentation:
1) PLAN_PHASES.md:
    - Streams mit Status "✅ ABGESCHLOSSEN" dürfen keine offenen "- [ ]" Checkboxen enthalten.
2) Markdown-Links:
    - Interne Links in *.md müssen auf existierende Pfade zeigen.
3) Dateiendungen:
    - Markdown-Dateien müssen die Endung .md (klein) verwenden; .MD ist nicht erlaubt.

Exit Codes:
0 = alles konsistent
1 = Inkonsistenzen gefunden
2 = Datei fehlt / Lesefehler
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


def check_closed_streams(plan_path: Path) -> tuple[bool, list[tuple[str, int]]]:
    text = plan_path.read_text(encoding="utf-8")
    parts = re.split(r"(^#### .*?$)", text, flags=re.M)
    issues: list[tuple[str, int]] = []

    for index in range(1, len(parts), 2):
        header = parts[index].strip()
        body = parts[index + 1]

        if "✅ ABGESCHLOSSEN" not in header:
            continue

        unchecked = len(re.findall(r"^- \[ \]", body, flags=re.M))
        if unchecked > 0:
            issues.append((header, unchecked))

    return (len(issues) == 0, issues)


def check_internal_md_links(root: Path) -> tuple[bool, list[tuple[Path, str]]]:
    link_pattern = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
    broken: list[tuple[Path, str]] = []

    for md_file in root.rglob("*.md"):
        try:
            text = md_file.read_text(encoding="utf-8")
        except OSError:
            continue

        for target in link_pattern.findall(text):
            if target.startswith("http://") or target.startswith("https://"):
                continue

            target_path = target.split("#", 1)[0]
            if target_path == "":
                continue

            resolved = (md_file.parent / target_path).resolve()
            if not resolved.exists():
                broken.append((md_file, target))

    return (len(broken) == 0, broken)


def check_md_extension_case(root: Path) -> tuple[bool, list[Path]]:
    wrong_case_files = sorted(root.rglob("*.MD"))
    return (len(wrong_case_files) == 0, wrong_case_files)


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    plan_path = root / "PLAN_PHASES.md"

    if not plan_path.exists():
        print("ERROR: PLAN_PHASES.md nicht gefunden.")
        return 2

    try:
        stream_check_ok, stream_issues = check_closed_streams(plan_path)
    except OSError as exc:
        print(f"ERROR: PLAN_PHASES.md konnte nicht gelesen werden: {exc}")
        return 2

    links_check_ok, broken_links = check_internal_md_links(root)
    extension_check_ok, wrong_case_files = check_md_extension_case(root)

    if stream_check_ok:
        print("OK: Keine offenen Checkboxen in als abgeschlossen markierten Streams.")
    else:
        print("FEHLER: Inkonsistenzen gefunden (abgeschlossene Streams mit offenen Checkboxen):")
        for header, count in stream_issues:
            print(f"- {header} -> offene Checkboxen: {count}")

    if links_check_ok:
        print("OK: Keine gebrochenen internen Markdown-Links gefunden.")
    else:
        print("FEHLER: Gebrochene interne Markdown-Links gefunden:")
        for file_path, target in broken_links:
            print(f"- {file_path} -> {target}")

    if extension_check_ok:
        print("OK: Keine .MD-Dateien gefunden (nur .md).")
    else:
        print("FEHLER: Markdown-Dateien mit falscher Endung gefunden (.MD statt .md):")
        for file_path in wrong_case_files:
            print(f"- {file_path}")

    if stream_check_ok and links_check_ok and extension_check_ok:
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
