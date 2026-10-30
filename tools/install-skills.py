#!/usr/bin/env python3
"""Install/update project-level Agent Skills under .agents/skills/.

Usage:
  python3 tools/install-skills.py            # install from cached clones (clone if missing)
  python3 tools/install-skills.py --update   # git pull upstream first
  python3 tools/install-skills.py --check    # verify installed dirs have SKILL.md

Source repos are cached in .research/skills-repos/ (gitignored).
Selection is intentionally curated; add entries to INSTALLS to extend.
"""
from __future__ import annotations

import argparse
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / ".research" / "skills-repos"
DEST = ROOT / ".agents" / "skills"

REPOS = {
    "godot-skill": "https://github.com/haxqer/godot-skill.git",
    "awesome-gamedev-skills": "https://github.com/gamedev-skills/awesome-gamedev-agent-skills.git",
    "godotprompter": "https://github.com/jame581/GodotPrompter.git",
    "game-dev-agentic-skills": "https://github.com/thedivergentai/Game-Dev-Agentic-Skills.git",
    "cty41-skills": "https://github.com/cty41/skills.git",
}

# (repo key, path inside repo, install directory name under .agents/skills)
INSTALLS = [
    ("godot-skill", "skill/godot", "godot"),
    ("awesome-gamedev-skills", "skills/godot/godot-gdscript", "godot-gdscript"),
    ("awesome-gamedev-skills", "skills/godot/godot-gdscript-headless-testing", "godot-gdscript-headless-testing"),
    ("awesome-gamedev-skills", "skills/godot/godot-resources", "godot-resources"),
    ("awesome-gamedev-skills", "skills/godot/godot-tilemap", "godot-tilemap"),
    ("awesome-gamedev-skills", "skills/disciplines/ai-behavior-trees-utility-ai", "ai-behavior-trees-utility-ai"),
    ("godotprompter", "skills/godot-project-setup", "godot-project-setup"),
    ("godotprompter", "skills/gdscript-patterns", "gdscript-patterns"),
    ("godotprompter", "skills/event-bus", "event-bus"),
    ("godotprompter", "skills/state-machine", "state-machine"),
    ("godotprompter", "skills/resource-pattern", "resource-pattern"),
    ("godotprompter", "skills/scene-organization", "scene-organization"),
    ("godotprompter", "skills/godot-code-review", "godot-code-review"),
    ("godotprompter", "skills/godot-debugging", "godot-debugging"),
    ("godotprompter", "skills/procedural-generation", "procedural-generation"),
    ("godotprompter", "skills/godot-ui", "godot-ui"),
    ("godotprompter", "skills/godot-grill", "godot-grill"),
    ("game-dev-agentic-skills", "skills/godot-genre-roguelike", "godot-genre-roguelike"),
    ("game-dev-agentic-skills", "skills/godot-combat-system", "godot-combat-system"),
    ("game-dev-agentic-skills", "skills/godot-ability-system", "godot-ability-system"),
    ("game-dev-agentic-skills", "skills/godot-economy-system", "godot-economy-system"),
    ("cty41-skills", "plan-plain", "plan-plain"),
    ("cty41-skills", "project-doc-organization", "project-doc-organization"),
    ("cty41-skills", "skill-writing", "skill-writing"),
]


def run(cmd: list[str], cwd: pathlib.Path | None = None) -> None:
    print(f"$ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=True)


def ensure_sources(update: bool) -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    for key, url in REPOS.items():
        path = CACHE / key
        if not path.exists():
            run(["git", "clone", "--depth", "1", "--single-branch", url, str(path)])
        elif update:
            run(["git", "-C", str(path), "pull", "--ff-only"])


def install() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for repo, rel, name in INSTALLS:
        src = CACHE / repo / rel
        if not (src / "SKILL.md").is_file():
            sys.exit(f"ERROR: missing {src}/SKILL.md")
        dst = DEST / name
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        print(f"installed {name}")


def check() -> None:
    missing = [name for _, _, name in INSTALLS if not (DEST / name / "SKILL.md").is_file()]
    if missing:
        sys.exit(f"missing skills: {', '.join(missing)}")
    print(f"OK: {len(INSTALLS)} external skills + folded-dungeon (project-specific)")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--update", action="store_true", help="git pull upstream repos before install")
    ap.add_argument("--check", action="store_true", help="only verify installed skills")
    args = ap.parse_args()
    if args.check:
        check()
        return
    ensure_sources(args.update)
    install()
    check()


if __name__ == "__main__":
    main()
