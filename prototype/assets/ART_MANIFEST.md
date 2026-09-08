# 第一章美术来源

本轮由用户授权采用中式写实插画与AI美术。使用 Codex 内置 imagegen 工具，没有使用图像 API CLI，也没有读取或使用玩家的 API Key。

| 项目资产 | 用途 | 图集布局 |
|---|---|---|
| shop-v2.png | 柜台主场景 | 单张横幅 |
| portraits-v2.png | 8名原创角色 | 4列×2行，从左到右、从上到下 |
| objects-v2.png | 24个物件图像，供28件道具共用 | 6列×4行 |

图像已经复制到本项目，不依赖生成缓存目录。角色和场景并非真实人物或真实店铺；器物图仅作美术表达，不构成现实鉴定资料。

## 生成提示词摘要

原始三次请求没有持久化完整逐字提示词；以下为可复现方向的摘要，不冒充原文。

- 店铺：中式写实绘画，小城古玩店，深木柜台、暖日光、左右陈列架、右侧门口、柜台左下账本；无前景人物，无界面文字或水印。
- 人物：统一暖棕背景和光线、4×2等分图集、八位腰部以上原创人物；依次为朴实中年男街坊、谨慎年轻女顾客、退休女职工、年轻男设计师、年长男同行、女修护师、中年男经纪人、成熟女拍卖征集负责人。
- 器物：6×4等分图集、棕色背景、写实绘画；24种瓷器、文房、书画及杂项小物，单格一件，无界面文字、水印或跨格构图。运行时使用AtlasTexture，不改写生成像素。

## 校核

已检查三张图集与游戏实际画面，按图中天平修正对应道具名称。部分器物共用图像，当前没有每名角色的多表情图集；不能据此声称所有姿态都已制作。

## 第二轮场景与资料（2026-09-05）

均使用Codex内置imagegen，已复制进本项目并接入默认场景，不使用玩家API配置。

- `market-v3.png`：古玩市场街面。沿用上一轮已生成图像；原提示摘要为中式写实古玩街、四家固定店面与散摊、无文字和UI。
- `teahouse-v3.png`：夜间茶馆，生成后检查了月夜门口、前景茶桌和灯光。
- `old-photo-v3.png`：序章虚构旧照，仅用于剧情氛围，不用画中细节直接确定物权或真伪。

茶馆完整提示词：

> Use case: illustration-story. Asset type: background illustration for Chinese antique shop narrative game, night teahouse scene. A quiet traditional Chinese neighborhood teahouse at night, realistic painterly Chinese illustration, aged dark timber, warm amber paper lamps, tea table in foreground with a small teapot and two cups, empty chairs for character portraits to be overlaid by the game, open doorway on right leading to a cool blue moonlit lane, rainy courtyard visible through wood lattice windows. Rich believable material texture, intimate calm atmosphere for talking with acquaintances about antiques. Wide 16:9 landscape, full frame environment, no people, no text, no UI, no watermark. Foreground table and doorway must be clearly readable clickable locations. Keep upper left area subdued for game scene heading.

旧照完整提示词：

> Use case: illustration-story. Asset type: fictional old photograph prop for a Chinese antiques narrative game. A single aged sepia photographic print, photographed straight on, cream deckled photo border with light age marks. The photo shows the counter of a modest old Chinese neighborhood tea shop before a move, small tea tin and an unidentifiable wrapped scroll beside a plain teapot on a wooden counter, wooden tea shelves behind, no people, no readable labels or inscriptions. Realistic archival photographic texture and subtle grain, not drawing. Landscape 4:3 composition. No modern objects, no watermark, no added game UI. Keep objects indistinct enough that it cannot establish authenticity or ownership; this is atmospheric fictional story material.

## 第三轮界面素材（2026-09-06）

为修复人物与器物贴图的矩形背景，新增：

- `portraits-v3.png` / `portraits-v3-alpha.png`：8名角色的4×2图集；运行时使用 alpha 版本。
- `objects-v3.png` / `objects-v3-alpha.png`：24格器物图集；运行时使用 alpha 版本。

两张 v3 原图由 Codex 内置 imagegen 按中式写实插画方向生成。`flatten_checkerboard.py` 按图集单元格清除与边缘相连的中性棋盘格，并输出 RGBA alpha 版本；它是可重复的资产处理步骤，不把生成图中的棋盘格当作游戏背景。新图仍属于原型美术，不承担器物真伪或现实鉴定依据。

## 拍卖场景（2026-09-08）

- `auction-hall-v1.png`：拍卖场景底图。
