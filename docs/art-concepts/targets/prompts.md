# D11 目标画面：生成记录

> 决策：2026-10-31 设计者选定 **A（像素地牢，游戏内）+ D（折叠地牢主视觉/封面）**。
> 生成环境：用户本机配置的 Azure OpenAI `gpt-image-2.5-sunburst`（`quality=max`，`1536x1024`，`n=1`）。
> 文件：`target-a-pixel.jpg` / `target-d-keyart.jpg`（1280 宽网页压缩版；原始 PNG 2-3MB 未入库，可用下方 prompt 重新生成）。

## A · 像素地牢（游戏内目标画面）

```text
Orthographic top-down 2D pixel-art game scene of a dark dungeon battle room, 16-bit SNES retro pixel art. A 9 by 9 tile stone room: thick stone brick walls with wooden dungeon doors in the middle of each wall, glowing faint gold. Dark stone floor tiles with cracks and faint checker pattern. Center-left: a small blue-armored pixel knight holding a sword, facing right. Upper-right: two red horned slime demons with glowing yellow eyes. Upper-right floor: patch of glowing toxic green fog with tiny bubbles. Upper-left corner: an iron brazier with bright orange fire and warm light spilling across the floor. Wall torches with warm glow. Cinematic vignette, soft bloom, crisp chunky pixels, high detail, moody dark fantasy roguelike. No text, no user interface, no watermark, no logo.
```

## D · 折叠地牢主视觉 / 封面

```text
Cinematic game key art for a 2D top-down tactical roguelike about building a dungeon: a dark dungeon floor plan seen from above where rooms fold and overlap like sheets of paper, glowing golden doorways linking rooms, five colored magical energies swirling between rooms — orange heat, green toxin, blue cold, yellow charge, pale airflow. A tiny lone knight silhouette stands in the center room, dramatic rim lighting, deep shadows, moody fantasy, painterly high detail, subtle volumetric light, wide composition, no text, no logo, no watermark.
```

## 用途约定

- A：作为 M6 实现对照（房间/光照/通道/单位比例/氛围），实际资产用 CC0 像素包 + 自绘补件。
- D：README 首图、游戏标题界面背景、后续商店页/胶囊图；不直接作为游戏内战斗画面。
- AI 生成内容的使用范围按生成模型服务条款执行；正式发行前复核。
