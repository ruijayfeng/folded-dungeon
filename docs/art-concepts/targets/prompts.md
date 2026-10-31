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

---

# B · 2.5D 暗黑地牢（2026-10-31 最终选定）

> 生成环境：用户本机 Azure OpenAI `gpt-image-2.5-sunburst`，`quality=max`，`size=1024x1024`，`n=1`。
> 后处理：法线（Sobel）、绿幕抠像（Pillow）、裁切、尺寸统一；脚本见 `.agents/plans` 与后续 `game/tools/art/`。

## 房间材质

### 石砖地面
```text
Seamless tileable texture of dark ancient dungeon flagstone floor, top-down orthographic view, weathered grey stone slabs with cracks, dirt, dried blood stains, moss between stones, high detail, AAA game texture, uniform neutral lighting, no text, no watermark, no objects, fills the frame edge to edge.
```

### 石砖墙面
```text
Seamless tileable texture of dark dungeon stone brick wall, rough rectangular blocks, mortar joints, soot, damp stains, high detail, AAA game texture, uniform neutral lighting, no text, no watermark, no objects, fills the frame edge to edge.
```

### 木门/木箱
```text
Seamless tileable texture of old dark oak wood planks with iron rivets and bands, worn grain, scratches, high detail game texture, uniform neutral lighting, no text, no watermark, fills the frame edge to edge.
```

### HUD 皮革
```text
Seamless tileable texture of dark worn brown leather, game UI panel material, subtle grain, cracks and scratches, uniform soft lighting, no text, no watermark, fills frame edge to edge.
```

### 蛛网（黑色背景 + 加法混合）
```text
A dusty old spider web in a corner, seen from above, pale grey strands on pure black background, isolated, high contrast, no text, no watermark.
```

## 单位立绘（纯绿幕 + 抠像）

### 玩家 · 重甲骑士
```text
Dark fantasy armored knight, full body standing pose, seen from a high three-quarter top-down angle like an isometric RPG, heavy dark steel plate armor with aged gold trim and a dark blue tattered tabard, holding a longsword and a round shield, dramatic warm torch rim light from the upper left, deep shadows, painterly detailed game character art with strong dark atmosphere, crisp silhouette, isolated on a pure solid chroma green background (#00FF00), full body visible from head to feet, centered, no text, no watermark, no ground shadow.
```

### 怪物 · 炎魔
```text
Dark fantasy demon monster creature, hulking horned red-black imp with glowing yellow eyes, clawed hands and jagged teeth, seen from a high three-quarter top-down angle like an isometric RPG, painterly detailed game monster art, dramatic warm rim light, deep shadows, crisp silhouette, isolated on a pure solid chroma green background (#00FF00), full body visible, centered, no text, no watermark, no ground shadow.
```

### 怪物 · 骷髅战士
```text
Dark fantasy undead skeleton warrior, rusty ancient armor and tattered cloth, holding a chipped sword, seen from a high three-quarter top-down angle like an isometric RPG, painterly detailed game monster art, cold blue rim light, deep shadows, crisp silhouette, isolated on a pure solid chroma green background (#00FF00), full body visible, centered, no text, no watermark, no ground shadow.
```

## 程序生成（非 AI）

- `normal_from_albedo`：Sobel 由 albedo 生成法线贴图；
- `flame.png`：火苗渐变（Pillow）；
- `fog-noise.png`：多椭圆模糊噪声；
- `shadow-blob.png`：径向黑色阴影；
- `blood.png`：随机椭圆 + 模糊血迹；
- `tox-blob.png`：径向绿色毒雾。
