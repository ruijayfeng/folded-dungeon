# 第三方内容声明（Third-Party Notices）

本仓库**自有代码与文档**采用 [Apache License 2.0](LICENSE)。以下内容为第三方组件/材料，其许可**独立于**本仓库整体；完整来源记录（仓库地址、提交号、许可证副本）见 [`research/skills-provenance/PROVENANCE.md`](research/skills-provenance/PROVENANCE.md)。

## 1. `.agents/skills/` 外部 AI 开发技能

| 技能目录 | 来源仓库 | 许可 |
|---|---|---|
| `godot` | [haxqer/godot-skill](https://github.com/haxqer/godot-skill) | MIT |
| `godot-gdscript`、`godot-gdscript-headless-testing`、`godot-resources`、`godot-tilemap`、`ai-behavior-trees-utility-ai` | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Apache-2.0（含 NOTICE） |
| `godot-project-setup`、`gdscript-patterns`、`event-bus`、`state-machine`、`resource-pattern`、`scene-organization`、`godot-code-review`、`godot-debugging`、`procedural-generation`、`godot-ui`、`godot-grill` | [jame581/GodotPrompter](https://github.com/jame581/GodotPrompter) | MIT |
| `godot-genre-roguelike`、`godot-combat-system`、`godot-ability-system`、`godot-economy-system` | [thedivergentai/Game-Dev-Agentic-Skills](https://github.com/thedivergentai/Game-Dev-Agentic-Skills) | LGPL-3.0 |
| `plan-plain`、`project-doc-organization`、`skill-writing` | [cty41/skills](https://github.com/cty41/skills) | MIT |
| `folded-dungeon` | 本项目自写 | Apache-2.0 |

- 各技能的完整许可证文本副本位于 [`research/skills-provenance/licenses/`](research/skills-provenance/licenses/)。
- **清理方式：** 删除 `.agents/skills/<技能目录>/` 即可移除对应第三方内容；剩余项目内技能索引与安装脚本见 `.agents/skills/README.md`、`tools/install-skills.py`。
- 这些技能仅用于 AI 辅助开发，**不参与游戏运行时**（`game/` 工程不依赖它们）。

## 2. `research/` 调研材料

- [`research/01-Godot开源项目调研.md`](research/01-Godot开源项目调研.md)：对公开 GitHub 项目的评估与摘要，仅引用项目名称、链接与许可证信息，**未复制其源代码**。
- [`research/02-设计文档复核记录.md`](research/02-设计文档复核记录.md) 与 `research/skills-provenance/`：本项目原创记录及上述第三方许可证副本。

## 3. 引擎与资源

- 本仓库**不包含** Godot 引擎二进制；运行需自行安装 [Godot Engine 4.7.2](https://godotengine.org/)（MIT 许可）。
- `game/icon.svg` 为本项目自制的占位图标，随本仓库 Apache-2.0 发布。
- **字体**：[Noto Serif SC](https://fonts.google.com/noto/specimen/Noto+Serif+SC)（SIL Open Font License 1.1），子集化后位于 `game/assets/art3d/fonts/`，许可全文同目录 `OFL.txt`。
- **音频**：部分 SFX 来自 [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio)（CC0）、[Kenney UI Audio](https://kenney.nl/assets/ui-audio)（CC0）与 [RPG Sound Pack](https://opengameart.org/content/rpg-sound-pack)（author: artisticdude，CC0）；其余音效与环境 loop 由本项目程序合成（Apache-2.0）。详见 `game/assets/audio/LICENSES.md`，CC0 法律文本见 `game/assets/audio/CC0-1.0.txt`。
- **美术**：2.5D 材质、单位立绘、标题主视觉与 UI 参考由用户配置的 Azure OpenAI 图像模型（`gpt-image-2.5-sunburst`）生成，生成 prompt 存档在 `docs/art-concepts/targets/prompts.md`；使用/发行前需复核对应模型服务条款。
- 早期调试用的 KayKit CC0 模型仅作路线对照，**未进入仓库/最终资产**。

## 4. 参考与借鉴

游戏设计调研参考了 Atrium、wooftactics、Grid Tactics Lite 等开源项目的**公开设计思路**（见 `research/01`），未直接复制其代码；规则引擎与战斗逻辑为本项目自研。
