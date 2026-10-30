# 《折叠地牢》Godot 4 开源项目调研（第一阶段）

> **调研日期：** 2026-10-30
> **调研目标：** 围绕 Godot 4，找出能加速《折叠地牢》开发的开源项目，重点服务其核心玩法：房间作为可组合构筑组件、房间独立规则与空间连接条件、相邻房间规则联动、改变布局影响战斗与探索、肉鸽结构（随机奖励/分支路线/Boss/局外成长）。
> **本阶段范围：** 用户指定的 5 个项目 + 星标列表 + `topics/godot` 话题页 + 围绕上述系统的补充检索。
> **结论先行：** **没有任何开源项目能直接复用「房间规则 + 邻接联动」这一核心玩法**；必须自研规则引擎。但房间图/门连接、回合制战术骨架、肉鸽单局结构、网格移动等「周边系统」可以在多个 MIT/Apache 项目中获得高价值借鉴或改造基础。**推荐：自研核心 + 选择性借鉴/移植周边。**

---

## 0. 执行摘要（TL;DR）

### 0.1 五个指定项目的结论

| # | 项目 | 星标※ | 许可证 | Godot | 一句话定位 | 对本项目的结论 |
|---|---|---|---|---|---|---|
| 1 | [Dragonboon/Atrium](https://github.com/Dragonboon/Atrium) | 85 | MIT | 4.7.2 | 3D 房间/地牢程序化搭建编辑器插件 | **★ 最高价值借鉴**：房间图/门 socket/放置校验/确定性生成的拓扑层，可 2D 重写 |
| 2 | [AlexeyBond/godot-constraint-solving](https://github.com/AlexeyBond/godot-constraint-solving) | 466 | MIT | 4.4 | WFC + 通用约束求解器 | **○ 备选实验**：可用于生成 9×7 房间内部布局；不适合做房间规则引擎 |
| 3 | [Lommix/infinite_worlds](https://github.com/Lommix/infinite_worlds) | 27 | MIT | 4.2 | WFC 无限区块世界（已停更） | **✗ 不采用**：无限世界与 5×5 有限地牢不匹配，作者已弃坑 |
| 4 | [ClarkWain/godot-arpg-kit](https://github.com/ClarkWain/godot-arpg-kit) | 17 | MIT | 4.5+ | 2D ARPG 数值/战斗/状态/物品/掉落系统 | **○ 部分借鉴**：数据驱动 Resource、状态/掉落/测试基建有用；实时战斗不适合 |
| 5 | [cty41/wooftactics](https://github.com/cty41/wooftactics) | 1 | Apache-2.0 | 4.7（C#/.NET 9） | 回合制战术肉鸽（Pure Run，七层节点） | **★ 最佳架构参考**：确定性回合、命令-过渡-事件、AI、Run 结构；C# 需移植而非直接用 |
| 6 | [github.com/sanskar](https://github.com/sanskar) | — | — | — | GitHub 用户主页 | **? 无效输入**：该用户无公开仓库，需确认原意 |

※ 星标为 2026-10-30 抓取的近似值。

### 0.2 最重要的四个判断

1. **核心规则系统没有现成答案。** 通道（热/毒/冷/能量/风）+ 邻接传导 + 反应配方 + 空间折叠，这类「环境图规则引擎」在 Godot 开源生态中没有对应项目。现有 GAS（Gameplay Ability System）类项目解决的是「角色技能」，不是「房间环境规则」。
2. **最像本项目「宏观层」的是 Atrium。** 它的 `DungeonPlanner`（纯逻辑、无场景依赖、确定性种子）、`LevelLayout`/`RoomPlacementData`/`RoomConnectionData`（房间图与双向门 socket）、`RoomValidationReport`（诊断码）几乎逐条对应我们对 5×5 房间图的需求——虽然它是 3D 编辑器插件，但**设计可以照搬，代码需 2D 重写**。
3. **最像本项目「回合制骨架」的是 wooftactics。** 它把「引擎无关的纯逻辑 Core（确定性 RNG、Battle/Run 状态）」与「Godot 表现适配层」彻底分离，并配有 Frozen Oracle/确定回放测试——这正好验证了我们技术方案中的「模拟/表现分离」。语言是 C#，但架构与关键算法（SplitMix64、Initiative 排序、Dijkstra/LOS、命令-过渡-事件）可移植到 GDScript。
4. **用户星标列表偏「引擎/工具/基建」，不含玩法框架。** 18 个仓库中只有 beehave（AI）、godogen/godot-mcp（AI 开发工具）、awesome-godot（索引）与项目开发流程相关；`topics/godot` 是通用热门榜，不适合精确检索子系统，应改用「topic + 关键词」的 GitHub 搜索。

### 0.3 推荐技术路线

```text
核心规则（通道/配方/传导/折叠/回合管线/构筑预览） → 100% 自研（见 docs/03 技术方案）
宏观房间图与门连接校验                      → 借鉴 Atrium 数据模型与校验不变量，2D 重写
房间内网格移动/寻路                         → 基于 Grid Tactics Lite（MIT, 708 行）改造
回合制战斗架构                              → 参考 wooftactics（确定性 RNG/命令-事件/AI）
肉鸽单局与构筑 UI                           → 参考 Slay-The-Robot / deck_builder_tutorial
房间内部程序化布局（可选）                   → constraint-solving WFC 实验
数据驱动资源与测试基建                      → 借鉴 arpg-kit 的组件化/Resource/CI 模式
AI 工具链                                   → godogen / godot-mcp / awesome-godot（非游戏代码）
```

---

## 1. 调研方法

| 项 | 做法 |
|---|---|
| 源码获取 | `git clone --depth 1` 全部指定项目，直接阅读 README、`project.godot`、目录结构、关键类源码 |
| 元数据 | stars/forks 通过 shields.io 抓取；最后提交时间用 `git log -1`；许可证读取 LICENSE 原文 |
| 版本兼容性 | 用本地 **Godot 4.7.2-stable**（`.tools/Godot.app`）以 `--headless --path <repo> --editor --quit` 做导入解析测试；**通过 = 无 SCRIPT ERROR/Parse Error**，不代表运行时功能正确 |
| 星标列表 | 抓取 `https://github.com/stars/ruijayfeng/lists/game` 的公开列表内容（18 个仓库） |
| 话题页 | 抓取 `https://github.com/topics/godot` 的 Top 仓库 |
| 补充检索 | GitHub Search API：`topic:godot roguelike`、`godot turn based tactics`、`godot dungeon generation`、`godot deckbuilder`、`godot tactical rpg`、`godot gameplay ability system` 等 20+ 组关键词，按星标排序 |

**局限：** ① 未逐个实际运行游戏/插件（只做导入解析测试）；② 星标、提交时间随时变化；③ GitHuh API 核心配额在调研时耗尽，元数据改用 HTML/shields/本地 git 获取，个别字段为近似值；④ "sanskar" 用户无公开仓库，无法评估。

---

## 2. 指定项目逐项评估

### 2.1 Atrium —— 最值得借鉴的房间图/门连接实现

| 项目信息 | 值 |
|---|---|
| 仓库 | https://github.com/Dragonboon/Atrium |
| 星标 / Fork | 85 / 6 |
| 最后提交 | 2026-10-16（活跃） |
| 许可证 | MIT（© 2026 sempitern0） |
| 引擎/语言 | Godot 4.7.2 / GDScript（编辑器插件，`@tool`） |
| 规模 | 2.4 MB，79 个 `.gd` |

**它是什么：** 一个「编辑器优先」的 3D 房间/地牢/多层建筑**搭建插件**。核心工作流：房间蓝图（尺寸、墙、门洞）→ 程序化生成布局（关键路径 / DFS 树 / 随机前沿树，可配分支与环路）→ 手动微调（锁房间、调几何、刷外观模块）→ 导出为原生 Godot 场景。支持多楼层、自由朝向、离格 socket 拼装。

**与《折叠地牢》的关系（为什么值得读）：**

- 它有本项目「宏观层」几乎全部要素，且实现质量高：
  - `DungeonPlanner extends RefCounted`（`@tool`），注释明确「Pure F2 grid topology/embedding. **No SceneTree nodes, no global RNG**」——纯逻辑、可无头测试、种子确定性；
  - 数据结构：`LevelLayout`（网格尺寸、seed、房间数组、连接数组）、`RoomPlacementData`（`cell: Vector2i`、`stable_id`、`role`、`shape_rotation`、锁/覆盖信息）、`RoomConnectionData`（`from_room_id`、`to_room_id`、`from_wall`、`to_wall`、开口宽度/偏移）——**「一条图边 = 两个互相对应的门」**，正是我们连接校验的核心不变量；
  - 生成策略：关键路径 + 分支 + 环路 + 预算/重试 + 失败诊断码（`RoomValidationReport.errors/warnings`）；
  - 校验：房间坐标不重叠/越界、ID 唯一、房间变换与网格一致、连接与门开口匹配、环路数公式（`edges - rooms + 1 == expected_loops`）等；
  - 确定性：局部 `RandomNumberGenerator` 以 seed 初始化；参数化预算避免无限重试。
- 它的「房间锁/手动覆盖/事务式编辑（先 duplicate 校验再提交）」思路，可直接用于我们的「构筑节点放置/替换/旋转」校验。

**不能直接用的原因：**

1. **3D 编辑器工具，不是运行时游戏系统**：大量 3D 依赖（`Vector3` 尺寸、`Transform3D`、网格/碰撞、`RoomOpening.Wall` 物理 socket、场景编译器）。我们的游戏是 2D、9×7 房间、运行时放置，不能直接装插件。
2. 它的门是「墙上的开口 + 走廊路由」，我们是「相邻房间共享墙上的门格」——模型更简单，无需 corridor router / free-yaw packer。
3. 它**不包含**任何房间规则/环境传导/邻接效果——那正是我们要自研的部分。

**建议：** 把 Atrium 的「拓扑层」当成参考实现：`stable_id`、`cell`、双向门连接、连通性/环路校验、确定性生成、诊断报告格式。可以按 MIT 协议移植少量纯逻辑代码（保留版权声明），但更推荐**参考其不变量，在 2D 中重写约 300–500 行**。

---

### 2.2 godot-constraint-solving —— WFC/CSP 通用求解器

| 项目信息 | 值 |
|---|---|
| 仓库 | https://github.com/AlexeyBond/godot-constraint-solving |
| 星标 / Fork | 466 / 19 |
| 最后提交 | 2025-05-13 |
| 许可证 | MIT（© 2023 Alexey Bondarenko） |
| 引擎/语言 | Godot 4.4 / GDScript（含 GUT 测试插件） |
| 规模 | 26 MB（含示例资源），90 个 `.gd` |

**它是什么：** Godot 4 的 **WFC（Wave Function Collapse）+ 通用约束满足问题（CSP）求解器**。特性：回溯、多线程、从示例地图学习规则、支持 `TileMapLayer`/`TileMap`/`GridMap`、瓦片概率、负样本、预条件（precondition）API。通用 `WFCSolver`（RefCounted）+ `WFCProblem` 抽象类可复用于非 WFC 的约束求解。

**对本项目可能的用途：**

- **房间内部布局生成**：为 9×7 房间生成地形/障碍/危险区域布局（以手绘示例地图学习规则），例如熔炉房的地形、毒雾房的水洼/管道、镜面房的反射面位置；
- 其 `precondition_2d_dungeon` 示例可生成「连通道路被墙包围」的地图，说明可以用预条件约束生成局部房间；
- **不建议**用它解 5×5 宏观房间布局：README 明确「不支持全局约束（含路径连通约束）」，而宏观布局的「门对门 + 全图连通 + Boss 可达」正是全局约束；我们自己的 5×5 校验器（Atrium 思路）更简单可靠。

**注意事项：**

- 手工维护 WFC 规则集（示例地图/负样本）有一定学习成本，且没有规则编辑器（README 明确说明）；
- 导入 Godot 4.7.2 解析通过（实测无脚本错误），但它只在 4.4 上维护；运行时行为需实测；
- 自带 `addons/gut` 完整测试框架（可剥离，只取 `addons/wfc`）。

**建议：** **非 MVP 必选**。如果 M2/M3 后房间内部多样化成为瓶颈，再做「用 WFC 生成房间内部地形」的 1–2 天实验；不要把宏观布局交给它。

---

### 2.3 infinite_worlds —— 不采用

| 项目信息 | 值 |
|---|---|
| 仓库 | https://github.com/Lommix/infinite_worlds |
| 星标 / Fork | 27 / 4 |
| 最后提交 | 2023-11-30 |
| 许可证 | MIT（© 2023 Lorenz Mielke） |
| 引擎/语言 | Godot 4.2 / GDScript |
| 规模 | 5.7 MB，13 个 `.gd` |

**它是什么：** 用 WFC 生成**无限延伸、按区块动态加载**的世界（`WfcTileMap` 节点，玩家移动时加载/收缩区块）。作者在 README 里明确：**「work in progress/demo addon and not production ready, there are many bugs」**，且已切换到 Bevy，**不再加新功能**。

**不采用的理由：**

1. 我们是 5×5 有限地牢，不需要无限世界与区块加载；
2. 使用旧版 `TileMap` API（Godot 4.3 起已被 `TileMapLayer` 取代，4.7 中是 legacy/弃用状态）；
3. 未维护、无测试、作者自述 demo 质量；
4. 不解决房间图/邻接规则问题。

**建议：** 跳过。可仅作为「WFC 区块规则学习」的代码示例浏览（如果以后做无限模式），但不进入技术选型。

---

### 2.4 godot-arpg-kit —— 部分借鉴（数据驱动 + 测试基建）

| 项目信息 | 值 |
|---|---|
| 仓库 | https://github.com/ClarkWain/godot-arpg-kit |
| 星标 / Fork | 17 / 0 |
| 最后提交 | 2026-10-10（活跃，v0.2.0） |
| 许可证 | MIT（© 2026 eiehihi） |
| 引擎/语言 | Godot 4.5+ / 纯 GDScript |
| 规模 | 2.5 MB，82 个 `.gd`，33 个 `.tres` |

**它是什么：** 一套组件化、数据驱动的 **2D ARPG 系统集合**：`StatsComponent`（属性/生命/回复）、`CombatComponent`（实时攻击/受击/连击）、`StatusEffectManager`（Buff/Debuff/DOT/护盾）、`SkillManager`、`InventoryManager`、`EquipmentManager`、`LootGenerator`/`EnemyLootComponent`、`TaskManager`（任务），以及 `CombatEventBus`/`QuestEventBus` 事件总线。全部为 `Resource`（`.tres`）配置，附 228 个单元/回归测试、中文文档、Godot 4.5/4.6 CI。

**可借鉴 / 可复用：**

- **数据驱动 Resource 的组织方式**（Stats/Status/Skill/Item/Loot 全部 `.tres`，编辑器可视化配置）——与我们的「房间/配方/敌人数据资源化」同构，可参考其字段设计与加载方式；
- `StatusEffectManager` 的「数据 + 实例分离」「DOT/护盾/叠层」模式，可改造为回合制状态系统；
- `LootTable`/`EnemyLootComponent`/`LootGenerator`：如果首版做随机奖励/掉落，可直接参考甚至裁剪复用（MIT）；
- **测试基建**：`tools/run_tests.py` + headless test scenes + 228 测试 + CI 汇总校验，是我们无头测试体系的好范本；
- 中文技术文档写作方式值得参考。

**不适用：**

- `CombatComponent` 是**实时 ARPG 战斗**（`_process`、连击窗口、无敌帧、`CharacterBody2D` 攻击判定），与我们的回合制格子战术完全不同，不能用于战斗核心；
- 它没有空间/房间/邻接概念，也没有肉鸽单局结构。

**建议：** 把 arpg-kit 当作「数据驱动 + 状态/掉落 + 工程规范」的参考库。如果要做敌人状态/掉落/装备，可复制其设计思路或少量 MIT 代码（保留声明）。

---

### 2.5 wooftactics —— 最佳架构参考（C#，不能直接用）

| 项目信息 | 值 |
|---|---|
| 仓库 | https://github.com/cty41/wooftactics |
| 星标 / Fork | 1 / 1 |
| 最后提交 | 2026-10-27（活跃） |
| 许可证 | **Apache-2.0**（代码/文档），游戏资产 CC BY 4.0，名称/Logo 有商标限制 |
| 引擎/语言 | Godot 4.7.1 Mono / C# / .NET 9；Windows + Git LFS |
| 规模 | 60 MB，`src/` 227 个 + `godot/src/` 161 个 `.cs`（`Tactics.Core` 约 9,200 行） |

**它是什么：** 一个**回合制战术肉鸽游戏**（Pure Run）：固定三人小队，穿越 7 层「战斗/精英/休整/商店/神秘/宝箱/Boss」节点，局内组合技能/属性/装备/消耗品并挑战最终 Boss；确定性格子战斗、行动顺序、技能效果、状态、敌人 AI、存档检查点，以及 NUnit/Frozen Oracle/GdUnit/Gameplay Specs 多层测试链。

**为什么对本项目价值最高（架构层面）：**

- **分层与本项目技术方案几乎一致**：
  - `Tactics.Core`：纯 .NET 9 玩法规则、确定性 RNG、Battle/Run 状态，**不依赖 Godot**；
  - `Tactics.Application`：用例、内容编译、存档/运行时投影；
  - `godot/src/Tactics.Godot.Adapter`：Node/Resource/Scene/UI/输入/表现。
  - 这正是我们 docs/03 中「模拟层（纯逻辑、可无头测试）↔ 表现层（订阅事件）」的成熟范例。
- **确定性设计可直接照搬思路**：
  - `DeterministicRandom`：SplitMix64 流，算法与常量被视为「回放契约」，变更需 schema 迁移 → 我们可用同样方式固定 GDScript 版 RNG；
  - `InitiativeOrder.Sort`：按 initiative 降序 + player + spawn ordinal + unit id 逐个 tie-breaker → 解决「同分排序不稳定」问题；
  - `DeterministicDijkstraPathfinder`：4 邻域确定性 Dijkstra，邻居顺序固定（右、左、上、下），等代价用固定堆比较 → 我们的房间内寻路可移植；
  - `BattleCommand → BattleTransitionService → BattleEvent`：命令-过渡-事件模型，状态不可变快照，便于回放/测试 → 我们回合管线可参考；
  - `AiDecisionService`：枚举「原地/移动后/移动+技能」的规范过渡候选再打分 → 我们敌人 AI 可参考（比行为树更适合「环境规则」决策）；
  - `PureRunModels`：Run 节点/阶段/结算/护送等模型 → 我们单局结构可参考。
- **测试范式**：Frozen Oracle + golden vectors + 固定种子战斗探针 → 正好解决我们「组合效果回归难」的问题。

**不能直接用的原因：**

1. **C# + .NET 9 + Windows + Git LFS**，与已选定的 GDScript/GDScript-only 原型栈不同；C# 版 Godot 需要 Mono 构建，团队与 CI 成本更高；
2. 项目仅 1★、处于原型阶段、以 Windows 为主；直接拿来当依赖不现实；
3. 它是「单房间棋盘战斗 + 线性节点冒险」，**没有房间构筑与邻接环境传导**，核心玩法仍要自研；
4. 许可证 Apache-2.0 允许商用与修改，但移植代码需保留 NOTICE 与许可证声明，且资产为 CC BY 4.0（需署名，且项目商标不可用）。

**建议：** 作为**首选架构参考**。首版无需引入 C#，而是：
- 移植/改写约 200–400 行关键算法到 GDScript：SplitMix64、确定性排序、4 邻域 Dijkstra/LOS、候选枚举式 AI；
- 把「命令 → 过渡 → 事件」和「纯 Core + Adapter」写进我们的 M0/M2 代码规范；
- 如果未来性能/工程复杂度需要，再评估是否切换 C#（目前不必要）。

---

### 2.6 sanskar —— 无效输入

https://github.com/sanskar 是一个 GitHub **用户主页**，页面明确显示「**sanskar doesn't have any public repositories yet**」。无法作为项目评估。

**需要确认：** 是否本意是另一个用户名/仓库（例如某人的 Godot 项目）？请提供正确链接，我再补调研。

---

## 3. 星标列表与 `topics/godot` 分析

### 3.1 `ruijayfeng/lists/game`（公开列表，18 个仓库）

抓取结果：该列表共 18 个仓库，**以引擎、工具、AI 开发基建为主**，没有「房间规则/空间构筑/回合战术玩法」项目：

| 仓库 | 星标 | 定位 | 对本项目 |
|---|---|---|---|
| godotengine/godot | ~100k | 引擎本体 | 必需（引擎） |
| Donchitos/Claude-Code-Game-Studios | 29k | Claude Code 游戏开发工作流（49 agents） | △ 工具链参考 |
| htdt/godogen | 7.2k | AI 自动开发 Godot 游戏（Claude/Codex） | △ 工具链参考 |
| Coding-Solo/godot-mcp | 6.4k | Godot 编辑器 MCP 自动化 | △ 工具链 |
| Calinou/awesome-godot | 11k | Godot 资源/插件索引 | ★ 发现渠道 |
| bitbrain/beehave | 3.3k | 行为树 AI（Godot 4.7，MIT） | ○ 敌人 AI 备选 |
| focus-creative-games/luban | 4.6k | 配置表方案（C#，Excel → 代码/数据） | △ 若走 Excel 配表再考虑 |
| nathanhoad/godot_dialogue_manager | 3.9k | 对话系统 | △ 叙事（非核心） |
| ramokz/phantom-camera | 3.6k | 相机（Cinemachine 风格） | △ 固定房间相机用不上 |
| TokisanGames/Terrain3D | 4.5k | 3D 地形 | ✗ 2D 项目 |
| Revolutionary-Games/Thrive | 3.8k | 大型 C# 游戏 | ✗ 参考价值低 |
| Redot-Engine/redot-engine | 6.2k | 引擎 fork | ✗ 不建议 |
| godotengine/godot-cpp、godot-rust/gdext | 2.8k / 5.3k | C++/Rust 绑定 | ✗ GDScript 项目不需要 |
| liangxiegame/QFramework | 5.5k | Unity/Godot 架构框架（C#） | ✗ 技术栈不符 |
| heroiclabs/nakama | 14k | 多人后端 | ✗ 单机游戏 |
| 0xFA11/MultiplayerNetworkingResources | — | 多人网络资料 | ✗ 单机游戏 |
| godotengine/godot-docs | — | 官方文档 | ★ 查文档 |

**结论：** 该列表更适合「引擎/工具/AI 工作流」参考，不覆盖玩法框架；其中对项目开发真正有用的只有 beehave（AI）与 godogen/godot-mcp/awesome-godot（工具与发现）。

### 3.2 `topics/godot`

话题页展示的是 Godot 生态「最热门」项目（Pixelorama、Terrain3D、Dialogic、beehave 等），**是编辑器/插件/引擎类项目榜，不是玩法系统检索入口**。

**结论：** 话题页适合了解生态，不适合找「房间规则/回合战术」类项目；应使用 `topic:godot <关键词>` 搜索（本报告第 4 章就是这样发现的）。

---

## 4. 额外值得关注的项目（补充检索结果）

以下按与项目的相关系统分类，均已核对许可证与 Godot 版本（星标/提交时间为 2026-10-30 近似值）。

### 4.1 回合制战术 / 网格移动

| 项目 | 星标 | 许可证 | Godot | 最后提交 | 可复用内容与结论 |
|---|---|---|---|---|---|
| [theshaggydev/unto-deepest-depths-prototype](https://github.com/theshaggydev/unto-deepest-depths-prototype) | 165 | MIT | 4.2 | 2025-05-20 | 回合制游戏核心循环的**早期 POC**（仅 14 个脚本/565 行），配套著名开发日志「How I structure turn-based games in Godot 4」。代码量太小，**参考架构与文章**，不直接复用 |
| [gdquest-demos/godot-2d-tactical-rpg-movement](https://github.com/gdquest-demos/godot-2d-tactical-rpg-movement) | 186 | 代码 MIT / 美术 CC-BY-NC-SA | 4.x | — | 网格移动 + 寻路 + 范围高亮教学 demo。**代码可商用借鉴**，美术资源不可商用（需替换） |
| [MeshLabDev/Grid-Tactics-Foundation](https://github.com/MeshLabDev/Grid-Tactics-Foundation)（Grid Tactics Lite） | 4 | MIT | 4.6 | 2026-06-28 | **708 行即插即用格子战术核心**：A* 寻路、移动范围、点击移动、Shift 路径点、信号解耦、自带 headless 测试。**最适合改造房间内移动**；完整版（付费）另有回合系统/战斗/LOS |
| [statico/godot-roguelike-example](https://github.com/statico/godot-roguelike-example) | 45 | MIT | 4.6 | 2026-01-29 | Godot 4 肉鸽示例：视野、背包、BSP 地牢生成。可参考肉鸽基础系统与探索层 |
| [bpachter/TILLY](https://github.com/bpachter/TILLY) | 3 | MIT | 4.6 | 2026-08-17 | 战术太空肉鸽，含确定性 Xorshift128+ RNG。可参考确定性随机；项目很新 |

### 4.2 肉鸽单局结构 / 构筑 UI（房间蓝图卡牌化）

| 项目 | 星标 | 许可证 | Godot | 最后提交 | 可复用内容与结论 |
|---|---|---|---|---|---|
| [DesirePathGames/Slay-The-Robot](https://github.com/DesirePathGames/Slay-The-Robot) | 293 | MIT | 4.6 | 2026-08-28 | **较完整的类《杀戮尖塔》框架**（333 个脚本）：卡牌/手牌/动作生成/节点地图/遗物/商店等。**参考构筑 UI 与单局流程**；架构偏 autoload 重，不适合整体嵌入空间构筑游戏 |
| [guladam/deck_builder_tutorial](https://github.com/guladam/deck_builder_tutorial) | 456 | MIT | 4.3 | 2024-10-16 | 类《杀戮尖塔》教学工程（122 脚本）：Run 地图、卡牌 UI 状态机、遗物、商店、篝火。**最适合参考「构筑节点/奖励/商店/休整」流程与卡牌交互** |
| [insideout-andrew/deckbuilder-framework](https://github.com/insideout-andrew/deckbuilder-framework) | 60 | MIT | 4.3 | 2024-12-16 | 卡组/发牌/洗牌等通用卡牌框架插件；可参考「房间蓝图卡牌」的 UI 行为 |
| [baozha2023/Null-Pointer](https://github.com/baozha2023/Null-Pointer) | 1 | **GPL-3.0** | 4.6 | 2026-07-22 | 中文卡牌 Roguelike（数据驱动、Action 栈结算、确定性随机）。**仅思路参考，GPL 代码不要并入闭源项目** |
| [JavierIslas/Card-Combat-System](https://github.com/JavierIslas/Card-Combat-System) | 16 | **AGPL-3.0** | 4.6+ | 2026-10-23 | Headless 卡牌战斗引擎；**AGPL 有传染性，代码不要并入** |

### 4.3 规则 / 效果 / 能力系统（用于借鉴「配方/效果」写法）

| 项目 | 星标 | 许可证 | Godot | 说明 |
|---|---|---|---|---|
| [LiGameAcademy/godot_ability_system](https://github.com/LiGameAcademy/godot_ability_system) | 25 | MIT | 4.x | 高内聚、低耦合的 GDScript 能力系统插件，2026-10 活跃。**可参考「数据驱动效果组合」的接口设计**；它面向角色能力，不是房间环境 |
| [AGomnes/Cantrip](https://github.com/AGomnes/Cantrip) | 6 | MIT | 无（C#/NuGet） | 卡牌/状态/遗物/敌人的**规则 DSL + 编译引擎**（写几行文本代替写类）。思路很接近「房间规则用数据描述」，但语言/平台不匹配，**仅概念参考** |
| [yulrun/godot-gas](https://github.com/yulrun/godot-gas) | 111 | **无许可证（All rights reserved）** | 4.x | 仿 Unreal GAS 的 Godot 实现；**无许可证不可复制代码**，只能读思路 |
| [OctoD/godot-gameplay-abilities](https://github.com/OctoD/godot-gameplay-abilities) | 77 | MIT | 4.x（C++） | C++ GDExtension 能力系统；GDScript 原型不引入 |
| [ClarkWain/godot-arpg-kit](https://github.com/ClarkWain/godot-arpg-kit) | 17 | MIT | 4.5+ | 状态/技能/掉落的数据驱动实现（见 §2.4） |

### 4.4 程序化生成（房间内部/地牢）

| 项目 | 星标 | 许可证 | Godot | 说明 |
|---|---|---|---|---|
| [AlexeyBond/godot-constraint-solving](https://github.com/AlexeyBond/godot-constraint-solving) | 466 | MIT | 4.4 | WFC + CSP（见 §2.2） |
| [TreacherousDev/Treacherous](https://github.com/TreacherousDev/Treacherous) | 53 | MIT | 4.2 | 基于「概率上下文敏感树自动机」的格子程序化生成（地牢/洞窟）；可作为房间内部地形生成实验 |
| [gdquest-demos/godot-4-pcg-basic-dungeon](https://github.com/gdquest-demos/godot-4-pcg-basic-dungeon) | 3 | 代码 MIT / 美术 CC-BY-NC-SA | 4.7 | GDQuest 的 PCG 基础地牢 demo；教学参考 |

### 4.5 AI / 工具链

| 项目 | 星标 | 许可证 | 说明 |
|---|---|---|---|
| [bitbrain/beehave](https://github.com/bitbrain/beehave) | 3.3k | MIT | Godot 4.7 行为树 AI（来自你的星标列表）。敌人 AI 复杂化后可引入；但本项目更推荐「枚举候选+打分」的效用式 AI（wooftactics 做法），与「利用房间环境」的决策更匹配 |
| [htdt/godogen](https://github.com/htdt/godogen) | 7.2k | MIT | AI 自动开发 Godot 游戏（Claude Code/Codex）——可作为开发流程参考，不是游戏代码 |
| [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) | 6.4k | MIT | Godot 编辑器 MCP 自动化，可辅助 AI 工作流 |
| [Calinou/awesome-godot](https://github.com/Calinou/awesome-godot) | 11k | CC0 类 | 官方生态索引，后续找插件的第一入口 |

---

## 5. 与《折叠地牢》系统的映射矩阵

| 游戏系统（对应 docs/01-03） | 最相关开源项目 | 关系 | 评级 | 说明 |
|---|---|---|---|---|
| 5×5 宏观房间图 / 门连接 / 旋转校验 | **Atrium** | 借鉴数据模型与校验不变量 | ★★★★☆ | 2D 重写，不直接用 3D 插件 |
| 房间放置/替换事务与诊断 | Atrium（RoomValidationReport/锁/覆盖） | 借鉴 | ★★★★☆ | 诊断码、先校验后提交 |
| 房间内部 Tile 布局生成 | constraint-solving / Treacherous | 备选实验 | ★★☆☆☆ | WFC 无全局连通保证；MVP 可先手写 6 房间模板 |
| 房间内网格移动 / 寻路 / 范围 | **Grid Tactics Lite**、GDQuest movement demo | 改造复用 | ★★★★☆ | 708 行 MIT，适合 fork；需扩展跨房间门 |
| 回合制战斗 / 技能 / 状态 / AI | **wooftactics**（架构）、arpg-kit（状态）、beehave（AI 备选） | 参考/移植 | ★★★★☆ | 命令-过渡-事件、确定性 RNG、候选枚举 AI |
| 单局结构（楼层/节点/奖励/商店/休整/Boss） | **wooftactics PureRun**、Slay-The-Robot、deck_builder_tutorial | 参考 | ★★★☆☆ | 节点图与 UI 流程可参考；Boss 需自研 |
| 构筑 UI（房间蓝图卡牌化/预览/费用） | Slay-The-Robot、deck_builder_tutorial、insideout deckbuilder-framework | 参考 | ★★★☆☆ | 卡牌交互/费用/预览可参考；空间放置 UI 自研 |
| **房间规则组合 / 邻接联动 / 环境传导 / 折叠** | **无** | **必须自研** | — | 未发现同类项目；这是我们方案的护城河 |
| 数据驱动数据资源（房间/配方/敌人） | arpg-kit、Cantrip（概念） | 借鉴 | ★★★☆☆ | 全部 Resource（.tres）+ 校验 |
| 确定性 / 回放 / 测试 | **wooftactics**（Frozen Oracle）、arpg-kit（测试基建） | 借鉴 | ★★★★☆ | SplitMix64、tie-breaker、黄金回放 |
| 房间内部视觉/相机 | 无必需 | — | — | 固定房间相机，phantom-camera 不需要 |
| 叙事/对话 | godot_dialogue_manager | 后续可选 | ★☆☆☆☆ | 非核心 |

### 必须自研、没有捷径的三块

1. **环境规则引擎**：通道状态 + 排放 + 相邻传导 + 反应配方 + 状态（火/毒/冷/充能）→ 见 `docs/03` §4–5；
2. **空间联动与折叠**：虚拟邻接边、跨房间投射物/传播、折叠权 → 全生态未发现同类实现；
3. **构筑预览 / 危险图 / AI 预判**：同一次「状态快照 + 预演」同时服务 UI、AI、测试 → 需自研 core API。

---

## 6. 推荐整合方案（按系统落地）

### 6.1 宏观房间图与门连接（M0，对应 Atrium 借鉴）

- **借鉴 Atrium：** `stable_id` 标识、`cell: Vector2i` 坐标、双向门记录（from/to room + wall）、连接与门的校验、连通性/越界/重叠检查、`RoomValidationReport` 式诊断码、固定种子生成、环路计数公式。
- **2D 简化：** 我们固定 9×7 房间、共享墙门格、不需要走廊路由/自由朝向/多层；Atrium 的 719 行 planner 中大部分 3D/空间嵌入逻辑可以丢弃，核心算法（关键路径 + 分支 + 环路 + 预算重试 + 校验）约 300–500 行可重写。
- **不要引入 addon**：它是 3D 编辑器工具；引用其仓库作为参考，复制少量 MIT 代码时保留版权声明。
- **对应我们文档：** `docs/03` §5.1/§4.1；评审提出的「9×7 旋转几何」问题也可借 Atrium 的「一条边两个对端嘴（socket）」不变量来修正。

### 6.2 房间内移动与战术层（M1/M3，对应 Grid Tactics Lite）

- 以 [Grid Tactics Lite](https://github.com/MeshLabDev/Grid-Tactics-Foundation) 的 `TacticsGrid/TacticsController/TacticsUnit` 为起点（708 行，MIT，信号解耦、A*、移动范围、路径点、headless 测试）；
- 改造点：9×7 单房间网格 → 跨房间门连接（离开房间边界时切换到相邻房间的入口格）、回合行动经济（移动+攻击）、房间环境危害格（毒/火/减速）接口；
- 用 GDQuest 的 movement demo 交叉学习（代码 MIT；美术资产许可需替换）。

### 6.3 回合制战斗架构（M2/M3，对应 wooftactics）

- 采用其 **命令 → 过渡 → 事件** 模型：`BattleCommand`（移动/攻击/技能）→ `BattleTransitionService`（纯函数状态迁移）→ `BattleEvent`（表现层消费）；
- 移植 **SplitMix64 确定性 RNG**（约 30 行 GDScript）+ **Initiative 排序 tie-breaker** 规则；
- 移植 **4 邻域确定性 Dijkstra / LOS** 思路（约 100–200 行）；
- 敌人 AI：采用其 `AiDecisionService` 的「候选状态枚举 + 打分」结构；把「站到有利房间/把玩家推入毒雾」编码成评分项；
- 用其 **Frozen Oracle / 黄金回放** 思路建立「固定种子 → 固定事件序列」回归测试（组合效果最需要）；
- 若未来切换 C#，其 Core 可成为参考基线；当前 GDScript 栈保持不变。

### 6.4 肉鸽单局结构（M4，对应 wooftactics/Slay-The-Robot/deck_builder_tutorial）

- 节点类型与流程直接参考 wooftactics 的七层节点（战斗/精英/休整/商店/神秘/宝箱/Boss）；
- 构筑节点/奖励三选一/商店/篝火的 UI 流程参考 deck_builder_tutorial 与 Slay-The-Robot；
- **不要照搬**它们的卡牌数值/Action 栈，我们的「房间蓝图 + 空间放置 + 资源约束」是另一套构筑；只借 UI/流程/节点图数据化思路。

### 6.5 数据驱动与测试基建（贯穿）

- 房间/配方/敌人全部自定义 `Resource`（参考 arpg-kit 的 `.tres` 组织方式与导出字段风格）；
- 自研极简 headless 测试运行器（`SceneTree` 子类），参考 arpg-kit 的测试场景 + CI 汇总模式；
- 添加「固定种子事件日志回放」测试，参考 wooftactics 的 Frozen Oracle 概念；
- 所有外部项目仅用于**参考与少量 MIT 代码移植**，不引入其运行时代码为依赖（避免版本/许可/架构耦合）。

### 6.6 工具链（可选、不影响玩法）

- **godogen / godot-mcp**：AI 辅助开发自动化（跑 Godot、抓输出、截图）——与我们的 AI 工作流契合；
- **awesome-godot**：后续找插件的第一入口；
- **luban**：若未来需要 Excel 配表管线再考虑（当前 `.tres` 足够）。

---

## 7. 许可证与合规风险

| 许可证 | 项目 | 义务 | 对本项目 |
|---|---|---|---|
| MIT | Atrium、constraint-solving、infinite_worlds、arpg-kit、Grid Tactics Lite、UDD、deck_builder_tutorial、statico、Slay-The-Robot、beehave、Treacherous、insideout deckbuilder、LiGameAcademy ability system、Cantrip、godogen、godot-mcp | 保留版权与许可证声明 | ✅ 可商用、可修改、可移植 |
| Apache-2.0 | **wooftactics**（代码/文档） | 保留 LICENSE/NOTICE、标注修改、专利条款 | ✅ 可商用；若移植代码必须附 NOTICE 与说明 |
| CC BY 4.0 | wooftactics 游戏资产 | 署名 cty41；资产单独许可 | ⚠️ 只取代码架构即可，避免依赖其美术 |
| GPL-3.0 | Null-Pointer | 衍生作品须 GPL 开源 | ❌ 闭源项目不要复制代码 |
| AGPL-3.0 | JavierIslas/Card-Combat-System | 网络使用也触发开源义务 | ❌ 不并入 |
| 无许可证 | yulrun/godot-gas | 默认保留所有权利 | ❌ 不可复制代码，只能读思路 |
| 代码 MIT + 美术 CC-BY-NC-SA | GDQuest demos（tactical movement / PCG dungeon） | 代码可商用；美术**非商业**且需署名 | ⚠️ 只用代码/思路，替换美术资源 |
| CC0 / 其他 | 引擎、字体等 | 按各自条款 | ✅ |

**工程层面的「不可用」与法律无关：**

- **C# 项目**（wooftactics、Cantrip、QFramework、Thrive）：与 GDScript 栈不同，不能直接引用；只能移植算法/借鉴架构（移植 Apache/MIT 代码需保留声明）。
- **C++ 项目**（OctoD GAS、Terrain3D、godot-cpp）：需要 GDExtension 构建链，原型期不引入。
- **3D 项目**（Atrium、Terrain3D）：模型/渲染/物理假设与 2D 俯视角不同，不能直接复用运行时代码。
- **旧引擎版本**（infinite_worlds 4.2、Treacherous/UDD 4.2、deckbuilder 4.3、constraint-solving 4.4）：**实测导入 Godot 4.7.2 均无解析错误**，但 API/行为仍需运行时验证；infinite_worlds 使用 legacy `TileMap`，未来迁移到 `TileMapLayer` 有成本。

---

## 8. 结论与下一步

### 8.1 结论

1. **核心技术没有现成项目**：房间规则/邻接联动/空间折叠/构筑预览必须自研——这与我们 `docs/01–03` 的判断一致，也说明现有设计方向没有可抄的近路。
2. **值得投入时间研究的两个项目**：**Atrium**（宏观房间图/门/校验/确定性生成）与 **wooftactics**（确定性回合制/肉鸽架构/测试范式）。前者 MIT 可借鉴代码，后者 Apache-2.0 可移植算法（C#→GDScript）。
3. **可以直接改造用的两个项目**：**Grid Tactics Lite**（房间内移动，MIT，708 行）与 **constraint-solving**（房间内部布局实验，MIT，按需）。
4. **构筑/肉鸽 UI 有成熟参考**：Slay-The-Robot、deck_builder_tutorial，参考流程与交互，不照搬数值。
5. **用户星标列表与 topics/godot 不足以覆盖玩法框架**，需按「topic:godot + 关键词」检索；本次补充检索已给出候选清单。
6. **许可证方面**：MIT/Apache 项目可安全借鉴/移植（保留声明）；GPL/AGPL/无许可证项目只可读思路。

### 8.2 建议的下一步（按优先级）

| 优先级 | 动作 | 产出 | 预估 |
|---|---|---|---|
| P0 | 按 `docs/03` 修好评审阻塞项后启动 M0；M0 直接采用 Atrium 式房间图数据模型（`stable_id`/`cell`/双向门/诊断报告/固定种子） | 可无头测试的 5×5 房间图 + 放置/旋转/连通校验 | 1–2 天 |
| P0 | 阅读 wooftactics 的 `Tactics.Core` 关键文件（DeterministicRandom / InitiativeOrder / BattleTransitionService / AiDecisionService / PureRunModels），写成我们的「回合管线规范」 | 确定性回合/战斗架构规范 | 0.5 天 |
| P1 | 用 Grid Tactics Lite 改造 9×7 房间内移动原型（A*、范围高亮、跨门切换） | M1 移动原型 | 1–2 天 |
| P1 | 参考 deck_builder_tutorial 的 Run 地图/卡牌 UI，设计「房间蓝图卡 + 构筑节点」交互原型 | 构筑 UI 草图/原型 | 1–2 天 |
| P2 | 用 constraint-solving 做「房间内部地形生成」实验（9×7、带危险/障碍） | 实验结论：是否值得引入 | 1–2 天 |
| P2 | 将 wooftactics 的 Frozen Oracle/黄金回放思路落到我们的测试框架 | 确定性回归测试 | 0.5 天 |

### 8.3 需要你确认的问题

1. **sanskar 链接**：原意是哪个用户/仓库？（当前链接无公开仓库）
2. **是否接受「自研核心 + 借鉴/移植周边」路线**？（本报告推荐；也是唯一现实路线）
3. **是否允许在后续 POC 中移植 MIT/Apache 代码片段**（保留版权/NOTICE）？还是只「参考重写」？
4. 是否需要在第二阶段做「wooftactics 架构移植评估」与「Atrium 2D 抽取」的深度代码级验证？

---

## 附录 A：项目元数据总表（2026-10-30）

| 项目 | 星标 | 许可证 | Godot | 最后提交 | 规模 | 4.7.2 导入实测 |
|---|---|---|---|---|---|---|
| Dragonboon/Atrium | 85 | MIT | 4.7.2 | 2026-10-16 | 2.4 MB / 79 gd | ✅ 无解析错误 |
| AlexeyBond/godot-constraint-solving | 466 | MIT | 4.4 | 2025-05-13 | 26 MB / 90 gd | ✅ |
| Lommix/infinite_worlds | 27 | MIT | 4.2 | 2023-11-30 | 5.7 MB / 13 gd | ✅（legacy TileMap） |
| ClarkWain/godot-arpg-kit | 17 | MIT | 4.5+ | 2026-10-10 | 2.5 MB / 82 gd | ✅ |
| cty41/wooftactics | 1 | Apache-2.0 | 4.7 Mono/C# | 2026-10-27 | 60 MB / 388 cs | ⚠️ 未测（需 .NET 9） |
| theshaggydev/unto-deepest-depths-prototype | 165 | MIT | 4.2 | 2025-05-20 | 0.6 MB / 14 gd | ✅ |
| MeshLabDev/Grid-Tactics-Foundation | 4 | MIT | 4.6 | 2026-06-28 | 1.6 MB / 708 行插件 | ✅ |
| guladam/deck_builder_tutorial | 456 | MIT | 4.3 | 2024-10-16 | 44 MB / 122 gd | ✅ |
| DesirePathGames/Slay-The-Robot | 293 | MIT | 4.6 | 2026-08-28 | 5.4 MB / 333 gd | ✅ |
| gdquest-demos/godot-2d-tactical-rpg-movement | 186 | MIT 代码 / NC 美术 | 4.x | — | — | 未克隆（仅读 README/许可） |
| statico/godot-roguelike-example | 45 | MIT | 4.6 | 2026-01-29 | — | 未克隆 |
| bitbrain/beehave | 3.3k | MIT | 4.7 | 2026-09-20 | — | 未克隆 |
| TreacherousDev/Treacherous | 53 | MIT | 4.2 | — | — | 未克隆 |
| insideout-andrew/deckbuilder-framework | 60 | MIT | 4.3 | 2024-12-16 | — | 未克隆 |
| bpachter/TILLY | 3 | MIT | 4.6 | 2026-08-17 | — | 未克隆 |
| LiGameAcademy/godot_ability_system | 25 | MIT | 4.x | 2026-10-25 | — | 未克隆 |
| yulrun/godot-gas | 111 | 无许可 | 4.x | 2026-10-13 | — | 未克隆 |
| OctoD/godot-gameplay-abilities | 77 | MIT | 4.x C++ | 2026-01-19 | — | 未克隆 |
| AGomnes/Cantrip | 6 | MIT | C#/NuGet | 2026-10-05 | — | 不适用 |
| baozha2023/Null-Pointer | 1 | GPL-3.0 | 4.6 | 2026-07-22 | — | 未克隆 |
| JavierIslas/Card-Combat-System | 16 | AGPL-3.0 | 4.6+ | 2026-10-23 | — | 未克隆 |

## 附录 B：兼容性测试方法

```bash
# 本地 Godot 4.7.2（macOS universal）；在仓库根目录执行
GD="$(git rev-parse --show-toplevel)/.tools/Godot.app/Contents/MacOS/Godot"
export HOME="$(git rev-parse --show-toplevel)/.research/home"   # 让 Godot 的用户目录可写（沙箱）
$GD --headless --path .research/repos/<repo> --editor --quit
# 判定：输出中无 SCRIPT ERROR / Parse Error（导入解析通过；不代表运行时正确）
```

> 说明：未替换 `user://` 路径时，Godot 会因沙箱无法写 `~/Library` 报错但项目仍可解析；本测试通过 `HOME` 重定向到工作区，避免该干扰。

## 附录 C：检索关键词（可复用）

- 宏观/房间：`topic:godot dungeon`, `godot room based procedural`, `godot dungeon generator procedural`
- 回合战术：`godot turn based tactics`, `godot tactical rpg`, `godot grid combat rpg`, `godot tactical roguelike`
- 肉鸽/卡牌：`topic:godot roguelike`, `godot roguelike deckbuilder`, `godot card game framework`, `godot slay the spire framework`
- 规则/能力：`godot gameplay ability system`, `godot ability system`, `godot effect system data driven`, `godot data driven combat framework`
- 程序生成：`topic:godot procedural-generation`, `godot wfc wave function collapse`
- 确定性：`godot deterministic rng roguelike`

## 附录 D：数据与局限

- stars/forks 为 2026-10-30 shields.io 抓取快照；GitHub API 核心配额耗尽，改用 HTML/本地 git。
- 兼容性测试只验证「导入解析无脚本错误」，未验证插件运行、场景加载、玩法功能。
- 克隆源码保存在 `.research/repos/`（约 150 MB，非交付物；可删除）。
- 星标列表是公开的（18 个仓库已全部解析）；`topics/godot` 只取首屏热门仓库。
- `sanskar` 用户无公开仓库，无法评估。
