#!/usr/bin/env python3
"""Generate three art-direction concept boards for the same Folded Dungeon combat scene."""

W, H = 1200, 760
TILE, N = 64, 9
GX, GY = 420, 88
SIDEBAR_W, TOP_H, BOT_Y = 252, 52, 700
RIGHT_X, RIGHT_W = 1012, 176
GRID_W = TILE * N

# scene facts (same in all three concepts)
PLAYER = (5, 3)
ENEMIES = [(2, 5), (3, 6)]
FURNACE = (1, 1)
TOXIC = [(1, 4), (1, 5), (1, 6), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5)]
CRATES = [(6, 6), (7, 6), (7, 2)]
DOORS = {(0, 4), (4, 0), (4, 8), (8, 4)}
WALLS = {(r, c) for r in range(N) for c in range(N)
         if r in (0, N - 1) or c in (0, N - 1)} - DOORS

MINIMAP = {(2, 2): "cur", (1, 2): "room", (2, 1): "room", (3, 2): "room",
           (2, 3): "room", (1, 1): "room", (1, 3): "empty"}

def cx(c): return GX + c * TILE
def cy(r): return GY + r * TILE

def esc(s): return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def svg_head(style, desc, extra_defs=""):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-labelledby="t d">
<title id="t">折叠地牢战斗界面概念图 — {style}</title>
<desc id="d">{esc(desc)}</desc>
<defs>
{extra_defs}
</defs>
'''

def star_field(seed=7):
    # tiny deterministic speckles for dark backgrounds
    out = []
    x = seed * 37
    for i in range(70):
        x = (x * 1103515245 + 12345) % (2 ** 31)
        sx = x % W
        x = (x * 1103515245 + 12345) % (2 ** 31)
        sy = x % H
        x = (x * 1103515245 + 12345) % (2 ** 31)
        r = 0.6 + (x % 3) * 0.4
        out.append(f'<circle cx="{sx}" cy="{sy}" r="{r}" fill="#ffffff" opacity="0.05"/>')
    return "".join(out)

# ---------------------------------------------------------------- style A: pixel dungeon
def style_pixel():
    bg = "#07070c"; panel = "#10101a"; panel2 = "#151522"; line = "#2b2b40"
    wall_top = "#3c3c52"; wall_face = "#212130"; floor1 = "#262634"; floor2 = "#2b2b3b"
    grout = "#1b1b26"; ink = "#0a0a10"
    gold = "#e8c15a"; heat = "#ff8a3d"; toxic = "#7bdc5a"; player_c = "#89b4fa"
    enemy_c = "#e05555"; text = "#e6e6f0"; muted = "#8f8fa8"

    defs = f'''<radialGradient id="pixelHeatGlow"><stop offset="0" stop-color="{heat}" stop-opacity="0.55"/><stop offset="1" stop-color="{heat}" stop-opacity="0"/></radialGradient>
<radialGradient id="pixelVig"><stop offset="0.62" stop-color="#000000" stop-opacity="0"/><stop offset="1" stop-color="#000000" stop-opacity="0.55"/></radialGradient>
<radialGradient id="pixelDoorGlow"><stop offset="0" stop-color="#e8c15a" stop-opacity="0.38"/><stop offset="1" stop-color="#e8c15a" stop-opacity="0"/></radialGradient>
<pattern id="pixelDither" width="8" height="8" patternUnits="userSpaceOnUse"><rect width="8" height="8" fill="none"/><rect x="0" y="0" width="4" height="4" fill="{toxic}" opacity="0.16"/></pattern>'''
    s = [svg_head("像素地牢", "16 像素网格、石砖地牢、火把与绿色毒雾，像素小人站在 9x9 房间中央。", defs)]
    s.append(f'<rect width="{W}" height="{H}" fill="{bg}"/>')
    s.append(star_field())
    # vignette
    s.append(f'<rect width="{W}" height="{H}" fill="url(#pixelVig)"/>')

    # ---- floor / walls
    for r in range(N):
        for c in range(N):
            x, y = cx(c), cy(r)
            if (r, c) in WALLS:
                s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="{wall_face}"/>')
                s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="12" fill="{wall_top}"/>')
                s.append(f'<rect x="{x}" y="{y+12}" width="{TILE}" height="2" fill="{ink}" opacity="0.7"/>')
                # brick seams
                off = 16 if r % 2 == 0 else 0
                for sx in (off, off + 32):
                    if 0 <= sx < TILE:
                        s.append(f'<rect x="{x+sx}" y="{y+14}" width="2" height="{TILE-14}" fill="{ink}" opacity="0.45"/>')
                s.append(f'<rect x="{x}" y="{y+TILE-4}" width="{TILE}" height="4" fill="#000000" opacity="0.35"/>')
            else:
                base = floor1 if (r + c) % 2 == 0 else floor2
                s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="{base}"/>')
                s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="none" stroke="{grout}" stroke-width="2" opacity="0.8"/>')
                # small cracks
                if (r * 7 + c * 3) % 5 == 0:
                    s.append(f'<rect x="{x+18}" y="{y+30}" width="12" height="2" fill="{ink}" opacity="0.5"/>')
                    s.append(f'<rect x="{x+30}" y="{y+32}" width="2" height="8" fill="{ink}" opacity="0.5"/>')

    # ---- toxic fog
    for (r, c) in TOXIC:
        x, y = cx(c), cy(r)
        s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="url(#pixelDither)"/>')
        s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="{toxic}" opacity="0.07"/>')
    for (r, c) in [(2, 5), (3, 4), (1, 6), (2, 4)]:
        x, y = cx(c) + 22, cy(r) + 40
        s.append(f'<circle cx="{x}" cy="{y}" r="6" fill="none" stroke="{toxic}" stroke-width="2" opacity="0.5"/>')
        s.append(f'<circle cx="{x+16}" cy="{y-14}" r="3" fill="{toxic}" opacity="0.45"/>')

    # ---- crates
    for (r, c) in CRATES:
        x, y = cx(c) + 10, cy(r) + 12
        s.append(f'<rect x="{x}" y="{y}" width="44" height="40" fill="#6b4a2b"/>')
        s.append(f'<rect x="{x}" y="{y}" width="44" height="8" fill="#8a6136"/>')
        s.append(f'<rect x="{x}" y="{y}" width="44" height="40" fill="none" stroke="#3a2614" stroke-width="3"/>')
        s.append(f'<rect x="{x+20}" y="{y+8}" width="4" height="32" fill="#3a2614"/>')

    # ---- doors: lit stone opening with wooden frame and a floor glow
    for (r, c) in DOORS:
        x, y = cx(c), cy(r)
        s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="{floor1}"/>')
        s.append(f'<circle cx="{x+32}" cy="{y+32}" r="34" fill="url(#pixelDoorGlow)"/>')
        if c == 0 or c == N - 1:
            ox = x + (10 if c == 0 else 22)
            s.append(f'<rect x="{ox}" y="{y+10}" width="32" height="44" fill="#07070c"/>')
            s.append(f'<rect x="{ox}" y="{y+10}" width="32" height="8" fill="#0d0d14"/>')
            s.append(f'<rect x="{ox-6}" y="{y+6}" width="6" height="52" fill="#8a5a2b"/>')
            s.append(f'<rect x="{ox+32}" y="{y+6}" width="6" height="52" fill="#8a5a2b"/>')
            s.append(f'<rect x="{ox-8}" y="{y+4}" width="48" height="6" fill="#a06c34"/>')
            for i in range(3):
                s.append(f'<rect x="{ox+4}" y="{y+18+i*12}" width="24" height="3" fill="#5c3a1c"/>')
        else:
            oy = y + (10 if r == 0 else 22)
            s.append(f'<rect x="{x+10}" y="{oy}" width="44" height="32" fill="#07070c"/>')
            s.append(f'<rect x="{x+10}" y="{oy}" width="44" height="8" fill="#0d0d14"/>')
            s.append(f'<rect x="{x+6}" y="{oy-6}" width="52" height="6" fill="#8a5a2b"/>')
            s.append(f'<rect x="{x+6}" y="{oy+32}" width="52" height="6" fill="#8a5a2b"/>')
            s.append(f'<rect x="{x+4}" y="{oy-8}" width="6" height="48" fill="#a06c34"/>')
            for i in range(3):
                s.append(f'<rect x="{x+18+i*12}" y="{oy+4}" width="3" height="24" fill="#5c3a1c"/>')
        s.append(f'<rect x="{x+30}" y="{y+30}" width="4" height="4" fill="{gold}"/>')

    # ---- torches on walls
    for (r, c) in [(0, 2), (2, 0), (2, 8), (8, 6)]:
        tx, ty = cx(c) + TILE / 2, cy(r) + TILE / 2
        s.append(f'<circle cx="{tx}" cy="{ty}" r="66" fill="url(#pixelHeatGlow)" opacity="0.5"/>')
        s.append(f'<rect x="{tx-3}" y="{ty-2}" width="6" height="18" fill="#5c3a1c"/>')
        s.append(f'<rect x="{tx-6}" y="{ty-14}" width="12" height="12" fill="#ffb347"/>')
        s.append(f'<rect x="{tx-3}" y="{ty-18}" width="6" height="6" fill="#ffe08a"/>')

    # ---- furnace
    fr, fc = FURNACE
    fx, fy = cx(fc) + 32, cy(fr) + 32
    s.append(f'<circle cx="{fx}" cy="{fy}" r="120" fill="url(#pixelHeatGlow)" opacity="0.55"/>')
    s.append(f'<rect x="{fx-24}" y="{fy+2}" width="48" height="20" fill="#4a4a62"/>')
    s.append(f'<rect x="{fx-24}" y="{fy+2}" width="48" height="5" fill="#6a6a8a"/>')
    s.append(f'<rect x="{fx-12}" y="{fy-16}" width="24" height="20" fill="#ffb347"/>')
    s.append(f'<rect x="{fx-8}" y="{fy-24}" width="16" height="12" fill="#ffe08a"/>')
    s.append(f'<rect x="{fx-4}" y="{fy-30}" width="8" height="8" fill="#fff4c2"/>')

    # ---- units
    pr, pc = PLAYER
    px, py = cx(pc), cy(pr)
    s.append(f'<ellipse cx="{px+32}" cy="{py+54}" rx="20" ry="6" fill="#000000" opacity="0.5"/>')
    s.append(f'<rect x="{px+22}" y="{py+42}" width="8" height="10" fill="#2f4a6e"/><rect x="{px+34}" y="{py+42}" width="8" height="10" fill="#2f4a6e"/>')
    s.append(f'<rect x="{px+18}" y="{py+22}" width="28" height="22" fill="{player_c}"/>')
    s.append(f'<rect x="{px+18}" y="{py+22}" width="28" height="4" fill="#a8d4ff"/>')
    s.append(f'<rect x="{px+18}" y="{py+36}" width="28" height="4" fill="#4a7dc4"/>')
    s.append(f'<rect x="{px+14}" y="{py+24}" width="6" height="12" fill="#4a7dc4"/><rect x="{px+44}" y="{py+24}" width="6" height="12" fill="#4a7dc4"/>')
    s.append(f'<rect x="{px+23}" y="{py+8}" width="18" height="14" fill="#72d4ff"/>')
    s.append(f'<rect x="{px+26}" y="{py+13}" width="12" height="4" fill="#0b0b10"/>')
    # sword
    s.append(f'<rect x="{px+48}" y="{py+10}" width="4" height="30" fill="#cfd8e6"/>')
    s.append(f'<rect x="{px+44}" y="{py+38}" width="12" height="4" fill="{gold}"/>')
    # channel marker on player tile
    s.append(f'<rect x="{px}" y="{py}" width="{TILE}" height="{TILE}" fill="none" stroke="{player_c}" stroke-width="2" opacity="0.45"/>')

    for i, (er, ec) in enumerate(ENEMIES):
        ex, ey = cx(ec), cy(er)
        s.append(f'<ellipse cx="{ex+32}" cy="{ey+54}" rx="20" ry="6" fill="#000000" opacity="0.5"/>')
        s.append(f'<rect x="{ex+14}" y="{ey+22}" width="36" height="28" fill="{enemy_c}"/>')
        s.append(f'<rect x="{ex+14}" y="{ey+22}" width="36" height="5" fill="#ff8a8a"/>')
        s.append(f'<rect x="{ex+10}" y="{ey+16}" width="8" height="10" fill="#a83a3a"/><rect x="{ex+46}" y="{ey+16}" width="8" height="10" fill="#a83a3a"/>')
        s.append(f'<rect x="{ex+20}" y="{ey+30}" width="8" height="6" fill="#fff3e0"/><rect x="{ex+36}" y="{ey+30}" width="8" height="6" fill="#fff3e0"/>')
        s.append(f'<rect x="{ex+20}" y="{ey+31}" width="4" height="4" fill="#0b0b10"/><rect x="{ex+36}" y="{ey+31}" width="4" height="4" fill="#0b0b10"/>')
        s.append(f'<rect x="{ex+14}" y="{ey}" width="{TILE}" height="{TILE}" fill="none" stroke="{enemy_c}" stroke-width="2" opacity="0.4"/>')

    # floating damage
    s.append(f'<text x="{cx(6)+40}" y="{cy(3)+16}" font-family="ui-monospace, Menlo, monospace" font-size="22" font-weight="700" fill="#ffd93d" stroke="#0b0b10" stroke-width="4" paint-order="stroke">-2</text>')

    # ---- HUD top
    s.append(f'<rect width="{W}" height="{TOP_H}" fill="{panel}"/><rect y="{TOP_H-2}" width="{W}" height="2" fill="{line}"/>')
    s.append(f'<text x="20" y="33" font-family="ui-monospace, Menlo, monospace" font-size="17" letter-spacing="2" fill="{gold}">◆ 折叠地牢</text>')
    s.append(f'<text x="150" y="33" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="2" fill="{muted}">FOLDED DUNGEON</text>')
    for i, (label, active) in enumerate([("构筑", False), ("探索", False), ("战斗", True)]):
        bx = 480 + i * 96
        if active:
            s.append(f'<rect x="{bx}" y="12" width="76" height="30" fill="{gold}" opacity="0.16" stroke="{gold}" stroke-width="1"/>')
            s.append(f'<text x="{bx+38}" y="33" text-anchor="middle" font-family="-apple-system, PingFang SC, sans-serif" font-size="16" font-weight="700" fill="{gold}">{label}</text>')
        else:
            s.append(f'<text x="{bx+38}" y="33" text-anchor="middle" font-family="-apple-system, PingFang SC, sans-serif" font-size="16" fill="{muted}">{label}</text>')
    s.append(f'<text x="{W-20}" y="33" text-anchor="end" font-family="ui-monospace, Menlo, monospace" font-size="14" letter-spacing="1" fill="{text}">GOLD 15   BP 9   HP 16/16</text>')

    # ---- sidebar
    s.append(f'<rect width="{SIDEBAR_W}" height="{H-TOP_H}" y="{TOP_H}" fill="#0d0d16"/>')
    s.append(f'<rect x="{SIDEBAR_W-2}" y="{TOP_H}" width="2" height="{H-TOP_H}" fill="{line}"/>')
    s.append(f'<text x="20" y="{TOP_H+34}" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="3" fill="{muted}">RUN · FLOOR 1/1</text>')
    mx, my, cell, gap = 20, 100, 40, 4
    for r in range(5):
        for c in range(5):
            key = (r, c)
            x, y = mx + c * (cell + gap), my + r * (cell + gap)
            kind = MINIMAP.get(key)
            if kind == "cur":
                s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="{player_c}"/>')
                s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="none" stroke="{gold}" stroke-width="2"/>')
            elif kind == "room":
                s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="#2a2a3c"/>')
                s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="none" stroke="#44445e" stroke-width="1"/>')
            else:
                s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="#141420"/>')
                s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="none" stroke="#252536" stroke-width="1"/>')
    # minimap doors
    for (x1, y1, x2, y2) in [(40, 160, 40, 160)]:
        pass
    s.append(f'<text x="20" y="352" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="2" fill="{muted}">GOLD</text>')
    s.append(f'<text x="20" y="378" font-family="ui-monospace, Menlo, monospace" font-size="20" fill="{gold}">15</text>')
    s.append(f'<text x="96" y="352" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="2" fill="{muted}">BP</text>')
    s.append(f'<text x="96" y="378" font-family="ui-monospace, Menlo, monospace" font-size="20" fill="{text}">9</text>')
    s.append(f'<text x="170" y="352" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="2" fill="{muted}">ROUND</text>')
    s.append(f'<text x="170" y="378" font-family="ui-monospace, Menlo, monospace" font-size="20" fill="{text}">2</text>')
    s.append(f'<rect x="20" y="408" width="212" height="2" fill="{line}"/>')
    s.append(f'<text x="20" y="442" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="2" fill="{muted}">CHANNELS</text>')
    for i, (name, val, col) in enumerate([("TOXIN", 0.20, toxic), ("HEAT", 0.60, heat), ("COLD", 0.0, "#6cc7ff"), ("CHARGE", 0.0, "#ffd93d")]):
        y = 464 + i * 46
        s.append(f'<text x="20" y="{y}" font-family="ui-monospace, Menlo, monospace" font-size="13" fill="{text}">{name}</text>')
        s.append(f'<rect x="88" y="{y-12}" width="120" height="12" fill="#1c1c2a" stroke="#33334a" stroke-width="1"/>')
        if val > 0:
            s.append(f'<rect x="89" y="{y-11}" width="{118*val:.0f}" height="10" fill="{col}"/>')
    s.append(f'<rect x="20" y="664" width="212" height="2" fill="{line}"/>')
    s.append(f'<text x="20" y="694" font-family="ui-monospace, Menlo, monospace" font-size="12" fill="{muted}">WASD 移动 · SPACE 攻击</text>')

    # ---- right panel
    s.append(f'<rect x="{RIGHT_X}" y="{GY}" width="{RIGHT_W}" height="{GRID_W}" fill="#0d0d16" stroke="{line}" stroke-width="2"/>')
    s.append(f'<text x="{RIGHT_X+16}" y="{GY+30}" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="2" fill="{muted}">UNITS</text>')
    units = [("玩家", "16/16", player_c), ("怪物 A", "4/4", enemy_c), ("怪物 B", "4/4", enemy_c)]
    for i, (name, hp, col) in enumerate(units):
        y = GY + 58 + i * 54
        s.append(f'<rect x="{RIGHT_X+16}" y="{y-16}" width="10" height="10" fill="{col}"/>')
        s.append(f'<text x="{RIGHT_X+34}" y="{y-6}" font-family="-apple-system, PingFang SC, sans-serif" font-size="15" fill="{text}">{name}</text>')
        s.append(f'<text x="{RIGHT_X+160}" y="{y-6}" text-anchor="end" font-family="ui-monospace, Menlo, monospace" font-size="14" fill="{col}">{hp}</text>')
    s.append(f'<rect x="{RIGHT_X+16}" y="{GY+236}" width="{RIGHT_W-32}" height="2" fill="{line}"/>')
    s.append(f'<text x="{RIGHT_X+16}" y="{GY+268}" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="2" fill="{muted}">HAZARD</text>')
    s.append(f'<text x="{RIGHT_X+16}" y="{GY+296}" font-family="-apple-system, PingFang SC, sans-serif" font-size="15" fill="{toxic}">毒雾 200</text>')
    s.append(f'<text x="{RIGHT_X+16}" y="{GY+322}" font-family="-apple-system, PingFang SC, sans-serif" font-size="15" fill="{heat}">热量 600</text>')
    s.append(f'<text x="{RIGHT_X+16}" y="{GY+370}" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="2" fill="{muted}">INTENT</text>')
    s.append(f'<text x="{RIGHT_X+16}" y="{GY+396}" font-family="-apple-system, PingFang SC, sans-serif" font-size="14" fill="{text}">怪物向玩家靠近</text>')

    # ---- bottom bar
    s.append(f'<rect y="{BOT_Y}" width="{W}" height="{H-BOT_Y}" fill="{panel}"/><rect y="{BOT_Y}" width="{W}" height="2" fill="{line}"/>')
    hints = [("WASD", "移动"), ("SPACE", "攻击"), ("ENTER", "结束回合"), ("ESC", "菜单")]
    x = 20
    for key, label in hints:
        kw = 8 + len(key) * 9
        s.append(f'<rect x="{x}" y="{BOT_Y+16}" width="{kw}" height="26" rx="3" fill="#222234" stroke="#44445e"/>')
        s.append(f'<text x="{x+kw/2}" y="{BOT_Y+34}" text-anchor="middle" font-family="ui-monospace, Menlo, monospace" font-size="12" fill="{text}">{key}</text>')
        s.append(f'<text x="{x+kw+10}" y="{BOT_Y+34}" font-family="-apple-system, PingFang SC, sans-serif" font-size="14" fill="{muted}">{label}</text>')
        x += kw + 24 + len(label) * 14
    s.append(f'<text x="{W-20}" y="{BOT_Y+34}" text-anchor="end" font-family="ui-monospace, Menlo, monospace" font-size="12" fill="{muted}">SCENE: 9×9 ROOM · 5×5 MACRO GRID</text>')
    s.append('</svg>')
    return "".join(s)

# ---------------------------------------------------------------- style B: tactical minimal
def style_tactical():
    bg = "#0b1118"; floor = "#121c26"; line = "#1e2d3c"; wall = "#0a1219"
    accent = "#58d6e8"; player_c = "#58d6e8"; enemy_c = "#ff6b6b"; text = "#e8eef4"
    muted = "#7c8fa3"; toxic = "#9ae66e"; heat = "#ffa94d"; gold = "#e8c15a"

    defs = f'''<pattern id="tacHatch" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="10" height="10" fill="none"/><rect width="4" height="10" fill="{heat}" opacity="0.18"/></pattern>
<radialGradient id="tacVig"><stop offset="0.6" stop-color="#000000" stop-opacity="0"/><stop offset="1" stop-color="#000000" stop-opacity="0.5"/></radialGradient>'''
    s = [svg_head("战术极简", "低饱和暗色、细网格、几何单位与斜线危险区，接近 Into the Breach 的战术可读性。", defs)]
    s.append(f'<rect width="{W}" height="{H}" fill="{bg}"/>')
    s.append(star_field(13))
    # room frame: dark band + lit edge
    rx, ry = GX - 12, GY - 12
    rw, rh = GRID_W + 24, GRID_W + 24
    s.append(f'<rect x="{rx-8}" y="{ry-8}" width="{rw+16}" height="{rh+16}" fill="#0d161e" stroke="#20313f" stroke-width="1"/>')
    s.append(f'<rect x="{rx}" y="{ry}" width="{rw}" height="{rh}" fill="{floor}" stroke="#2a4054" stroke-width="2"/>')
    for (tx, ty, sx, sy) in [(rx, ry, 1, 1), (rx+rw, ry, -1, 1), (rx, ry+rh, 1, -1), (rx+rw, ry+rh, -1, -1)]:
        s.append(f'<path d="M{tx} {ty+sy*16}V{ty}H{tx+sx*16}" fill="none" stroke="{accent}" stroke-width="2" opacity="0.55"/>')
    for r in range(N):
        for c in range(N):
            x, y = cx(c), cy(r)
            s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="none" stroke="{line}" stroke-width="1"/>')
    # toxic zone
    for (r, c) in TOXIC:
        x, y = cx(c), cy(r)
        s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="{toxic}" opacity="0.10"/>')
        if (r + c) % 2 == 0:
            s.append(f'<circle cx="{x+32}" cy="{y+32}" r="5" fill="none" stroke="{toxic}" stroke-width="1.5" opacity="0.55"/>')
    s.append(f'<text x="{cx(6)-4}" y="{cy(1)+10}" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="1" fill="{toxic}" opacity="0.85">TOXIN 200</text>')
    # furnace hazard tile
    fr, fc = FURNACE
    x, y = cx(fc), cy(fr)
    s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="url(#tacHatch)"/>')
    s.append(f'<rect x="{x+20}" y="{y+20}" width="24" height="24" fill="none" stroke="{heat}" stroke-width="2"/>')
    s.append(f'<text x="{x+50}" y="{y+18}" font-family="ui-monospace, Menlo, monospace" font-size="13" fill="{heat}">600</text>')
    # walls: thick band with inner outline
    for (r, c) in WALLS:
        x, y = cx(c), cy(r)
        s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="{wall}"/>')
        s.append(f'<rect x="{x+2}" y="{y+2}" width="{TILE-4}" height="{TILE-4}" fill="none" stroke="#1b2a38" stroke-width="1"/>')
    # doors: chevrons
    for (r, c) in DOORS:
        x, y = cx(c), cy(r)
        s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="{floor}"/>')
        s.append(f'<rect x="{x}" y="{y}" width="{TILE}" height="{TILE}" fill="{accent}" opacity="0.08"/>')
        if c == 0:
            s.append(f'<path d="M{x+44} {y+18}L{x+28} {y+32}L{x+44} {y+46}" fill="none" stroke="{accent}" stroke-width="3"/>')
        elif c == N - 1:
            s.append(f'<path d="M{x+20} {y+18}L{x+36} {y+32}L{x+20} {y+46}" fill="none" stroke="{accent}" stroke-width="3"/>')
        elif r == 0:
            s.append(f'<path d="M{x+18} {y+44}L{x+32} {y+28}L{x+46} {y+44}" fill="none" stroke="{accent}" stroke-width="3"/>')
        else:
            s.append(f'<path d="M{x+18} {y+20}L{x+32} {y+36}L{x+46} {y+20}" fill="none" stroke="{accent}" stroke-width="3"/>')
    # crates as small outlined squares
    for (r, c) in CRATES:
        x, y = cx(c) + 16, cy(r) + 16
        s.append(f'<rect x="{x}" y="{y}" width="32" height="32" fill="none" stroke="#33475a" stroke-width="2"/>')
        s.append(f'<path d="M{x} {y}L{x+32} {y+32}M{x+32} {y}L{x} {y+32}" stroke="#33475a" stroke-width="1"/>')
    # player
    pr, pc = PLAYER
    s.append(f'<path d="M{cx(pc)+32} {cy(pr)+20}L{cx(pc)+50} {cy(pr)+52}L{cx(pc)+14} {cy(pr)+52}Z" fill="{player_c}" opacity="0.25"/>')
    s.append(f'<rect x="{cx(pc)+14}" y="{cy(pr)+14}" width="36" height="36" fill="{player_c}" fill-opacity="0.16" stroke="{player_c}" stroke-width="2.5"/>')
    s.append(f'<circle cx="{cx(pc)+32}" cy="{cy(pr)+32}" r="8" fill="{player_c}"/>')
    s.append(f'<path d="M{cx(pc)+32} {cy(pr)+12}L{cx(pc)+38} {cy(pr)+22}L{cx(pc)+26} {cy(pr)+22}Z" fill="{player_c}"/>')
    s.append(f'<text x="{cx(pc)+32}" y="{cy(pr)+58}" text-anchor="middle" font-family="ui-monospace, Menlo, monospace" font-size="11" fill="{player_c}">YOU</text>')
    for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        rr, cc = pr + dr, pc + dc
        if 0 <= rr < N and 0 <= cc < N and (rr, cc) not in WALLS and (rr, cc) not in DOORS:
            s.append(f'<rect x="{cx(cc)+12}" y="{cy(rr)+12}" width="{TILE-24}" height="{TILE-24}" fill="none" stroke="{accent}" stroke-width="1.5" stroke-dasharray="3 5" opacity="0.32"/>')
    # enemies
    for i, (er, ec) in enumerate(ENEMIES):
        ex, ey = cx(ec), cy(er)
        s.append(f'<path d="M{ex+32} {ey+18}L{ex+48} {ey+46}L{ex+16} {ey+46}Z" fill="{enemy_c}" fill-opacity="0.18" stroke="{enemy_c}" stroke-width="2.5"/>')
        s.append(f'<circle cx="{ex+32}" cy="{ey+36}" r="4" fill="{enemy_c}"/>')
        s.append(f'<text x="{ex+32}" y="{ey+58}" text-anchor="middle" font-family="ui-monospace, Menlo, monospace" font-size="11" fill="{enemy_c}">HP 4</text>')
        # intent arrow toward player (dashed path + arrowhead)
        s.append(f'<path d="M{ex+32} {ey+48}Q{ex+10} {ey+72} {ex-2} {ey+94}" fill="none" stroke="{enemy_c}" stroke-width="1.5" stroke-dasharray="4 4" opacity="0.6"/>')
        s.append(f'<path d="M{ex-2} {ey+94}l-1 -9M{ex-2} {ey+94}l-9 -2" stroke="{enemy_c}" stroke-width="1.5" opacity="0.7" fill="none"/>')
    # damage flash marker
    s.append(f'<rect x="{cx(6)}" y="{cy(3)}" width="{TILE}" height="{TILE}" fill="{heat}" opacity="0.14"/>')
    s.append(f'<text x="{cx(6)+44}" y="{cy(3)+22}" font-family="ui-monospace, Menlo, monospace" font-size="18" font-weight="700" fill="{heat}">-2</text>')

    # top bar
    s.append(f'<rect width="{W}" height="{TOP_H}" fill="#0b1118"/><rect y="{TOP_H-2}" width="{W}" height="1" fill="{line}"/>')
    s.append(f'<text x="24" y="33" font-family="ui-monospace, Menlo, monospace" font-size="15" letter-spacing="4" fill="{text}">FOLDED DUNGEON</text>')
    s.append(f'<text x="250" y="33" font-family="-apple-system, PingFang SC, sans-serif" font-size="14" fill="{muted}">折叠地牢 · 战术原型</text>')
    for i, (label, active) in enumerate([("构筑", False), ("探索", False), ("战斗", True)]):
        bx = 560 + i * 72
        if active:
            s.append(f'<rect x="{bx}" y="14" width="56" height="26" fill="{accent}" fill-opacity="0.10" stroke="{accent}" stroke-width="1"/>')
            s.append(f'<text x="{bx+26}" y="32" text-anchor="middle" font-family="-apple-system, PingFang SC, sans-serif" font-size="14" font-weight="700" fill="{accent}">{label}</text>')
        else:
            s.append(f'<text x="{bx+26}" y="32" text-anchor="middle" font-family="-apple-system, PingFang SC, sans-serif" font-size="14" fill="{muted}">{label}</text>')
    s.append(f'<text x="{W-24}" y="33" text-anchor="end" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="2" fill="{text}">GOLD 15   BP 9   HP 16/16</text>')

    # sidebar
    s.append(f'<rect width="{SIDEBAR_W}" height="{H-TOP_H}" y="{TOP_H}" fill="#0a0f15"/>')
    s.append(f'<rect x="{SIDEBAR_W-1}" y="{TOP_H}" width="1" height="{H-TOP_H}" fill="{line}"/>')
    s.append(f'<text x="20" y="{TOP_H+34}" font-family="ui-monospace, Menlo, monospace" font-size="12" letter-spacing="3" fill="{muted}">MACRO GRID</text>')
    mx, my, cell, gap = 20, 100, 40, 6
    for r in range(5):
        for c in range(5):
            x, y = mx + c * (cell + gap), my + r * (cell + gap)
            kind = MINIMAP.get((r, c))
            fill = "#131e28"
            stroke = "#26394b"
            if kind == "room":
                fill, stroke = "#1b2c3b", "#38566e"
            if kind == "cur":
                fill, stroke = "#1d3a45", accent
            s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="{fill}" stroke="{stroke}" stroke-width="{2.5 if kind=="cur" else 1}"/>')
            if kind == "cur":
                s.append(f'<circle cx="{x+cell/2}" cy="{y+cell/2}" r="5" fill="{accent}"/>')
    s.append(f'<text x="20" y="382" font-family="ui-monospace, Menlo, monospace" font-size="12" letter-spacing="2" fill="{muted}">TURN</text>')
    s.append(f'<text x="20" y="410" font-family="ui-monospace, Menlo, monospace" font-size="26" fill="{text}">02</text>')
    s.append(f'<text x="120" y="382" font-family="ui-monospace, Menlo, monospace" font-size="12" letter-spacing="2" fill="{muted}">KILLS</text>')
    s.append(f'<text x="120" y="410" font-family="ui-monospace, Menlo, monospace" font-size="26" fill="{text}">01</text>')
    s.append(f'<rect x="20" y="440" width="212" height="1" fill="{line}"/>')
    s.append(f'<text x="20" y="474" font-family="ui-monospace, Menlo, monospace" font-size="12" letter-spacing="3" fill="{muted}">CHANNELS</text>')
    for i, (name, val, col) in enumerate([("TOXIN", 0.20, toxic), ("HEAT", 0.60, heat), ("COLD", 0.0, "#6cc7ff"), ("CHARGE", 0.0, "#ffd93d")]):
        y = 500 + i * 44
        s.append(f'<text x="20" y="{y}" font-family="ui-monospace, Menlo, monospace" font-size="12" fill="{muted}">{name}</text>')
        s.append(f'<rect x="96" y="{y-11}" width="112" height="6" fill="#16222d"/>')
        if val > 0:
            s.append(f'<rect x="96" y="{y-11}" width="{112*val:.0f}" height="6" fill="{col}"/>')
        s.append(f'<text x="232" y="{y}" text-anchor="end" font-family="ui-monospace, Menlo, monospace" font-size="11" fill="{text}">{int(val*1000)}</text>')
    s.append(f'<text x="20" y="{H-24}" font-family="ui-monospace, Menlo, monospace" font-size="11" fill="#3c5367">SEED 20261030</text>')

    # right panel
    s.append(f'<rect x="{RIGHT_X}" y="{GY-12}" width="{RIGHT_W}" height="{GRID_W+24}" fill="#0a0f15" stroke="{line}" stroke-width="1"/>')
    s.append(f'<text x="{RIGHT_X+14}" y="{GY+22}" font-family="ui-monospace, Menlo, monospace" font-size="11" letter-spacing="3" fill="{muted}">INTENT</text>')
    intents = [("怪物 A", "靠近 · 攻击", enemy_c), ("怪物 B", "靠近 · 攻击", enemy_c)]
    for i, (name, desc, col) in enumerate(intents):
        y = GY + 52 + i * 44
        s.append(f'<text x="{RIGHT_X+14}" y="{y}" font-family="-apple-system, PingFang SC, sans-serif" font-size="13" fill="{text}">{name}</text>')
        s.append(f'<text x="{RIGHT_X+14}" y="{y+18}" font-family="-apple-system, PingFang SC, sans-serif" font-size="12" fill="{muted}">{desc}</text>')
    s.append(f'<rect x="{RIGHT_X+14}" y="{GY+160}" width="{RIGHT_W-28}" height="1" fill="{line}"/>')
    s.append(f'<text x="{RIGHT_X+14}" y="{GY+192}" font-family="ui-monospace, Menlo, monospace" font-size="11" letter-spacing="2" fill="{muted}">NEXT</text>')
    s.append(f'<text x="{RIGHT_X+14}" y="{GY+216}" font-family="-apple-system, PingFang SC, sans-serif" font-size="13" fill="{text}">回合结束触发环境结算</text>')

    # bottom bar
    s.append(f'<rect y="{BOT_Y}" width="{W}" height="{H-BOT_Y}" fill="#0b1118"/><rect y="{BOT_Y}" width="{W}" height="1" fill="{line}"/>')
    s.append(f'<text x="24" y="{BOT_Y+36}" font-family="ui-monospace, Menlo, monospace" font-size="13" letter-spacing="1" fill="{muted}">WASD 移动      SPACE 攻击      ENTER 结束回合      ESC 菜单</text>')
    s.append(f'<text x="{W-24}" y="{BOT_Y+36}" text-anchor="end" font-family="ui-monospace, Menlo, monospace" font-size="12" fill="#3c5367">DETERMINISTIC · 0 RNG IN UI</text>')
    s.append('</svg>')
    return "".join(s)

# ---------------------------------------------------------------- style C: inked silhouette / paper
def style_paper():
    paper = "#e7dcc4"; ink = "#2b2418"; warm = "#f2e9d6"; text = "#3a2f20"
    rust = "#b4552d"; teal = "#3fa8a0"; toxic = "#7d9b4e"; heat = "#d27b2e"

    defs = f'''<filter id="paperGrain"><feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="3" stitchTiles="stitch"/><feColorMatrix type="matrix" values="0 0 0 0 0.45  0 0 0 0 0.38  0 0 0 0 0.28  0 0 0 0.07 0"/></filter>
<radialGradient id="paperHeat"><stop offset="0" stop-color="{heat}" stop-opacity="0.5"/><stop offset="1" stop-color="{heat}" stop-opacity="0"/></radialGradient>
<radialGradient id="paperToxic"><stop offset="0" stop-color="{toxic}" stop-opacity="0.32"/><stop offset="1" stop-color="{toxic}" stop-opacity="0"/></radialGradient>
<radialGradient id="paperVig"><stop offset="0.55" stop-color="#000000" stop-opacity="0"/><stop offset="1" stop-color="#4a3826" stop-opacity="0.22"/></radialGradient>'''
    s = [svg_head("手绘剪影", "羊皮纸底、墨线房间与剪影角色，暖光火盆和绿色水彩毒雾，偏叙事插画风。", defs)]
    s.append(f'<rect width="{W}" height="{H}" fill="{paper}"/>')
    s.append(f'<rect width="{W}" height="{H}" fill="url(#paperVig)"/>')
    s.append(f'<path d="M0 210L330 0M870 {H}L{W} 520" stroke="#7a6448" stroke-width="1" opacity="0.10"/>')
    s.append(f'<path d="M0 640L210 {H}M980 0L{W} 180" stroke="#7a6448" stroke-width="1" opacity="0.07"/>')
    s.append(f'<rect width="{W}" height="{H}" filter="url(#paperGrain)" opacity="0.9"/>')

    # room paper
    rx, ry = GX - 16, GY - 16
    rw, rh = GRID_W + 32, GRID_W + 32
    s.append(f'<rect x="{rx}" y="{ry}" width="{rw}" height="{rh}" fill="{warm}" stroke="{ink}" stroke-width="4"/>')
    s.append(f'<rect x="{rx+6}" y="{ry+6}" width="{rw-12}" height="{rh-12}" fill="none" stroke="{ink}" stroke-width="1" opacity="0.35"/>')
    # pencil grid
    s.append(f'<g stroke="{ink}" stroke-width="1" opacity="0.10">')
    for i in range(1, N):
        s.append(f'<line x1="{GX+i*TILE}" y1="{GY}" x2="{GX+i*TILE}" y2="{GY+GRID_W}"/>')
        s.append(f'<line x1="{GX}" y1="{GY+i*TILE}" x2="{GX+GRID_W}" y2="{GY+i*TILE}"/>')
    s.append('</g>')
    # inked walls
    s.append(f'<g fill="none" stroke="{ink}" stroke-linecap="round">')
    s.append(f'<path d="M{rx+8} {ry+8}H{rx+rw-8}V{ry+rh-8}H{rx+8}Z" stroke-width="9"/>')
    for (r, c) in sorted(WALLS):
        x, y = cx(c), cy(r)
        s.append(f'<path d="M{x+4} {y+6}H{x+TILE-6}M{x+6} {y+4}V{y+TILE-6}" stroke-width="2" opacity="0.35"/>')
    s.append('</g>')
    # hatching inside walls
    for (r, c) in sorted(WALLS):
        x, y = cx(c), cy(r)
        s.append(f'<g stroke="{ink}" stroke-width="1.4" opacity="0.4">')
        s.append(f'<path d="M{x+8} {y+50}L{x+22} {y+36}M{x+18} {y+54}L{x+32} {y+40}M{x+30} {y+56}L{x+44} {y+42}M{x+42} {y+56}L{x+54} {y+44}"/>')
        s.append('</g>')
    # doors: ink arch with portcullis and warm light behind
    for (r, c) in DOORS:
        x, y = cx(c), cy(r)
        s.append(f'<rect x="{x+2}" y="{y+2}" width="{TILE-4}" height="{TILE-4}" fill="{paper}"/>')
        s.append(f'<circle cx="{x+32}" cy="{y+32}" r="46" fill="url(#paperHeat)" opacity="0.9"/>')
        if c == 0 or c == N - 1:
            s.append(f'<rect x="{x+22}" y="{y+10}" width="20" height="44" fill="{paper}" stroke="{ink}" stroke-width="2.5"/>')
            for i in range(4):
                s.append(f'<path d="M{x+22} {y+18+i*10}H{x+42}" stroke="{ink}" stroke-width="1.6" opacity="0.7"/>')
            s.append(f'<path d="M{x+18} {y+54}V{y+30}q14 -22 28 0V{y+54}" fill="none" stroke="{ink}" stroke-width="3"/>')
        else:
            s.append(f'<rect x="{x+10}" y="{y+22}" width="44" height="20" fill="{paper}" stroke="{ink}" stroke-width="2.5"/>')
            for i in range(4):
                s.append(f'<path d="M{x+18+i*10} {y+22}V{y+42}" stroke="{ink}" stroke-width="1.6" opacity="0.7"/>')
            s.append(f'<path d="M{x+8} {y+54}H{x+56}M{x+8} {y+54}V{y+30}q0 -18 18 -18" fill="none" stroke="{ink}" stroke-width="3"/>')
        s.append(f'<circle cx="{x+32}" cy="{y+32}" r="3" fill="{rust}" opacity="0.8"/>')
    # furnace
    fr, fc = FURNACE
    fx, fy = cx(fc) + 32, cy(fr) + 34
    s.append(f'<circle cx="{fx}" cy="{fy}" r="130" fill="url(#paperHeat)"/>')
    s.append(f'<path d="M{fx-22} {fy+22}H{fx+22}M{fx-18} {fy+22}V{fy+8}M{fx+18} {fy+22}V{fy+8}" stroke="{ink}" stroke-width="3" fill="none"/>')
    s.append(f'<path d="M{fx} {fy-26}C{fx-14} {fy-2},{fx-10} {fy+10},{fx} {fy+14}C{fx+10} {fy+10},{fx+14} {fy-2},{fx} {fy-26}Z" fill="{heat}" opacity="0.85"/>')
    s.append(f'<path d="M{fx+26} {fy-30}c10 -8, 16 -18, 8 -30M{fx+40} {fy-24}c12 -6, 20 -14, 14 -28" stroke="{ink}" stroke-width="1.5" fill="none" opacity="0.35"/>')
    # toxic watercolor
    for (r, c) in TOXIC:
        x, y = cx(c) + 32, cy(r) + 32
        s.append(f'<circle cx="{x}" cy="{y}" r="58" fill="url(#paperToxic)"/>')
    for (r, c) in [(2, 5), (3, 4), (1, 6)]:
        x, y = cx(c) + 30 + (c % 3) * 8, cy(r) + 34 - (r % 2) * 6
        s.append(f'<circle cx="{x}" cy="{y}" r="9" fill="{toxic}" opacity="0.28"/>')
        s.append(f'<circle cx="{x+18}" cy="{y-12}" r="5" fill="{toxic}" opacity="0.22"/>')
    # crates as ink boxes
    for (r, c) in CRATES:
        x, y = cx(c) + 14, cy(r) + 16
        s.append(f'<rect x="{x}" y="{y}" width="36" height="34" fill="none" stroke="{ink}" stroke-width="3"/>')
        s.append(f'<path d="M{x+4} {y+4}L{x+32} {y+30}M{x+32} {y+4}L{x+4} {y+30}" stroke="{ink}" stroke-width="1.6" opacity="0.5"/>')
    # player silhouette with teal rim
    pr, pc = PLAYER
    px, py = cx(pc), cy(pr)
    s.append(f'<ellipse cx="{px+32}" cy="{py+58}" rx="24" ry="7" fill="{ink}" opacity="0.22"/>')
    s.append(f'<path d="M{px+32} {py+10}C{px+42} {py+10},{px+46} {py+20},{px+45} {py+26}L{px+52} {py+56}H{px+12}L{px+19} {py+26}C{px+18} {py+18},{px+22} {py+10},{px+32} {py+10}Z" fill="{ink}"/>')
    s.append(f'<path d="M{px+19} {py+56}V{py+64}M{px+45} {py+56}V{py+64}" stroke="{ink}" stroke-width="6" stroke-linecap="round"/>')
    s.append(f'<path d="M{px+24} {py+20}C{px+20} {py+24},{px+20} {py+40},{px+21} {py+52}" stroke="{teal}" stroke-width="3" fill="none" opacity="0.9"/>')
    s.append(f'<path d="M{px+46} {py+30}L{px+60} {py+20}M{px+58} {py+18}L{px+62} {py+22}" stroke="{ink}" stroke-width="3" fill="none"/>')
    # enemies ink blobs
    for i, (er, ec) in enumerate(ENEMIES):
        ex, ey = cx(ec), cy(er)
        s.append(f'<ellipse cx="{ex+32}" cy="{ey+56}" rx="22" ry="7" fill="{ink}" opacity="0.2"/>')
        s.append(f'<path d="M{ex+12} {ey+52}C{ex+6} {ey+36},{ex+14} {ey+16},{ex+32} {ey+14}C{ex+50} {ey+16},{ex+58} {ey+36},{ex+52} {ey+52}Z" fill="{ink}"/>')
        s.append(f'<path d="M{ex+18} {ey+22}l6 -10 6 10M{ex+34} {ey+22}l6 -10 6 10" fill="{ink}"/>')
        s.append(f'<circle cx="{ex+25}" cy="{ey+32}" r="3" fill="{warm}"/><circle cx="{ex+39}" cy="{ey+32}" r="3" fill="{warm}"/>')
        s.append(f'<path d="M{ex+44} {ey+30}C{ex+50} {ey+34},{ex+50} {ey+44},{ex+44} {ey+50}" stroke="{rust}" stroke-width="2.5" fill="none" opacity="0.8"/>')
    # damage ink splatter
    s.append(f'<path d="M{cx(6)+34} {cy(3)+18}l14 10 -10 6 16 8" stroke="{rust}" stroke-width="3" fill="none" stroke-linecap="round"/>')
    s.append(f'<text x="{cx(6)+58}" y="{cy(3)+24}" font-family="Georgia, Songti SC, serif" font-size="20" font-weight="700" fill="{rust}">-2</text>')

    # top bar: paper with ink rule
    s.append(f'<rect width="{W}" height="{TOP_H}" fill="{paper}" opacity="0.92"/>')
    s.append(f'<path d="M0 {TOP_H-3}H{W}" stroke="{ink}" stroke-width="2" opacity="0.8"/>')
    s.append(f'<path d="M28 26l8 -8 8 8 -8 8z" fill="{rust}"/>')
    s.append(f'<text x="52" y="34" font-family="Georgia, Songti SC, serif" font-size="21" font-weight="700" fill="{ink}">折叠地牢</text>')
    s.append(f'<text x="160" y="33" font-family="Georgia, serif" font-size="13" letter-spacing="3" fill="{text}" opacity="0.7">FOLDED DUNGEON</text>')
    for i, (label, active) in enumerate([("构筑", False), ("探索", False), ("战斗", True)]):
        bx = 470 + i * 90
        if active:
            s.append(f'<path d="M{bx} {TOP_H-14}H{bx+58}" stroke="{rust}" stroke-width="3"/>')
            s.append(f'<text x="{bx+29}" y="33" text-anchor="middle" font-family="Georgia, Songti SC, serif" font-size="17" font-weight="700" fill="{rust}">{label}</text>')
        else:
            s.append(f'<text x="{bx+29}" y="33" text-anchor="middle" font-family="Georgia, Songti SC, serif" font-size="16" fill="{text}" opacity="0.6">{label}</text>')
    s.append(f'<text x="{W-22}" y="33" text-anchor="end" font-family="Georgia, serif" font-size="14" fill="{ink}">金币 15 · 构筑点 9 · 生命 16/16</text>')

    # sidebar paper
    s.append(f'<rect width="{SIDEBAR_W}" height="{H-TOP_H}" y="{TOP_H}" fill="{paper}" opacity="0.92"/>')
    s.append(f'<path d="M{SIDEBAR_W-2} {TOP_H}V{H}" stroke="{ink}" stroke-width="2" opacity="0.7"/>')
    s.append(f'<text x="20" y="{TOP_H+34}" font-family="Georgia, serif" font-size="12" letter-spacing="3" fill="{text}" opacity="0.65">RUN · FLOOR 1/1</text>')
    mx, my, cell, gap = 20, 100, 40, 4
    for r in range(5):
        for c in range(5):
            x, y = mx + c * (cell + gap), my + r * (cell + gap)
            kind = MINIMAP.get((r, c))
            if kind == "cur":
                s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="{teal}" opacity="0.22" stroke="{ink}" stroke-width="2"/>')
                s.append(f'<circle cx="{x+cell/2}" cy="{y+cell/2}" r="5" fill="{rust}"/>')
            elif kind == "room":
                s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="none" stroke="{ink}" stroke-width="1.6" opacity="0.75"/>')
            else:
                s.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" fill="none" stroke="{ink}" stroke-width="1" opacity="0.25"/>')
    s.append(f'<path d="M20 352H232" stroke="{ink}" stroke-width="1" opacity="0.4"/>')
    s.append(f'<text x="20" y="384" font-family="Georgia, Songti SC, serif" font-size="14" fill="{text}">金币 15</text>')
    s.append(f'<text x="130" y="384" font-family="Georgia, Songti SC, serif" font-size="14" fill="{text}">构筑点 9</text>')
    s.append(f'<text x="20" y="412" font-family="Georgia, Songti SC, serif" font-size="14" fill="{text}">回合 02 · 战斗</text>')
    s.append(f'<path d="M20 436H232" stroke="{ink}" stroke-width="1" opacity="0.4"/>')
    s.append(f'<text x="20" y="466" font-family="Georgia, serif" font-size="12" letter-spacing="2" fill="{text}" opacity="0.6">CHANNELS</text>')
    for i, (name, val, col) in enumerate([("毒雾", 0.20, toxic), ("热量", 0.60, heat), ("寒冷", 0.0, "#4a7fa8"), ("蓄能", 0.0, "#b08a2e")]):
        y = 492 + i * 40
        s.append(f'<text x="20" y="{y}" font-family="Georgia, Songti SC, serif" font-size="13" fill="{text}">{name}</text>')
        s.append(f'<path d="M72 {y-5}H232" stroke="{ink}" stroke-width="1" opacity="0.3"/>')
        if val > 0:
            s.append(f'<path d="M72 {y-5}H{72+160*val:.0f}" stroke="{col}" stroke-width="5" opacity="0.85"/>')
    s.append(f'<text x="20" y="{H-26}" font-family="Georgia, serif" font-size="12" fill="{text}" opacity="0.55">WASD 移动 · SPACE 攻击</text>')

    # right panel: ink notes, no box
    s.append(f'<path d="M{RIGHT_X} {GY-8}V{GY+GRID_W+8}" stroke="{ink}" stroke-width="2" opacity="0.6"/>')
    s.append(f'<text x="{RIGHT_X+18}" y="{GY+26}" font-family="Georgia, serif" font-size="11" letter-spacing="3" fill="{text}" opacity="0.6">UNITS</text>')
    units = [("玩家", "16/16", teal), ("怪物 A", "4/4", rust), ("怪物 B", "4/4", rust)]
    for i, (name, hp, col) in enumerate(units):
        y = GY + 60 + i * 52
        s.append(f'<circle cx="{RIGHT_X+22}" cy="{y-6}" r="5" fill="{col}"/>')
        s.append(f'<text x="{RIGHT_X+38}" y="{y}" font-family="Georgia, Songti SC, serif" font-size="15" fill="{text}">{name}</text>')
        s.append(f'<text x="{RIGHT_X+170}" y="{y}" text-anchor="end" font-family="Georgia, serif" font-size="14" fill="{text}">{hp}</text>')
    s.append(f'<path d="M{RIGHT_X+18} {GY+238}H{RIGHT_X+RIGHT_W-20}" stroke="{ink}" stroke-width="1" opacity="0.4"/>')
    s.append(f'<text x="{RIGHT_X+18}" y="{GY+270}" font-family="Georgia, serif" font-size="11" letter-spacing="3" fill="{text}" opacity="0.6">OMEN</text>')
    s.append(f'<text x="{RIGHT_X+18}" y="{GY+300}" font-family="Georgia, Songti SC, serif" font-size="14" fill="{text}">毒雾将蔓延</text>')
    s.append(f'<text x="{RIGHT_X+18}" y="{GY+326}" font-family="Georgia, Songti SC, serif" font-size="14" fill="{text}">火盆仍在燃烧</text>')

    # bottom bar
    s.append(f'<rect y="{BOT_Y}" width="{W}" height="{H-BOT_Y}" fill="{paper}" opacity="0.92"/>')
    s.append(f'<path d="M0 {BOT_Y}H{W}" stroke="{ink}" stroke-width="2" opacity="0.7"/>')
    s.append(f'<text x="24" y="{BOT_Y+36}" font-family="Georgia, Songti SC, serif" font-size="14" fill="{text}">WASD 移动　SPACE 攻击　ENTER 结束回合　ESC 菜单</text>')
    s.append(f'<text x="{W-24}" y="{BOT_Y+36}" text-anchor="end" font-family="Georgia, serif" font-size="12" letter-spacing="2" fill="{text}" opacity="0.5">SEED 20261030 · DETERMINISTIC</text>')
    s.append('</svg>')
    return "".join(s)

if __name__ == "__main__":
    import pathlib
    out = pathlib.Path(__file__).resolve().parent
    out.mkdir(parents=True, exist_ok=True)
    for name, fn in [("style-a-pixel", style_pixel), ("style-b-tactical", style_tactical), ("style-c-paper", style_paper)]:
        (out / f"{name}.svg").write_text(fn())
        print("wrote", name)
