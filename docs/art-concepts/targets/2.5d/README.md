# 2.5D 暗黑地牢 · 达标房 v1 参考

- `bench-room-v1.png`：**真引擎渲染**（Godot 4.7.2 → Forward+，`--rendering-method forward_plus`），非 AI 出图。画面：3D 材质房间 + 火盆/火把 + 毒雾区 + AI 立绘单位（骑士/炎魔/骷髅）+ 皮革悬浮 HUD。分辨率为本机窗口 1100×760（设计目标 1280×800）。
- `units/*.jpg`：AI 生成立绘的压缩参考（实际游戏内使用透明 PNG；生成 prompt 见 `../prompts.md`）。
- `materials/*.jpg`：AI 生成材质参考（石墙/地砖/木门/皮革；法线由脚本从 albedo 生成）。
- 说明：本目录只保存**验收参考**；生产资产、脚本与清单将进入 `game/assets/art3d/`（见 `docs/09` 与 M6 计划）。
