#!/usr/bin/env python3
"""Remove a green-screen background from an AI-generated character/monster
sheet, despill edges, and crop to content.

Usage: python3 game/tools/art/chroma_key.py in.png out.png
"""
import sys
import numpy as np
from PIL import Image

def main() -> None:
    src = Image.open(sys.argv[1]).convert("RGBA")
    arr = np.asarray(src).astype(np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    mask = (g > 110) & (g > r * 1.18) & (g > b * 1.18)
    arr[:, :, 3] = np.where(mask, 0, 255)
    edge = (~mask) & (g > np.maximum(r, b) * 1.02)
    arr[:, :, 1] = np.where(edge, np.maximum(r, b), arr[:, :, 1])
    out = Image.fromarray(arr.clip(0, 255).astype(np.uint8))
    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    out.save(sys.argv[2])
    print("wrote", sys.argv[2], out.size)

if __name__ == "__main__":
    main()
