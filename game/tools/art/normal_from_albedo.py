#!/usr/bin/env python3
"""Generate a tangent-space normal map from an albedo texture (Sobel).

Usage: python3 game/tools/art/normal_from_albedo.py <albedo.png> [strength]
Output: <albedo>-n.png next to the input.
"""
import sys
import numpy as np
from PIL import Image

def main() -> None:
    path = sys.argv[1]
    strength = float(sys.argv[2]) if len(sys.argv) > 2 else 2.2
    arr = np.asarray(Image.open(path).convert("L"), dtype=np.float32) / 255.0
    gx = np.zeros_like(arr)
    gy = np.zeros_like(arr)
    gx[:, 1:-1] = (arr[:, 2:] - arr[:, :-2]) * 0.5
    gy[1:-1, :] = (arr[2:, :] - arr[:-2, :]) * 0.5
    nx = -gx * strength
    ny = gy * strength
    nz = np.ones_like(arr)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack([nx / length * 0.5 + 0.5, ny / length * 0.5 + 0.5, nz / length * 0.5 + 0.5], axis=-1)
    out = path.replace(".png", "-n.png")
    Image.fromarray((rgb * 255.0).clip(0, 255).astype(np.uint8)).save(out)
    print("wrote", out)

if __name__ == "__main__":
    main()
