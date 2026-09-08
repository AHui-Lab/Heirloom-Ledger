---
title: Immersive Revision Acceptance
status: review
owner: agent
last_reviewed: 2026-09-06
---

# 第二轮沉浸式原型验证

## 2026-09-08场景与对话密度改版

用户确认采用表现流式、抽屉式信息和 6～8 件拍品的拍卖框架。原型现将会面资料、快捷提问与剧情正事默认收起，把聊天保留为右栏主体；请求期间显示“正在思考”，回复完整到达后逐字呈现，玩家消息使用更快的逐字效果，并在显示过程中持续滚动到最新位置。店铺热点取消金色多边形边框，只保留低干扰文字入口；阶段推进移到顶部日期旁；商户与夜间会面使用固定单一返回入口。

拍卖新增独立场景底图、每场 6～8 件图录、关注标记、每件 2～4 名可观察竞买人，以及逐件举牌、放弃本件和提前离场。拍品、竞买上限、资金、费用与物权均由 Game Core 结算。桌面 OpenGL 截图新增 `immersive_auction_preview.png` 与 `immersive_auction_bidding.png`；默认测试不调用外部模型。

## 2026-09-07追加试玩修复验证

根据第二轮实际试玩截图完成以下原型修复：店内场景使用非负明确图层，热点位于背景之上、人物与器物之下；对白展开时隐藏店内热点，避免高亮轮廓遮挡前景。私人判断卡改挂在右侧信息栏，不再覆盖商户库存。会面资料默认折叠，快捷问题放入有限高度的独立滚动区。商户详情按钮统一为“查看物品 · 形成私人判断”；玩家一句话提到多个商户商品时不自动猜测目标，而是要求先点击商品卡片。无剧情拜访改为一次性短对白，剧情夜谈保留点击式正事选择，输入框提示仅用于闲聊与回顾。

桌面 OpenGL 截图已复核：店内对白展开、市场总览、商户三列库存、商户物件详情和夜间剧情场景均正常渲染。全量 `prototype/run_checks.ps1` 通过，未进行外部模型调用。剧情内容的吸引力、故事节点对白质量和真实模型长期一致性仍属于后续试玩事项。

## 2026-09-06追加修复验证

修复上午最后一位来客离开后推进按钮跟随对话容器隐藏的问题。按钮改为独立流程控件，测试使用 `is_visible_in_tree()` 与实际按钮点击覆盖午间、市场往返和十日闭店。旧测试只检查自身 `visible`，不足以证明玩家可操作，已替换。

市场改为背景店铺/摊位轮廓与招牌入口；悬停显示简介、主营和推荐商品。进入商户默认收起对话，商品使用大面积三列网格。详情顶部显示鉴定、个位整数报价与还价入口；UI测试点击鉴定、输入金额、出价、确认，验证库存转移及精确扣款。Core库存重入/存读档不刷货和重复交割保护继续覆盖。

多份模型配置按名称存于Windows受保护文件中；设置一键切换，兼容原有单配置。虚构配置A/B测试验证选中模型与对应Key恢复、请求中禁止切换。Kimi Code模板基于官方资料，尚未做该服务真实联调；账户适用范围和产品API区别见README。

本轮已成功使用桌面OpenGL渲染，以下新截图取代上轮“未完成视觉检查”的限制：`immersive_noon_progression.png`、`immersive_market.png`、`immersive_merchant.png`、`immersive_merchant_appraised.png`。对白为本地模拟。背景沿用现有原画，轮廓与招牌由界面绘制；不是新生成的独立商铺室内画。

Changed Files：`immersive_main.gd`、`scene_hotspot.gd`、`immersive_core.gd`、`profile_settings.gd`、`test_immersive_ui.gd`、`capture_immersive_ui.gd`、上述截图、README与项目记录。未修改正式src。

本地实现已接入默认启动入口，真实模型对白验收尚未完成。此页不是设计锁定，也不代表整个目标已完成。

## Changed Files

- `prototype/scripts/immersive_main.gd`、`immersive.tscn`、`project.godot`：左右对白卡、私人判断与经营记录分离、齿轮与场景热点、鼠标附近提示、可折叠对白、会面摘要、历史开关、市场双列卡片、商户库存、夜间交谈、资料与疑问笔记。
- `prototype/scripts/immersive_core.gd`、`data/immersive_content.json`：商户独立物件、每天固定的随机摊位、同日会面状态、逐人物原话、明确交割、显式共同看货、调查条件。
- `prototype/scripts/scene_hotspot.gd`、`prototype/tools/flatten_checkerboard.py`：低干扰场景热点样式、键盘聚焦和透明素材处理步骤。
- `profile_store.gd`、`profile_settings.gd`、`tools/protected_profile.ps1`：Windows当前用户保护保存、恢复、删除配置；可保存联调许可，启动不自动联调。
- `assets/market-v3.png`、`teahouse-v3.png`、`old-photo-v3.png`、`portraits-v3-alpha.png`、`objects-v3-alpha.png`：市场、夜间、序章资料及透明人物/器物图集。来源见ART_MANIFEST。
- `tests/test_immersive_core.gd`、`test_immersive_ui.gd`、`test_profile_store.gd`、`capture_immersive_ui.gd`、`run_checks.ps1`：新增核心、界面、凭据及截图验证。

## Tests / Evidence

| 用户要求 | 当前证据 | 结论 |
|---|---|---|
| 人物对白与独白、记录分开 | 既有 `immersive_dialogue.png`、`immersive_private.png` 与新版 UI 测试；人物原话只记录 player/npc | 本地通过 |
| 保存API配置与Key | 虚构凭据的DPAPI保存、读取相等、密文不含原字段、删除检查；当前用户配置成功解密并完成连接测试 | 本地通过 |
| 连续记忆与回答相关性 | 同一商户重入保留耐心/公开话题，原话随读档恢复；真实样本覆盖来源、议价、同一人物追问、买家需求与夜间旧账 | 小样本通过；长时间试玩待验 |
| 市场多家店与独立库存 | 4家固定店＋每日3～5摊，各5～8件；独立ID；重入/读档不复制库存；随机种子保存 | 本地通过 |
| 场景交互与夜间看货 | 店铺/市场/商户/茶馆/笔记/齿轮实际截图；夜间显式展示库存，私人概率不公开 | 本地通过 |
| 故事背景与疑问板 | 可跳过序章、信件、旧照插画、按实际旗标显示的疑问与走访方向 | 本地通过；吸引力待人类试玩 |
| 场景可发现性与剧情提问 | 热点覆盖场景物件并提供悬停提示；所有剧情节点有对应人物提示；快捷提问不自动解决节点 | 本地通过；仍需用户视觉试玩 |

新增界面测试从默认新版场景运行到第10日闭店，并点击实际成交确认按钮验证资金变化；同时验证对白折叠、历史开关、会面摘要、整数报价和市场往返。既有整章测试覆盖分支与物权，HTTP本地夹具覆盖两种协议与错误重试。截图中的对白是模拟回复，不是实际模型输出；当前执行环境的 headless 渲染驱动无法取得屏幕纹理，需在可渲染桌面窗口中运行 `capture_immersive_ui.gd` 做最终视觉检查。另有 `test_live_profile_connection.gd` 与 `test_live_dialogue_quality.gd` 使用已保存配置做受限真实验证，不纳入默认回归以避免每次自动计费。

## Deviations / Known Issues

- 实际模型跨会面记忆表达和兼容网关延迟仍在小样本验收中。本机`api_profile.dpapi`已存在且成功完成连接测试；Key只在运行时解密使用，没有写入仓库、普通存档或诊断日志。
- 自由文本意图目前为有限本地识别，复杂长句可能误分类；交割仍须玩家确认。真实对白联调须重点检验指代、反问、历史金额与新报价。
- 各商户共用市场背景，夜间场景共用茶馆背景；器物部分共用图集。独立物件ID不代表每件都有独立美术。新透明图集通过边缘棋盘格清理生成，仍需继续检查个别格子的抠图质量。
- 近期上下文读取每名人物最近30条原话及Core往来摘要；更早未结构化的承诺未保证长期召回。后续真实多轮验收需覆盖这一边界，不能把当前实现宣传为无限记忆。
- 凭据保护目前限Windows。联调许可与10元上限是开发约束；游戏中的玩家手动请求仍按服务商计费。尚未实现实时人民币费用仪表。

本机已保存 DeepSeek 配置并完成一次真实连接测试。DeepSeek V4 的对白请求自动关闭隐藏思考，以避免思考内容占满有限对白输出；其他服务商不改变原配置。价格和 Responses 接口依据官方文档核对：[模型与价格](https://api-docs.deepseek.com/quick_start/pricing)、[Responses API](https://api-docs.deepseek.com/api/create-response/)、[Thinking Mode](https://api-docs.deepseek.com/guides/thinking_mode/)。

## Next Step

受限真实样本已完成：来源问答→内心鉴定→议价→同一人物追问→买家需求→夜间旧账交流。DeepSeek V4 对话请求已按官方参数关闭隐藏思考，避免推理占满对白预算。下一步是用户实际试玩并记录场景热点是否容易发现、摘要和剧情提示是否减轻混乱，以及哪些对白听起来不自然，再进入内容/提示词迭代；不要在聊天里发送Key。
