#!/usr/bin/env python3
"""Rebuild game/assets/art3d/manifests/art3d.json from the asset folders."""
import json
import pathlib
from PIL import Image

BASE = pathlib.Path("game/assets/art3d")

def main() -> None:
    manifest = {"version": 1, "generated": "2026-10-31", "items": []}
    for sub, kind in [("materials", "material"), ("units", "unit")]:
        for p in sorted((BASE / sub).glob("*.png")):
            img = Image.open(p)
            manifest["items"].append({
                "id": f"{kind}:{p.stem}",
                "file": f"{sub}/{p.name}",
                "kind": kind,
                "size": [img.width, img.height],
                "alpha": img.mode in ("RGBA", "LA"),
            })
    out = BASE / "manifests" / "art3d.json"
    out.write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    print("wrote", out, "items:", len(manifest["items"]))

if __name__ == "__main__":
    main()
