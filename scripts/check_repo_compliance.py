from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RULE_START = "2026-04-29T00:00:00"


def run(*args: str) -> str:
    result = subprocess.run(
        list(args),
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return result.stdout.strip()


def count_mbt_lines() -> int:
    total = 0
    for path in ROOT.glob("src/**/*.mbt"):
        total += sum(1 for _ in path.open("r", encoding="utf-8"))
    return total


def workflow_contains(path: Path, needles: list[str]) -> bool:
    if not path.exists():
        return False
    content = path.read_text(encoding="utf-8")
    return all(needle in content for needle in needles)


def remote_default_branch(remote: str) -> str | None:
    try:
        url = run("git", "remote", "get-url", remote)
        symref = run("git", "ls-remote", "--symref", url, "HEAD")
    except RuntimeError:
        return None
    for line in symref.splitlines():
        if line.startswith("ref: "):
            return line.split("\t", 1)[0].rsplit("/", 1)[-1]
    return None


def main() -> int:
    required_files = {
        "README.md": (ROOT / "README.md").exists(),
        "LICENSE": (ROOT / "LICENSE").exists(),
        ".github/workflows/ci.yml": (ROOT / ".github/workflows/ci.yml").exists(),
        ".gitea/workflows/ci.yml": (ROOT / ".gitea/workflows/ci.yml").exists(),
        "src/moontemplate/pkg.generated.mbti": (ROOT / "src/moontemplate/pkg.generated.mbti").exists(),
        "docs/source-attribution.md": (ROOT / "docs/source-attribution.md").exists(),
    }
    workflow_needles = [
        "moon fmt --check",
        "moon info",
        "moon build",
        "moon check --deny-warn",
        "moon check --target native --deny-warn",
        "moon test --deny-warn",
        "moon test --target native --deny-warn",
    ]
    report = {
        "commit_count": int(run("git", "rev-list", "--count", "HEAD")),
        "post_2026_04_29_commits": int(run("git", "rev-list", "--count", f"--since={RULE_START}", "HEAD")),
        "moonbit_source_lines": count_mbt_lines(),
        "default_branch": {
            "github": remote_default_branch("github"),
            "origin": remote_default_branch("origin"),
        },
        "required_files": required_files,
        "workflow_checks": {
            "github_ci": workflow_contains(ROOT / ".github/workflows/ci.yml", workflow_needles),
            "gitea_ci": workflow_contains(ROOT / ".gitea/workflows/ci.yml", workflow_needles),
        },
        "tracked_build_artifacts": run("git", "ls-files", "_build").splitlines(),
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    ok = (
        all(required_files.values())
        and all(report["workflow_checks"].values())
        and not report["tracked_build_artifacts"]
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
