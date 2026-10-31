# 2.5D 资产生产工具

M6-1 起，游戏内 2.5D 资产全部来自 **AI 生成 + 程序化后处理**，生成结果提交仓库（PNG），脚本不含密钥。

## 生成环境

- 用户本机 Azure OpenAI `gpt-image-2.5-sunburst`（`quality=max`，`1024x1024`）；
- 生成入口为用户环境中的 Sunburst 脚本（读取环境变量，密钥不入仓）；prompt 存档在
  `docs/art-concepts/targets/prompts.md`。

## 后处理

```bash
# 法线贴图（albedo → normal）
python3 game/tools/art/normal_from_albedo.py game/assets/art3d/materials/floor-stone.png

# 单位立绘绿幕抠像 + 裁切
python3 game/tools/art/chroma_key.py raw/player-knight-raw.png game/assets/art3d/units/player-knight.png

# 刷新资产清单
python3 game/tools/art/build_manifest.py
```

## 目录

- `game/assets/art3d/materials/`：albodo + normal（石墙/地砖/木门/皮革/火焰/雾/阴影/血迹/毒雾）
- `game/assets/art3d/units/`：透明立绘（玩家/怪物）
- `game/assets/art3d/manifests/art3d.json`：资产清单（`test_asset_manifest.gd` 校验）
