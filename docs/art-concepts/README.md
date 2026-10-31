# D11 美术方向概念图

同一场战斗场景（9×9 房间：熔炉 600 热、毒雾 200、2 只怪物、5×5 侧栏地图），三种视觉语言，仅用于方向选型，**不是最终美术**，也未接入游戏。

| 文件 | 方向 | 一句话 |
|---|---|---|
| `style-a-pixel.png` | A · 像素地牢 | 16×16 石砖地牢、火把暖光、毒雾抖动纹理、像素小人/怪物、木门金光 |
| `style-b-tactical.png` | B · 战术极简 | 低饱和暗色、细网格、几何单位、虚线可达格、意图箭头、斜线危险区 |
| `style-c-paper.png` | C · 手绘剪影 | 羊皮纸底、墨线房间、剪影角色、水彩毒雾、火盆暖光 |

- 概念图为手写 SVG（本项目原创，Apache-2.0）渲染而成，源码见同目录 `*.svg`。
- 场景与生成脚本：`generate_concepts.py`（仅依赖 Python 标准库；用 Chrome headless 渲染截图）。
- 方向调研（资产/许可/工作量）见 [`research/03-美术方向与资产复用调研.md`](../../research/03-美术方向与资产复用调研.md)。
- 选型记录待补充到 [`docs/07-美术方向与占位说明.md`](../07-美术方向与占位说明.md)。

重渲染示例：

```bash
python3 docs/art-concepts/generate_concepts.py
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --no-sandbox \
  --screenshot=docs/art-concepts/style-a-pixel.png --window-size=1200,760 \
  "file://$PWD/docs/art-concepts/style-a-pixel.svg"
```

## 定稿（2026-10-31）

- **游戏内视觉：B · 2.5D 暗黑地牢**（3D 场景 + AI 2D 立绘单位）；**主视觉/封面：D 折叠地牢**。
- 达标房 v1（真引擎渲染）与单位/材质参考：[`targets/2.5d/`](targets/2.5d/)。
- 早期三套 2D 风格概念图（A 像素 / B 战术极简 / C 手绘剪影）与 A/D 概念稿保留在 `targets/`，作为历史记录。
- 设计规范与实施方案：[`docs/09-视觉与手感升级方案（M6）`](../09-视觉与手感升级方案（M6）.md)；任务拆解：[`.agents/plans/2026-10-31-M6-视觉与手感升级.md`](../../.agents/plans/2026-10-31-M6-视觉与手感升级.md)。
