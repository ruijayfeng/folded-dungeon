# 项目级 AI 开发技能（Project Skills）

> 安装日期：2026-10-30 · 安装位置：`.agents/skills/` · 共 25 个 skill（24 个外部 + 1 个项目自定义）

本目录按 [Agent Skills](https://code.claude.com/docs/en/skills) 标准组织：每个子目录一个 `SKILL.md`（YAML frontmatter + Markdown 指令）。DSH 会在会话中发现并注入技能目录，可通过 Web 输入框 `/` 菜单直接调用，或让 Agent「加载 X skill」。

## DSH 的技能发现路径（实现文档实测）

| 优先级 | 来源 | 路径 |
|---|---|---|
| 100 | project-dsh | `<projectRoot>/.dsh/skills` |
| **200** | **project-agents（本目录）** | **`<projectRoot>/.agents/skills`** |
| 300 | custom | 配置的额外目录 |
| 400 | user-dsh | `$DSH_HOME/skills`（本机 `~/.dsh/skills`） |
| 500 | user-agents | `~/.agents/skills` |

`projectRoot` = 包含 `.git` 的最近祖先目录；本仓库已 `git init`（仓库根 = 本目录），因此 `projectRoot` 即仓库根。若克隆到其他路径，技能仍随仓库生效，无需迁移。本目录随仓库提交到 GitHub；第三方技能许可与清理方式见仓库根 [`THIRD_PARTY_NOTICES.md`](../../THIRD_PARTY_NOTICES.md)。

## 安装清单

| Skill | 来源 | 许可 | 主要用途 |
|---|---|---|---|
| `godot` | [haxqer/godot-skill](https://github.com/haxqer/godot-skill) | MIT | Godot 4.7 无头工作流全家桶：脚手架/场景与资源检查编辑、TileMap、UI、API 查询、lint、测试、导出、ASCII 生成像素画/音效。**SKILL.md 约 82KB，加载成本高，按需使用** |
| `godot-gdscript` | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Apache-2.0 | Godot 4.7 地道 GDScript（类型、生命周期、信号、await） |
| `godot-gdscript-headless-testing` | 同上 | Apache-2.0 | `godot --headless` 测试运行器 + CI 退出码（本项目测试方案基础） |
| `godot-resources` | 同上 | Apache-2.0 | 自定义 Resource、`.tres`、ResourceLoader/Saver |
| `godot-tilemap` | 同上 | Apache-2.0 | TileMapLayer/TileSet/autotile/代码读写格子 |
| `ai-behavior-trees-utility-ai` | 同上 | Apache-2.0 | 行为树 + Utility AI（敌人 AI 参考） |
| `godot-project-setup` | [jame581/GodotPrompter](https://github.com/jame581/GodotPrompter) | MIT | Godot 4.x 工程目录/设置/autoload/.gitignore 脚手架 |
| `gdscript-patterns` | 同上 | MIT | GDScript 模式：静态类型、await、lambda、match、导出注解 |
| `event-bus` | 同上 | MIT | 事件总线/解耦通信（对应本项目 EventBus） |
| `state-machine` | 同上 | MIT | 状态机三种实现与取舍 |
| `resource-pattern` | 同上 | MIT | 数据容器 Resource 模式 |
| `scene-organization` | 同上 | MIT | 场景树组织/组合 vs 继承 |
| `godot-code-review` | 同上 | MIT | GDScript/C# 代码审查清单 |
| `godot-debugging` | 同上 | MIT | 远程调试器/打印/信号追踪/常见错误 |
| `procedural-generation` | 同上 | MIT | 噪声/BSP/元胞自动机/WFC/种子随机（Godot 4.3+） |
| `godot-ui` | 同上 | MIT | Control/主题/锚点/容器布局 |
| `godot-grill` | 同上 | MIT | 设计决策盘问（每轮带推荐答案，落盘决策） |
| `godot-genre-roguelike` | [thedivergentai/Game-Dev-Agentic-Skills](https://github.com/thedivergentai/Game-Dev-Agentic-Skills) | LGPL-3.0 | 肉鸽蓝图：程序生成、永久死亡+局外成长、Run/Meta 状态分离、种子 RNG、遗物、难度曲线 |
| `godot-combat-system` | 同上 | LGPL-3.0 | 战斗：hitbox/hurtbox、DamageData、血量组件、状态机、连击 |
| `godot-ability-system` | 同上 | LGPL-3.0 | 技能/冷却/技能树/资源管理 |
| `godot-economy-system` | 同上 | LGPL-3.0 | 货币/商店/动态定价/掉落表/经济平衡 |
| `plan-plain` | [cty41/skills](https://github.com/cty41/skills) | MIT | 生成可执行计划并强制写「人话版」 |
| `project-doc-organization` | 同上 | MIT | `.agents/docs`/plans/knowledge 文档组织规范 |
| `skill-writing` | 同上 | MIT | 新建/编辑 skill 的规范（渐进披露） |
| `folded-dungeon` | 本项目自写 | — | **本项目上下文**：文档索引、Godot 路径、架构约定、待确认决策、评审阻塞项、技能使用建议 |

### 备注 / 已知限制

- 部分外部 skill 的正文会交叉引用**未安装**的兄弟 skill（如 game-dev-agentic 引用 `godot-composition`）。遇到时以已安装技能为准。
- `game-dev-agentic` 系列为 **LGPL-3.0**：当前仓库公开且项目整体采用 Apache-2.0，但该系列技能仅作开发辅助、不参与游戏运行时；若未来要闭源分发，建议先删除或替换该系列（见仓库根 `THIRD_PARTY_NOTICES.md`）。
- 外部来源与提交号、许可证副本见 `research/skills-provenance/`。
- 技能正文可能要求 `GODOT_BIN` 指向引擎；优先用仓库包装脚本（自动处理 HOME），需要直接指向时：
  ```bash
  export GODOT_BIN="$(git rev-parse --show-toplevel)/.tools/Godot.app/Contents/MacOS/Godot"  # macOS 本地引擎
  ```

## 使用方式

- **DSH Web**：输入 `/` 后选择技能名；或直接说「加载 godot-gdscript-headless-testing」。
- **Agent 自动加载**：任务描述匹配技能 description 时，Agent 会调用 `skill` 工具加载。
- **项目上下文**：任何开发/规划任务先加载 `folded-dungeon`（约 6KB，成本低）。

## 维护 / 升级

```bash
# 方式 A：用安装脚本（推荐；源仓库缓存于 .research/skills-repos，不提交 Git）
python3 tools/install-skills.py --update   # 拉取上游最新并重新拷贝
python3 tools/install-skills.py            # 仅从本地缓存重新安装

# 方式 B：手工更新单个技能
git -C .research/skills-repos/godotprompter pull --ff-only
cp -R .research/skills-repos/godotprompter/skills/godot-debugging .agents/skills/godot-debugging
```

升级后请同步更新上表与 `research/skills-provenance/PROVENANCE.md` 中的提交号。新增技能：在脚本的 `INSTALLS` 列表中加入源路径 → 重新运行。

**移除技能**：直接删除 `.agents/skills/<name>/`（DSH 下次会话/热更新时目录会消失）。项目自定义 `folded-dungeon` 请勿删。

## 自定义项目 skill

`folded-dungeon/SKILL.md` 是本项目专属上下文（设计文档索引、技术约定、Godot 路径、待确认决策、评审阻塞项）。修改后用 `skill-writing` 检查格式，并保持 **< 8KB**（DSH 工具结果修剪阈值约 8192 字符）。
