# README 视觉素材

| 文件 | 作用 | 来源 / 维护 |
|---|---|---|
| `hero.svg` | 首屏标题 + 5×5 房间图 + 通道图例 | 手写 SVG，房间/门/通道数据取自 `game/data/rooms/` 与 `game/presentation/theme/palette.gd` |
| `mechanism.svg` | 环境通道六阶段管线 + 传导比例 + 爆燃示例 | 手写 SVG，数值来自 `docs/06-平衡报告.md` |
| `prototype.png` | M5 可玩运行层实机截图（占位美术） | 由 `game/tools/capture_readme_shots.gd` 驱动运行层截图后裁切 |

约定：

- SVG 用系统字体、无外部资源、不依赖脚本/`foreignObject`；主要文字不小于 18 SVG 单位（1200 宽画布）。
- 实机截图只在 M5 运行层有变化时重拍；文案与数据若变化，优先改 Markdown，再同步图示。

重拍截图：

```bash
GODOT_BIN=/path/to/Godot .tools/Godot.app/Contents/MacOS/Godot \
  --path game --resolution 2200x1520 \
  --script res://tools/capture_readme_shots.gd -- \
  --mode=battle --out=$PWD/.tmp/battle_shot.png
```

截图后按 `prototype.png` 的裁切/圆角处理（0,0 → 1315×880）。
