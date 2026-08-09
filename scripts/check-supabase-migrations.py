#!/usr/bin/env python3
"""Fail closed when a public table migration omits RLS or grants anon broadly."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CREATE_PUBLIC = re.compile(
    r"create\s+table(?:\s+if\s+not\s+exists)?\s+(?:public\.)?[\"']?([a-z_][a-z0-9_]*)",
    re.IGNORECASE,
)
RLS = re.compile(
    r"alter\s+table(?:\s+if\s+exists)?\s+(?:public\.)?[\"']?([a-z_][a-z0-9_]*)[\"']?\s+enable\s+row\s+level\s+security",
    re.IGNORECASE,
)
UNSAFE_GRANT = re.compile(r"grant\s+all\b.*\bto\s+(?:anon|authenticated)\b", re.IGNORECASE | re.DOTALL)


def main() -> int:
    failures: list[str] = []
    migrations = sorted((ROOT / "supabase/migrations").glob("*.sql"))
    for migration in migrations:
        sql = migration.read_text()
        if UNSAFE_GRANT.search(sql):
            failures.append(f"{migration.name}: GRANT ALL to a Data API role is forbidden")
        created = set(CREATE_PUBLIC.findall(sql))
        protected = set(RLS.findall(sql))
        for table in sorted(created - protected):
            failures.append(f"{migration.name}: public table {table} does not enable RLS in the same migration")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"Supabase migration policy valid: {len(migrations)} migration(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
