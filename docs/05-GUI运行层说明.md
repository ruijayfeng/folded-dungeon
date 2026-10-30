# 05 · GUI 运行层说明（M5 可玩版本）

> 场景：`game/presentation/run_mode/run_mode.tscn`（`project.godot` 主场景）
> 运行：`game/tools/godot run`

## 操作

| 阶段 | 操作 |
|---|---|
| 构筑 | `1/2/3` 选蓝图；鼠标点地图格选位置；`R` 旋转；`Enter` 建造 |
| 探索 | `WASD` 移动；穿过门进入新房间自动触发内容 |
| 战斗 | `WASD` 移动；`SPACE` 攻击相邻敌人；`Enter` 结束回合 |
| 事件/休整/商店 | `1/2/3` 选择选项 |
| 结算 | `R` 重新开始 |

## 界面

- 左：5×5 宏观地图（当前房间高亮、构筑 ghost 绿/红表示可/不可放置）；
- 右：当前房间 9×9（门、出生点、通道染色、玩家/敌人/血条）；
- 上：楼层/金币/构筑点/阶段/蓝图提示；
- 下：选项按钮；调试面板显示当前房间通道值与最近规则事件。

## 架构

```text
RunMode (presentation)
  └── RunController (core/run)
        ├── DungeonSession / DungeonGrid   探索与建造
        ├── RuleEngine                    环境规则
        └── CombatController              战斗（含 Boss 能力）
```

`RunMode` 只读/转发输入；规则、胜负、奖励全部在 core 层，便于无头回归测试。

## 手工验收清单

- [ ] 用 3 个蓝图选项各建造一次，旋转后门位对齐；
- [ ] 走入门触发战斗/事件/休整/商店；
- [ ] 战斗用攻击/结束回合打完一场；观察通道染色与 DebugPanel；
- [ ] 打完 Boss 看到结算；`R` 重开；
- [ ] 记录任何卡死、按钮不可点、文字溢出问题到 `docs/08` 已知问题。
