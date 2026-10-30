# 《折叠地牢》（Folded Dungeon）— 开发准备仓库

> 2D 俯视角 · 回合制战术 · 空间构筑 · Roguelike · Godot 4.x
>
> **当前状态（2026-10-30）：Phase 0 与 M0 已完成。** 工程骨架、房间图/门校验、确定性基础、无头测试均已跑通（29 tests / 534 assertions）；下一步 M1（探索与构筑闭环）。6 项非 M0 决策仍按建议值推进。

---

## 准备度总览

| 方面 | 状态 | 说明 |
|---|---|---|
| 设计理解 | ✅ 完成 | 概念、循环、系统拆解、规则模型、风险（`docs/01`） |
| 设计补全 | ⚠️ 完成但待确认 | 缺失章节已按原文风格补全并标注（`docs/02`） |
| 技术方案 | ⚠️ 框架完成，待修阻塞项 | 架构/数据模型/算法/测试/里程碑已写（`docs/03`） |
| 开源调研 | ✅ 完成 | 5 个指定项目 + 星标列表 + 20+ 补充候选（`research/01`） |
| 工具链 | ✅ 就绪 | Godot 4.7.2 本地可无头运行；`.tools/` |
| AI 开发技能 | ✅ 已安装 | 25 个项目级技能（`.agents/skills/`），DSH 热发现可用 |
| 工程代码 | ✅ M0 完成 | `game/` 工程 + 房间图/门校验/测试基建；M1 待开始 |
| 版本管理 | ⛔ 未初始化 | 尚未 `git init`（建议 M0 前初始化） |
| 待确认决策 | ⏳ 6 项 | D1/D2/D3/D5/D13/B2（见下） |
| 任务计划 | ✅ 已排好 · Phase 0/M0 完成 | [任务推进方案](.agents/plans/2026-10-30-任务推进方案.md)：Phase 0 ✅ → M0 ✅ → M1 ⏳（共 49 个可验收 Task） |
| 评审阻塞项 | ✅ 已修复 | B1 旋转几何 / B2 放置校验 / B3 模拟层污染 / B4 M0 前置错位（见 research/02 修复记录） |

> 结论：**设计层面约 85% 就绪，工程层面 0%。** 现在即可进入 M0，但建议先修 B1–B4（半天内可完成）。

---

## 文档导航

| 文档 | 内容 | 状态 |
|---|---|---|
| [00-原始设计交接文档](docs/00-原始设计交接文档.md) | 用户提供的原始交接文档存档（§5.2 处截断） | 存档 |
| [01-设计理解与系统拆解](docs/01-设计理解与系统拆解.md) | 游戏概念理解、五条理念的验证标准、四层循环、系统拆解、规则模型推导、设计风险 | ✅ |
| [02-补全设计与待确认清单](docs/02-补全设计与待确认清单.md) | D1–D15 决策清单、AI 补全设计（折叠机制、12 房间、战斗、经济）、术语表 | ✅（待确认） |
| [03-技术方案与里程碑](docs/03-技术方案与里程碑.md) | 技术选型、模拟/表现分离架构、数据模型、核心算法、测试策略、M0–M5 里程碑 | ✅（待修 B1–B4） |
| [research/01-Godot开源项目调研](research/01-Godot开源项目调研.md) | 指定项目评估、补充候选、系统映射、许可证与整合方案 | ✅ |
| [research/02-设计文档复核记录](research/02-设计文档复核记录.md) | 独立复核：4 个阻塞项 + 11 个重要问题 + 建议 | ✅ |
| [.agents/skills/README](.agents/skills/README.md) | 项目级 AI 技能索引、用法、许可证与升级方式 | ✅ |
| [.agents/plans/2026-10-30-任务推进方案](.agents/plans/2026-10-30-任务推进方案.md) | **任务推进方案**：Phase 0 + M0–M5，每个 Task 的目标/产出/涉及文件/验收标准 | ✅ |

---

## 一句话理解

> 别人进入地牢寻找宝藏，你建造地牢，让地牢成为自己的武器。
>
> 技术化表述：**房间 = 规则组件，门 = 传导通道，5×5 网格 = 战术装置**；玩家通过放置/旋转/替换房间，让热量、毒雾、寒冷、能量、气流等环境通道在房间之间传导并触发反应，投射物与射束则被镜面、重力、风暴改写路径，再用这套自己搭建的规则地形打回合制战术战斗。

---

## 已确认事项

| 项 | 结论 |
|---|---|
| 引擎 | Godot 4.7.2 stable（`.tools/Godot.app`，无头模式实测可用） |
| 语言 | GDScript |
| 缺失设计 | 由 AI 按原文风格补全，标注 `【AI 补全 / 待确认】` |
| 局外成长 / 美术 / 存档 | 不进入首个可玩版本 |
| 开源项目 | 调研完成；核心规则自研，周边借鉴 Atrium / wooftactics / Grid Tactics Lite 等（详见 research/01） |
| 技能 | 25 个项目级 AI 开发技能已安装（`.agents/skills/`） |
| POC 代码复用 | 2026-10-30 设计者授权：质量没问题可直接用 MIT/Apache 代码，暂不纠结版权；来源记录于 `research/skills-provenance/` |

## 待设计者确认（6 项，最小集合）

1. **D1**「折叠」是机制还是隐喻？（建议：轻量版空间折叠 + 房间折叠）
2. **D2** 战斗粒度：单角色战术 / 小队战术？（建议：单角色）
3. **D3** 探索是否回合制？（建议：全程回合制）
4. **D5** 地牢是渐进扩建还是先生成后改造？（建议：渐进扩建）
5. **D13** 首个可玩版本做 6 个房间还是 12 个？（建议：先 6 个验证引擎）
6. **B2** 12 房间名单与 4 个 AI 补全房间是否可接受？

详见 [02-补全设计与待确认清单](docs/02-补全设计与待确认清单.md)。

## 已修复的阻塞项（Phase 0，详见 [research/02](research/02-设计文档复核记录.md)）

| # | 问题 | 修复方向 |
|---|---|---|
| B1 | 9×7 旋转几何错位 | ✅ 已解决：内部统一 9×9 + 门格/门锚点模型（P0-1） |
| B2 | 放置校验缺分支 | ✅ 已解决：`can_place`/`can_rotate`/`can_replace` 失败码与不变量（P0-3） |
| B3 | 模拟层混入 PackedScene | ✅ 已解决：纯数据 `RoomLayout`，场景归表现层（P0-2） |
| B4 | M0 前置决策错位 | ✅ 已解决：M0 前置改为 G0（D4/D6 冻结），验收对齐计划（P0-4） |

---

## 仓库结构

```text
gmNew/
├── README.md                  # 本文件
├── docs/                      # 设计理解 / 补全设计 / 技术方案
├── research/                  # 开源调研报告、设计复核记录、技能来源
│   ├── 01-Godot开源项目调研.md
│   ├── 02-设计文档复核记录.md
│   └── skills-provenance/     # 技能仓库提交号与许可证副本
├── .agents/skills/            # 25 个项目级 AI 开发技能（提交 Git）
├── tools/install-skills.py    # 技能安装/升级脚本
├── .tools/Godot.app           # 本地 Godot 4.7.2（不提交 Git）
├── .research/                 # 调研用仓库缓存（不提交 Git，约 220MB）
└── game/                      # Godot 工程（M0 创建）
```

## 本地工具链

```bash
# 引擎版本
.tools/Godot.app/Contents/MacOS/Godot --version
# => 4.7.2.stable.official.ed1daf0bf

# 技能维护（源仓库缓存于 .research/skills-repos）
python3 tools/install-skills.py --check
python3 tools/install-skills.py --update

# 无头测试（M0 起可用）
export GODOT_BIN="/Users/softbook/dev/gmNew/.tools/Godot.app/Contents/MacOS/Godot"
"$GODOT_BIN" --headless --path game --script res://tests/run_tests.gd
```

## M0 已完成（2026-10-30）

**产物：**
- `game/`：Godot 4.7 工程、主场景、`tools/godot` 包装脚本；
- `game/core/`：`Fixed` 定点、`DeterministicRng`（SplitMix64 + 命名流）、`Channels`、`DoorSpec`（9×9 门格/门锚点）、`RoomLayout`/`RoomDef`、`RoomInstance`、`RoomGraph`、`DungeonGrid`（放置/旋转/替换/连通性/预算/诊断码）；
- `game/data/rooms/`：`start_room.tres`、`combat_room.tres`（由 `tools/generate_sample_rooms.gd` 生成）；
- `game/tests/`：无头运行器 + 6 个用例文件（**29 tests / 534 assertions**）。

**验收证据：**
- `game/tools/godot import`：无 SCRIPT ERROR；
- `game/tools/godot test`：`{"ok": true, "tests": 29, "assertions": 534, "failed": 0}`，进程退出码 0；
- 失败用例注入验证：退出码 1（已恢复）；
- 主场景无头运行：输出 `[FoldedDungeon] M0 skeleton ready`，退出码 0；
- 门锚点对齐：4 朝向 × 4 面墙组合单测通过（B1 回归）。

## 下一步（按任务计划执行）

完整顺序、每个任务的产出与验收标准见 **[任务推进方案](.agents/plans/2026-10-30-任务推进方案.md)**。M1（探索与构筑闭环）：

1. M1-1 房间内部 TileMapLayer 模板与两个真实房间场景；
2. M1-2 回合制房间内移动/穿门；
3. M1-3 5×5 地图视图与房间切换；
4. M1-4 构筑 UI 与放置预览；
5. M1-5 探索/构筑阶段状态机；
6. M1-6 M1 验收场景。

> 决策未确认时按计划中的 **Assumptions** 建议值推进；已用技能：`godot-project-setup`、`godot-gdscript-headless-testing`、`godot-resources`、`event-bus`。
