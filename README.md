# 《折叠地牢》（Folded Dungeon）— 开发准备仓库

> 2D 俯视角 · 回合制战术 · 空间构筑 · Roguelike · Godot 4.x
>
> **当前状态（2026-10-30）：Phase 0 / M0–M4 已完成。** 垂直切片核心闭环已跑通（75 tests / 956 assertions）：楼层计划、构筑→探索→战斗/事件/休整/商店→奖励→Boss→结算、Boss 房间规则能力、两层推进；下一步 M5（内容与发布准备，含 GUI 运行层接入）。6 项非 M0 决策仍按建议值推进。

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
| 工程代码 | ✅ M4 完成 | 探索/构筑 + 规则引擎 + 战斗 + 单局/楼层闭环；M5 待开始 |
| 版本管理 | ⛔ 未初始化 | 尚未 `git init`（建议 M0 前初始化） |
| 待确认决策 | ⏳ 6 项 | D1/D2/D3/D5/D13/B2（见下） |
| 任务计划 | ✅ 已排好 · Phase 0–M4 完成 | [任务推进方案](.agents/plans/2026-10-30-任务推进方案.md)：Phase 0 ✅ → M0 ✅ → M1 ✅ → M2 ✅ → M3 ✅ → M4 ✅ → M5 ⏳（共 49 个可验收 Task） |
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

## 版本控制（Git）

- **分支：** 原型期单分支 `main`；重大实验用 `exp/<topic>` 分支，合并后删除。
- **提交粒度：** 一个 Task（或一组强相关改动）一次提交；提交信息格式 `TaskID: 摘要`（如 `M0-4: 房间图连通性校验`），里程碑收口用 `M0/M1: ...`。
- **提交前检查：** `game/tools/godot test` 必须全绿、`game/tools/godot import` 无 SCRIPT ERROR；只提交预期文件。
- **里程碑标签：** 每个里程碑完成打 annotated tag：`m0`、`m1`…（当前已有 `m0`）。
- **不提交：** `.godot/`、`.tools/`、`.research/`、`.tmp/`、构建产物；`.gitattributes` 统一文本为 LF，图片/音频按二进制处理。
- **回退：** 小问题 `git revert <sha>`；里程碑级回退 checkout 对应 tag 后新开提交，不改写已发布历史。

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

## M1 已完成（2026-10-30）

**产物：**
- `game/core/run/dungeon_session.gd`：单局会话（4 向移动/穿门/回合/蓝图/阶段状态机/事件日志）；
- `game/core/run/build_controller.gd` + `game/core/combat/unit.gd`：构筑预览/旋转/确认（复用 `DungeonGrid` 校验）、玩家单位；
- `game/presentation/`：`RoomView`（9×9 占位色块渲染）、`GridMapView`（5×5 地图 + 构筑 ghost）、`BuildPanel`（阶段/BP/放置/旋转/确认）、`main.gd` 沙盒（WASD 移动、Tab 构筑节点、地图点击选格、R 旋转、Enter 确认）；
- `game/presentation/rooms/`：`room_template.tscn`、`start_room.tscn`、`combat_room.tscn`。

**验收证据：**
- `game/tools/godot test`：`{"ok": true, "cases": 10, "tests": 40, "assertions": 653, "failed": 0}`，退出码 0；
- M1 验收场景 `tests/scenarios/m1_build_and_enter.gd`：探索 → 获得蓝图 → 构筑节点 → 放置房间 → 穿新门，事件序列与门锚点断言通过；
- `game/tools/godot import`：无 SCRIPT ERROR；主场景无头运行退出码 0；
- 构筑预览/旋转不修改真实布局（快照对比断言）。

## M2 已完成（2026-10-30）

**产物：**
- `game/core/rules/room_state.gd` / `condition_def.gd` / `effect_def.gd` / `reaction_recipe.gd` / `rule_engine.gd`；
- 确定性环境管线：排放 → 一跳传导（高→低，源×百分比，同阶段快照）→ 相邻吸收 → 反应配方（优先级 / 冷却 / 每回合上限）→ 衰减 → 周期性事件；CHARGE 守恒，其余为环境场；全定点整数；
- `game/data/rooms/`：熔炉、毒雾、冰霜、镜面、蓄能、箭塔 6 个规则房间；`game/data/recipes/`：爆燃、冷热相消、充能释放 3 个配方（由 `tools/generate_sample_rooms.gd` 生成）；
- 预览：`RuleEngine.preview_turns(n)` 克隆状态预演，事件与真实推进逐条一致；
- 折叠 MVP：折叠房授予折叠充能 → 虚拟传导边（`DungeonSession.activate_fold`；折叠移动留到 M4 折叠 UI）；
- 表现层：房间通道染色、`DebugPanel`（通道值 + 最近事件）、主场景接入 RuleEngine（移动时推进环境）。

**验收证据：**
- `game/tools/godot test`：`{"ok": true, "cases": 19, "tests": 58, "assertions": 819, "failed": 0}`，退出码 0；
- M2 验收场景 `tests/scenarios/m2_combo_chain.gd`：第 1/2/3 回合毒雾房 heat=100/300/600、toxin=200/400/600；第 3 回合爆燃（channels_before 600/600）+ 燃烧状态 + 火焰波经镜面由东转向南命中目标房；
- `preview_turns(3)` 与真实 tick 事件 JSON 逐条一致；确定性：两次独立引擎事件/状态完全一致；
- 主场景无头运行退出码 0；`game/tools/godot import` 无 SCRIPT ERROR。

## M3 已完成（2026-10-30）

**产物：**
- `game/core/combat/unit.gd`：单位属性/状态/克隆（HP、攻击、移动点、burning/poisoned/chilled/charged/stunned）；
- `game/core/combat/combat_state.gd`：战斗状态（玩家/敌人/环境阶段、攻击、击退+碰撞伤害、占用格）；
- `game/core/combat/combat_controller.gd`：战斗循环（玩家阶段 → BFS 追击敌人阶段 → 环境阶段 → 胜负结算）；
- `game/core/combat/projectile_system.gd`：房间级投射物（门到门、镜面转向、箭塔周期射击、事件日志）；
- 表现层：`CombatHUD`、`RoomView` 敌人/血条渲染、主场景 `C` 键测试战斗（WASD 移动 / SPACE 攻击 / ENTER 结束回合）。

**验收证据：**
- `game/tools/godot test`：`{"ok": true, "cases": 23, "tests": 69, "assertions": 893, "failed": 0}`；
- M3 验收场景 `tests/scenarios/m3_battle_layouts.gd`：同一战斗在「空地」与「熔炉+毒雾包围」两种布局下结果不同（plain enemy_hp=4 / combo=1，combo 第 2 回合被环境击杀）；
- 镜面房把投射物由东转向南命中敌人（`test_projectile_m3`）；毒雾/热浪同时伤害玩家与敌人；击退撞墙额外伤害；
- 主场景无头运行退出码 0；import 无 SCRIPT ERROR。

**实现差异（已记录）：** 双阶段制替代多单位 initiative；投射物为房间级抽象（逐格弹道后置）；风暴/重力房改写随 M5 内容补。

## M4 已完成（2026-10-30，核心闭环保留 GUI 到 M5）

**产物：**
- `game/core/run/run_state.gd`：可序列化单局状态（种子/楼层/金币/BP/已清槽位/事件/胜负）；
- `game/core/run/floor_plan.gd`：确定性楼层结构（7 个内容槽位 + 起始房：战斗/事件/战斗/休整/精英/商店/Boss）；
- `game/core/run/run_controller.gd`：构筑 → 探索 → 战斗/事件/休整/商店 → 奖励 → Boss → 楼层推进/结算；
- Boss 房间规则能力：每回合向房间注入热量（`boss_heat`）、对热危害免疫；
- `game/data/rooms/` 新增 `boss_room`、`corridor_room`；
- 自动验收辅助 `auto_build_adjacent` / `auto_walk_into` / `CombatController.auto_resolve`（仅用于回归，不参与正式规则）。

**验收证据：**
- `game/tools/godot test`：`{"ok": true, "cases": 26, "tests": 75, "assertions": 956, "failed": 0}`；
- 自动化垂直切片：一层 8 房间 / 7 槽位全部清空、Boss 击杀、胜利结算；金币/BP 奖励、蓝图 3 选 1、Boss 能力事件、≥3 种房间类型；
- 两层运行：首层 Boss 后触发 `floor_advanced`，第二层结束触发结算；
- 主场景无头运行退出码 0；import 无 SCRIPT ERROR。

**实现差异（已记录）：** 垂直切片当前为**脚本驱动核心闭环**；玩家可玩的构筑/商店/事件/首领 GUI 在 M5-4 接入。`auto_*` 方法只用于自动化验收。

## 下一步（按任务计划执行）

完整顺序、每个任务的产出与验收标准见 **[任务推进方案](.agents/plans/2026-10-30-任务推进方案.md)**。M5（内容与发布准备）：

1. M5-1 补齐 12 房间 → M5-2 平衡与组合验证；
2. M5-3 美术方向与占位替换 → M5-4 UI 打磨与**可玩 GUI 运行层接入**（构筑/商店/事件/首领）；
3. M5-5 存档断点与种子分享 → M5-6 局外成长（D10 决策后）→ M5-7 Windows 导出与冒烟 → M5-8 发布前验收。

> 决策未确认时按计划中的 **Assumptions** 建议值推进；已用技能：`godot-project-setup`、`godot-gdscript-headless-testing`、`godot-resources`、`event-bus`。
