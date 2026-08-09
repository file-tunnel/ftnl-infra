#!/usr/bin/env python3
"""Validate environment ownership and keep plaintext credentials out of Git."""

from __future__ import annotations

import re
import subprocess
import sys
import tomllib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NAME = re.compile(r"^[A-Z][A-Z0-9_]*$")
ALLOWED_CLASSIFICATIONS = {
    "non-secret",
    "public-config",
    "public-credential",
    "sensitive-config",
    "secret",
}
ALLOWED_SOURCES = {"sops", "fiducia-kv", "kubernetes-manifest"}
ALLOWED_DELIVERY = {
    "local-file",
    "deployment-workflow",
    "fiducia-external-secret",
    "pod-env",
}
PLACEHOLDERS = {"", "replace-me", "changeme", "todo"}


def fail(message: str) -> None:
    raise ValueError(message)


def tracked_files() -> set[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    return {item.decode() for item in result.stdout.split(b"\0") if item}


def parse_dotenv_keys(path: Path) -> set[str]:
    keys: set[str] = set()
    for number, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("sops_"):
            continue
        if "=" not in line:
            fail(f"{path.relative_to(ROOT)}:{number}: expected NAME=value")
        key, value = line.split("=", 1)
        if not NAME.fullmatch(key):
            fail(f"{path.relative_to(ROOT)}:{number}: invalid variable name {key!r}")
        if key in keys:
            fail(f"{path.relative_to(ROOT)}:{number}: duplicate variable {key}")
        if path.name.endswith(".example") and value.strip().lower() not in PLACEHOLDERS and not value.startswith("https://replace-me"):
            fail(f"{path.relative_to(ROOT)}:{number}: examples must contain placeholders only")
        keys.add(key)
    return keys


def main() -> int:
    manifest = tomllib.loads((ROOT / "env/ownership.toml").read_text())
    rows = manifest.get("variables", [])
    if not rows:
        fail("env/ownership.toml has no variables")

    names: set[str] = set()
    sops_names: set[str] = set()
    for row in rows:
        name = row.get("name", "")
        if not NAME.fullmatch(name):
            fail(f"invalid ownership name {name!r}")
        if name in names:
            fail(f"{name} has more than one source of record")
        names.add(name)
        if row.get("classification") not in ALLOWED_CLASSIFICATIONS:
            fail(f"{name}: unsupported classification")
        if row.get("source") not in ALLOWED_SOURCES:
            fail(f"{name}: unsupported source")
        if row.get("runtime_delivery") not in ALLOWED_DELIVERY:
            fail(f"{name}: unsupported runtime delivery")
        consumers = row.get("consumers")
        if not isinstance(consumers, list) or not consumers:
            fail(f"{name}: at least one consumer is required")
        if row["source"] == "sops":
            sops_names.add(name)

    template_names = parse_dotenv_keys(ROOT / "env/template.env.example")
    if template_names != sops_names:
        fail(
            "template and SOPS-owned names differ: "
            f"missing={sorted(sops_names - template_names)} "
            f"unexpected={sorted(template_names - sops_names)}"
        )

    tracked = tracked_files()
    forbidden: list[str] = []
    for item in tracked:
        path = Path(item)
        if item == ".env" or item.startswith("env/dec/"):
            forbidden.append(item)
        elif path.suffix == ".env" and item != "env/template.env.example":
            forbidden.append(item)
        elif path.name.startswith(".env") and item not in {".envrc", ".env.example"}:
            forbidden.append(item)
    if forbidden:
        fail(f"plaintext environment files are tracked: {sorted(forbidden)}")

    encrypted = sorted((ROOT / "env/enc").glob("*.env.enc"))
    for path in encrypted:
        content = path.read_text()
        if "ENC[AES256_GCM" not in content or "sops_age__list_0__map_enc" not in content:
            fail(f"{path.relative_to(ROOT)} is not SOPS age ciphertext")
        encrypted_keys = parse_dotenv_keys(path)
        if encrypted_keys != sops_names:
            fail(
                f"{path.relative_to(ROOT)} key set differs from ownership: "
                f"missing={sorted(sops_names - encrypted_keys)} "
                f"unexpected={sorted(encrypted_keys - sops_names)}"
            )

    print(
        f"environment contract valid: {len(names)} owned variables, "
        f"{len(encrypted)} encrypted bundle(s), no tracked plaintext"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, ValueError, tomllib.TOMLDecodeError) as error:
        print(f"environment validation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
