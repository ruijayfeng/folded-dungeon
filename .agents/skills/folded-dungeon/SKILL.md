---
name: folded-dungeon
description: 《折叠地牢》项目上下文与工作约定 — Godot 4.7.2 本地工具链、设计/调研文档索引、模拟层/表现层分离、确定性规则引擎、无头测试命令、待确认决策与评审阻塞项。在本仓库做开发、调试、规划或写代码前使用。
---

# 《折叠地牢》（Folded Dungeon）项目上下文

2D 俯视角 · 回合制战术 · 空间构筑 · Roguelike · Godot 4.x + GDScript。
一句话：房间是规则组件，门是传导通道，5×5 网格是玩家搭建的战术装置。

## Quick Reference

| 需求 | 位置 / 命令 |
|---|---|
| 设计文档 | `docs/00`–`docs/03` |
| 开源项目调研结论 | `research/01-Godot开源项目调研.md` |
| M0 阻塞项（内部复核） | `research/02-设计文档复核记录.md` |
| Godot 4.7.2 引擎 | `/Users/softbook/dev/gmNew/.tools/Godot.app/Contents/MacOS/Godot`（`export GODOT_BIN=...`） |
| 无头测试 | `game/tools/godot test`（内部自动 import；包装脚本已处理 HOME） |
| 已安装技能索引 | `.agents/skills/README.md` |
| **任务推进方案（唯一任务来源）** | **`.agents/plans/2026-10-30-任务推进方案.md`** |

## When to use

- 在本仓库创建/修改 Godot 工程、GDScript、场景或 Resource。
- 规划里程碑、拆分 M0–M5 任务、写技术方案或复查设计文档。
- 改动规则引擎（通道/反应配方/回合管线）或房间图校验。
- 不确定该用哪个已安装技能时，先读 `.agents/skills/README.md` 的清单。

## 当前阶段（2026-10-30）

- **Phase 0 / M0 / M1 / M2 已完成**（2026-10-30）：房间图/门校验、探索/构筑闭环、规则引擎 MVP（58 tests / 819 assertions）。**下一步 M3**（战斗最小闭环）。
- 调研报告 `research/01-Godot开源项目调研.md` 已给出可借鉴项目。
- 开发任务已排好：`.agents/plans/2026-10-30-任务推进方案.md`（Phase 0 → M0–M5），按 Task ID 执行与勾选。
- 4 个评审阻塞项已关闭（`research/02` 修复记录）：B1 几何 → 内部 9×9 + 门锚点；B2 放置/旋转/替换不变量；B3 纯数据 `RoomLayout`；B4 M0 前置改为 D4/D6 冻结。
- 已冻结（G0）：D4 几何、D6 构筑资源、定点数值（0–1000，阈值 600/300）、数据/表现分离。
- 待用户确认的关键设计决策：D1 折叠机制、D2 战斗粒度、D3 探索是否回合制、D5 渐进扩建、D13 内容量（6/12 房间）、B2 房间名单。
- POC 许可约定（2026-10-30）：**质量没问题就直接用** MIT/Apache 代码片段，暂不纠结版权；仍建议在文件头/`research/skills-provenance/` 记录来源。

## 目录与文档

| 路径 | 内容 |
|---|---|
| `docs/00-原始设计交接文档.md` | 用户原始设计（§5.2 重力房处截断） |
| `docs/01-设计理解与系统拆解.md` | 概念理解、四层循环、系统 P0/P1/P2、规则模型、体验样例 |
| `docs/02-补全设计与待确认清单.md` | D1–D15 决策 + AI 补全（折叠/12 房间/战斗/经济/术语） |
| `docs/03-技术方案与里程碑.md` | 架构（sim/view 分离）、数据模型、算法、测试、M0–M5 |
| `research/01-Godot开源项目调研.md` | 开源项目评估与整合建议 |
| `.agents/skills/` | 本项目已安装的 Godot/AI 开发技能（见其 README） |
| `game/` | 待创建：Godot 工程（M0） |

## 工具链与命令

- 引擎：**Godot 4.7.2 stable**，本地路径
  `/Users/softbook/dev/gmNew/.tools/Godot.app/Contents/MacOS/Godot`
- 多数 Godot 技能脚本读取 `GODOT_BIN`，先设置：
  ```bash
  export GODOT_BIN="/Users/softbook/dev/gmNew/.tools/Godot.app/Contents/MacOS/Godot"
  ```
- 无头导入（首次/CI）：
  `"$GODOT_BIN" --headless --path game --editor --quit`
- 无头测试（M0 起）：`"$GODOT_BIN" --headless --path game --script res://tests/run_tests.gd`
- 沙箱注意：Godot 写 `user://` 需要 HOME 可写；在受沙箱限制的环境可 `export HOME=/Users/softbook/dev/gmNew/.research/home`。

## 技术约定（以 docs/03 为准）

- **模拟/表现分离**：`core/` 纯 GDScript（无场景依赖、可无头测试）；`presentation/` 只读状态、播动画、转发输入。
- **确定性**：定点整数通道值（建议 0–1000，阈值 600/300）；命名 RNG 流（run/floor/combat/loot），禁止全局 `randi()`；固定遍历顺序 + tie-breaker；事件日志 = 测试与回放依据。
- **数据驱动**：房间/配方/敌人用自定义 `Resource`（`.tres`）；`EffectDef` 不可变，运行时状态放 `RoomInstance`；避免 `RoomDef → PackedScene → …` 循环依赖。
- **规则模型**：通道（HEAT/TOXIN/COLD/CHARGE/AIRFLOW）+ 排放 + 门对门传导 + 反应配方（条件 + 效果）+ 回合管线（排放→传导→反应→衰减）。
- **空间**：5×5 宏观房间图（节点=房间，边=双向匹配的门）+ 9×7 微观战斗格；旋转作用于整个房间朝向；折叠 = 虚拟邻接边。

## 已安装技能怎么用（详见 `.agents/skills/README.md`）

| 任务 | 优先加载 |
|---|---|
| 引擎/scene/resource 的无头检查与编辑、项目脚手架、API 查询 | `godot`（注意：SKILL.md 约 82KB，加载成本高，按需） |
| 写/改 GDScript | `godot-gdscript`、`gdscript-patterns` |
| 无头测试/CI | `godot-gdscript-headless-testing` |
| 架构模式 | `event-bus`、`resource-pattern`、`scene-organization`、`state-machine` |
| 数据 Resource | `godot-resources`、`resource-pattern` |
| 房间内部 Tile 地图 | `godot-tilemap` |
| 肉鸽/战斗/技能/经济 | `godot-genre-roguelike`、`godot-combat-system`、`godot-ability-system`、`godot-economy-system` |
| 程序生成 / 敌人 AI | `procedural-generation`、`ai-behavior-trees-utility-ai` |
| UI | `godot-ui` |
| 设计决策盘问 | `godot-grill` |
| 开发计划 / 文档组织 / 新技能 | `plan-plain`、`project-doc-organization`、`skill-writing` |

## 调研结论速查（详见 research/01）

- 核心「房间规则 + 邻接联动」**没有可直接复用的开源项目**，必须自研。
- **Atrium**（MIT）：房间图/双向门/放置校验/确定性生成的拓扑层值得 2D 重写借鉴。
- **wooftactics**（Apache-2.0，C#）：确定性 RNG、命令-过渡-事件、AI 候选枚举、Run 结构的最佳架构参考（需移植）。
- **Grid Tactics Lite**（MIT，708 行）：房间内网格移动可直接改造。
- **constraint-solving**（MIT）：房间内部 WFC 布局实验（非 MVP）。
- 避免：GPL/AGPL/无许可证代码不要进游戏代码；3D 插件不能直接用于 2D 运行时。

## 已知坑

- 旋转几何：内部 9×9、门 = 外环中点门格 + 墙边中点门锚点；邻房门锚点世界坐标必须重合（已冻结）。
- float32 累加在 0.6/0.3 阈值边界可能抖动——用定点整数。
- `.tres` 只放静态数据；不要把运行时状态写进共享 Resource。
- Godot 场景/资源不要手工乱改 `.tscn`（UID/导入缓存易坏），用 `godot` 技能脚本或编辑器。
