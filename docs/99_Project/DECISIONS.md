---
title: Design Decisions
status: draft
owner: human
last_reviewed:
---

# Design Decisions
正式确定的重要设计在此记录，避免只存在聊天记录中。

## DEC-070

Date: 2026-09-05

Decision: 用户确认第二轮沉浸式改版：场景与人物保留，双侧头像/姓名消息卡并可回看；市场4家固定老店、每天3～5个随机小摊、每家约5～8件在售品；夜间可选茶馆交流及按关系/线索拜访熟人或专家，可交流验货后返回休息；自由交谈为主，钱货交割保留明确确认；1～2分钟可跳过序章、书信/照片与提示方向但不揭答案的疑问笔记。API配置与Key按本机受保护方式保存，允许本轮累计不超过人民币10元的真实模型联调；价格无法核实或无可用配置则不得调用。

Reason: 第一章试玩暴露对话混杂、记忆不足、场景与市场结构单薄及故事引导缺失。保存凭据与真实联调是本轮明确授权，不再沿用DEC-069的“不付费联调”限制，但不得越过新上限。

Affected Docs: [[IMMERSIVE_REVISION_PLAN]], [[UX_FLOW]], [[LLM_DESIGN]], [[LOCATIONS]], [[STORY]], [[DESIGN_PHASE_STATUS]]

Status: confirmed for immersive prototype revision

Boundary: 不升级为正式locked规则；不读取其他应用凭据，不将Key写进仓库、普通存档或日志。预算针对开发联调，真实模型仍不能直接修改权威状态。

## DEC-069
Date: 2026-09-05

Decision: 用户授权完整第一章 Godot 可玩原型，约10个营业日、8名重要NPC、至少24件器物与分支收束。采用中式写实插画，允许AI生成美术；剧情以行业人情和家族旧事为主。增加事实卡与2～3条可编辑回答，不泄露隐藏答案。本轮明确重开店外范围，加入外出与拍卖。暂不付费模型联调。

Reason: 一日试玩已验证经营链条，需要改善角色表达、稳定性、玩家辅助和视觉互动，并验证跨日剧情、人物与后果。

Affected Docs: [[NEXT_VERSION_PLAN]], [[DESIGN_PHASE_STATUS]], [[CHAPTER_ONE_SPEC]], [[CORE_LOOP]], [[UX_FLOW]], [[EVENT_SYSTEM]], [[LLM_DESIGN]]

Status: confirmed for next playable prototype

Boundary: 既有文档的 Post-V1 店外限制对本轮原型重新打开；实现古玩街看货、拜访懂行者与小型拍卖，保持章节化而非实时时钟。具体原型参数不自动成为永久设计。

## DEC-001
Date: 2026-08-24

Decision: 项目采用 Docs-Driven Development；设计文档是游戏设计的主要事实来源。

Reason: 让 Human Designer 通过 Obsidian 维护设计，并使后续 Task 与实现可追溯。

Affected Docs: [[INDEX]], [[AGENTS]]

Status: draft

## DEC-002
Date: 2026-08-31
Updated: 2026-09-01

Decision: 第一版普通古玩买卖遵循“买定离手、钱货两清”。交易完成后不自动退款或撤销。系统不判断玩家正常误判还是故意欺骗；已售假货只有在二次倒卖、被他人看货或类似后续场景中被真实发现时，才进入信誉、口碑、关系或事件影响判定，但不保证必然产生负面影响。是否发酵及其程度由 Game Core 结算。发现假货同时向玩家提供相关瑕疵信息并产生知识或经验收益。

Reason: 让买卖双方承担交易前判断风险，避免出售时通过即时信誉变化泄露隐藏真相，并让假货暴露同时形成长期口碑风险和失败学习反馈。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]], [[ANTIQUE_SYSTEM]], [[KNOWLEDGE_SYSTEM]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]]

Status: confirmed

Open Boundary: 假货发现条件、信誉损失、知识收益和口碑传播范围尚未确定。

## DEC-003
Date: 2026-09-01

Decision: 鉴定结果分为明确判假与概率判断两层。玩家经验足以发现决定性瑕疵时，可以明确判定为假；未发现足以判假的瑕疵时，获得由 Game Core 生成、以 `1%–99%` 整数显示且不含小数的真品概率，不能因此确认物件为真。概率模式不出现 `0%` 或 `100%`；明确判假是独立结果。鉴定反馈同时包含由 LLM 根据 Game Core 授权的概率、已发现线索和不确定性生成的玩家内心独白。主动鉴定中获得有意义的新线索时更新结果；库存物件不后台刷新，只有重新查看、重新鉴定或向买家推荐时才按当前能力重新计算，并保留历次鉴定记录。

Reason: 让玩家成长表现为能够识别更多真实线索，同时保留信息不完整和误判风险；数值概率提供明确的决策依据，内心独白提供自然、可理解的鉴定体验。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ANTIQUE_SYSTEM]], [[KNOWLEDGE_SYSTEM]], [[UX_FLOW]], [[WORLD_STATE]]

Status: confirmed

Open Boundary: 瑕疵识别条件、什么构成“有意义的新线索”和具体概率公式尚未确定。

## DEC-004
Date: 2026-09-01

Decision: V1 暂定使用基础鉴定委托作为经营软失败安全网。当玩家资金不足以完成最低层级收购且没有可出售库存时，Game Core 在近期营业中保证出现一次无需本金的鉴定委托。完成委托即可获得不会因判断错误而取消的最低服务费，使玩家重新进入最低层级交易；鉴定质量可以影响额外收益。委托不占用已经安排的客人名额，但需要占用明确的营业时间、日程或其他经营资源。

Reason: 防止玩家因资金与库存同时耗尽而永久退出核心经营循环，同时继续使用观察、询问和鉴定这一核心玩法恢复经营。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]]

Status: under review

Open Boundary: 触发阈值、保证出现的时间范围、最低服务费、额外收益以及未来更贴近现实古玩经营的替代或扩展方式尚未确定。

## DEC-005
Date: 2026-09-01

Decision: 卖货客人的真实状态不使用固定、互斥的卖家类型，而由认知状态、表达诚实度、出售动机和谈判策略等可组合维度构成。NPC 的陈述与物件真相不一致时，不自动视为故意欺骗；其原因也可能是卖家自身认知错误。上述权威状态由 Game Core 决定，LLM 仅依据授权状态进行对话表达。

Reason: 支持玩家通过交谈区分无知、误判、隐瞒、欺骗、急售和试探等不同情况，避免 NPC 对话退化为可快速识别的固定人物模板。

Affected Docs: [[CORE_LOOP]], [[CHARACTERS]], [[WORLD_STATE]], [[AI_BOUNDARIES]]

Status: confirmed

Open Boundary: 各维度的具体枚举、组合限制、对话可见线索，以及日常客人与重要 NPC 是否共用同一模型尚未确定。

## DEC-006
Date: 2026-09-01
Updated: 2026-09-01

Decision: 卖货客人的单次交互存在由 Game Core 管理的有限交谈耐心或等价阈值，玩家不能通过无限提问穷举隐藏信息。耐心按经过校验的对话行为结算，而不是按玩家发送的消息条数固定扣除。普通回应、确认和必要澄清通常不消耗；新主题追问正常消耗；重复追问、施压、质疑或指控通常消耗更多；合理引用线索的追问可以使用较低或正常消耗。寒暄和夸奖不能反复恢复耐心；玩家冒犯 NPC 后可以尝试一次道歉、解释或主动退让，由 Game Core 根据 NPC 性格、关系和受冒犯程度决定是否恢复少量耐心，且不能超过本次交互的初始上限。长期关系主要影响初始耐心。Game Core 可以保存精确耐心值，但不向玩家直接显示数字或进度条；玩家通过 NPC 态度变化和模糊阶段提示判断交谈空间。普通耐心耗尽后进入最终报价阶段，卖家停止回答新的调查问题，但玩家仍可报价、完成必要的最后议价或放弃；继续追问、施压、指控或拖延才可能导致卖家离店。急躁或已受冒犯的 NPC 可以更早离店，但必须提前反馈态度变化。LLM 或解析层可以提出候选对话行为，但耐心变化、恢复、阶段转换和离店结果必须由 Game Core 校验并结算。不提供能够直接判断 NPC 是否说谎的万能提示。

Reason: 让玩家必须选择最有价值的追问，并使人物判断保留不确定性、风险与对话成本。

Affected Docs: [[CORE_LOOP]], [[CHARACTERS]], [[RELATIONSHIP_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 态度阶段的数量与命名、对话行为的完整分类与具体消耗、一次性挽回的触发条件与恢复量，以及最终报价阶段哪些行为构成继续拖延尚未确定。

## DEC-007
Date: 2026-09-01

Decision: 买货客人也需要玩家通过交谈判断隐藏状态。其权威交易状态由购买目的、专业程度、预算弹性、购买急迫度和谈判策略等可组合维度构成，不使用固定、互斥的买家类型，也不只依赖公开的目标类别和价格区间。买家初次只表达宽泛的购买方向，具体用途、品质要求、真实预算、预算弹性和急迫度通过交谈逐步发现；表达不完整不必然代表故意欺骗。Game Core 决定这些状态及最终购买条件；LLM 根据授权状态通过询问重点、对推荐物件的反应、报价和谈判措辞逐步表现。买货客人使用与卖货客人相同的底层交谈耐心框架，但耐心耗尽后进入“最终选择阶段”：不再接受新的调查问题或库存推荐，只能在已看过的物件中作出最后决定、提出最后报价或离店。

Reason: 让买货分支同样承载“通过交谈识人”的核心体验，使推荐、定价和出售决策需要判断人物，而不是机械匹配库存标签。

Affected Docs: [[CORE_LOOP]], [[CHARACTERS]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 各维度的具体枚举与组合限制、哪些状态可以被玩家逐步发现、宽泛需求的最低信息量，以及最终选择阶段中哪些行为构成继续拖延并可能导致买家离店尚未确定。

## DEC-008
Date: 2026-09-01
Updated: 2026-09-01

Decision: 买货客人初次至少公开器物类别、约略价格和年代要求。器物基础类别是确定属性，不采用“疑似类别”的概率结果。系统可以依据这些公开条件、库存物件属性和物件当前市场估值，对匹配物件进行高亮或优先排序；初次匹配不使用玩家收购价或尚未提出的最终报价。玩家主动提出报价后，系统可以另行显示报价与买家预算的模糊匹配。年代要求使用时间范围进行匹配，完全落在范围内为高匹配，部分接近或相邻为弱匹配，明显超出为低匹配。类别要求使用层级匹配，买家提出父类时其子类可以匹配，提出具体子类时精确子类优先，同父类其他子类为弱匹配，完全不同大类不匹配。若没有完全匹配，系统仍保留符合部分条件的弱匹配候选，并提示玩家没有完全匹配；玩家可以自行决定是否推荐，买家是否接受由 Game Core 结算。完全不同大类或明显偏离公开需求的物件不进入第一版常规推荐范围。该提示只表示公开条件的机械匹配，不代表真伪、绝对年代、品相、价值、利润、买家真实偏好或系统替玩家决定推荐对象；玩家仍需通过鉴定记录、交谈和判断完成推荐。

Reason: 给玩家一个合理的库存筛选入口，避免买家需求完全隐蔽导致玩家无法开始行动，同时保留交谈识人和经营判断的核心乐趣。

Affected Docs: [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 类别层级的具体定义、价格和年代的完整匹配规则、具体模糊范围、排序方式、报价后的预算反馈、弱匹配候选的具体保留边界和数量尚未确定。

## DEC-009
Date: 2026-09-01

Decision: 玩家推荐或推销弱匹配库存时，必须准确告诉买家物件的具体类别，并可以主动说明物件特点、推荐理由以及它为什么可能满足买家需求。推销行为不能改变物件的确定类别，也不能把弱匹配表达为完全匹配；买家是否相信、感兴趣、议价或接受推荐由 Game Core 根据其隐藏状态、预算、耐心和对话结果结算。该规则确认的是相关弱匹配的主动推销，不扩大第一版对完全不同大类或明显偏离需求物件的常规推荐范围。

Reason: 保留玩家主动经营和销售库存的空间，同时保证物件类别这一基础事实不会被对话或 LLM 改写；玩家仍需承担推销弱匹配可能失败或损害信任的风险。

Affected Docs: [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 弱匹配介绍时界面需要向玩家展示哪些偏差、哪些表达属于正常推销或明确误导，以及错误陈述年代、价格或其他物件属性时的具体结算后果尚未完全确定。年代和价格偏差不要求玩家主动披露。

## DEC-010
Date: 2026-09-01

Decision: 玩家选择推荐库存物件后，系统必须自动展示并带出该物件的确定具体类别，作为物件介绍和后续对话的固定事实。玩家可以在类别事实之后自由推销物件，但不能通过自由文本省略或改写类别。该自动展示由 Game Core/UI 提供，不由 LLM 决定是否出现；年代和价格偏差不要求使用固定话术主动披露。

Reason: 在保留自然对话和主动销售空间的同时，保证物件类别这一基础事实不会因为玩家输入或 LLM 生成而丢失、模糊或被改写。

Affected Docs: [[GAME_RULES]], [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 自动类别展示的具体界面位置、展示时机，以及玩家明确陈述错误年代、价格或其他属性时的识别与结算方式尚未确定。

## DEC-011
Date: 2026-09-01

Decision: 玩家对物件市场价格、目标售价或交易报价的表达，属于估值观点、销售表达或谈判策略；价格与 Game Core 当前市场估值不一致，本身不直接构成说谎。年代、来源、真伪等客观属性的明确错误陈述，才可能进入误导或欺诈判定。LLM 可以表达玩家选择的价格立场，但 Game Core 负责保存市场估值、报价、成交价格及所有后果。

Reason: 区分“价格判断错误或谈判策略”和“虚构物件客观事实”，避免把古玩交易中正常的估价分歧误判为欺诈，同时保留玩家利用错误信息误导买家的风险空间。

Affected Docs: [[GAME_RULES]], [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[ECONOMY]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 年代、来源、真伪等客观属性的错误陈述如何被识别、后续真实发现的条件、具体信誉/关系/事件影响，以及是否在更高版本区分玩家误判、选择性隐瞒和故意欺诈尚未确定。

## DEC-012
Date: 2026-09-01

Decision: 沿用“买定离手、钱货两清”的后续发现规则。玩家售出假货，或对年代、来源、真伪等客观属性作出错误陈述时，交易完成不立即揭示真相、扣除信誉或撤销交易。只有相关问题在后续流转、看货或类似场景中被真实发现时，才进入信誉、口碑、关系或事件影响判定，但不保证必然产生负面影响；是否发酵及其程度由 Game Core 结算。第一版不在交易当下强行区分玩家是正常误判还是故意欺骗。价格表达仍按 DEC-011 作为估值观点或谈判策略处理。

Reason: 保持交易前判断风险和买定离手的核心体验，避免系统在交易完成瞬间替玩家揭示隐藏真相；后续发现同时提供长期经营后果和学习反馈。

Affected Docs: [[GAME_RULES]], [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 哪些后续场景可以真实发现错误、各发现者层级的具体能力范围、后果的具体数值和传播范围尚未确定。

## DEC-013
Date: 2026-09-01

Decision: 后续发现者暂采用三个能力层级：普通客人只能发现非常明显的问题；懂行买家或相关 NPC 能发现较隐蔽的问题；专业鉴定人拥有最高的相关发现能力。层级只影响此次检查能否识别问题，不直接决定是否产生后果或后果轻重。实际是否发现由 Game Core 结合物件问题的明显程度、可观察线索、发现者能力和具体情境结算，不保证高能力发现者每次都成功。LLM 只能表现 Game Core 已结算的检查和发现结果。

Reason: 给后续发现事件提供清晰的能力框架，让玩家理解为什么不同人物的鉴定可靠度不同，同时保留不确定性和事件设计空间。

Affected Docs: [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 三个层级的具体能力范围、物件问题的难度、发现判定条件、发现概率，以及是否需要付费或通过特定事件接触尚未确定。

## DEC-014
Date: 2026-09-01

Decision: 客观错误被发现不等于必然扣除信誉或产生负面后果。发现只会使事件进入后续影响判定；是否发酵以及发酵程度由 Game Core 根据问题严重程度、假货成交价格、买家身份、交易关系和传播范围决定。发现者的能力层级只影响能否识别问题，不直接决定处罚强度。

Reason: 古玩行业中的问题暴露可能因为交易金额、买家影响力和传播范围不同而产生不同结果，避免把“被发现”机械等同于固定处罚，同时保留长期经营风险。

Affected Docs: [[GAME_RULES]], [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 影响判定的具体公式、无明显后果与轻度/重度发酵的边界尚未确定。

## DEC-015
Date: 2026-09-01

Decision: V1 将原买家身份暂分为三个层级，用于影响客观错误被发现后的传播与发酵潜力：普通买家、懂行买家或行业相关 NPC、有行业影响力的买家。普通买家的传播范围通常较小，可能没有明显后果；懂行买家或行业相关 NPC 可能引发圈内议论并影响相关关系或口碑；有行业影响力的买家可能造成更大范围传播并触发更严重的经营或事件后果。该层级只影响后续影响的潜力，不代表必然产生对应后果，也不等同于发现者能力层级。

Reason: 买家身份会影响问题暴露后的社会传播范围，使相同的假货问题在不同交易对象手中产生不同的经营风险，同时保持“发现不等于必然处罚”的规则。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ANTIQUE_SYSTEM]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 三个买家身份层级对应的具体数值、传播路径、影响范围和事件触发条件尚未确定。

## DEC-016
Date: 2026-09-01

Decision: 假货或客观属性错误的成交价格不参与后续发现判定，不影响发现者能否识别问题，也不改变发现者的能力范围。只有在问题已经被 Game Core 判定为真实发现后，成交价格才作为影响判定输入，用于与问题严重程度、买家身份、交易关系和传播范围共同决定是否发酵及发酵程度。

Reason: 将“能否发现问题”和“发现后造成多大社会影响”分成两个阶段，避免高价交易自动变成更容易被发现，同时保留高额交易可能带来更严重后果的经营风险。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ANTIQUE_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 成交价格在影响判定中的具体区间、权重和与其他因素的组合方式尚未确定。

## DEC-017
Date: 2026-09-01

Decision: V1 将物件问题或玩家客观属性错误的严重程度分为三个层级：轻微问题、严重问题、极严重问题。轻微问题包括局部瑕疵或有限价值偏差；严重问题包括真伪、年代、来源等重大错误，且会明显改变价值判断；极严重问题包括关键属性完全虚构，或物件本质与玩家陈述严重不符。该层级主要描述问题本身对物件真实价值与行业判断的影响，不以成交价格作为定义，不等同于发现者能力，也不等同于买家身份；成交价格作为独立因素参与后续影响判定，是否产生后果仍需由 Game Core 综合其他因素判定。

Reason: 将问题本身、成交价格、发现能力和社会传播潜力分开，避免同一因素被重复计算，便于后续建立可解释的影响判定，同时保留不同情境下可能无影响或产生不同程度后果的空间。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ANTIQUE_SYSTEM]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 三档问题在复杂边界案例中的具体归类、对应的影响范围和与成交价格及买家身份的组合方式尚未确定。

## DEC-018
Date: 2026-09-01

Decision: 同一物件存在多个已知问题时，Game Core 以其中最高严重程度作为该物件的主问题等级；其他问题作为附加影响因素保留，不覆盖或降低主问题等级。附加问题可以参与后续影响、传播和学习反馈的结算，但具体作用仍由 Game Core 根据情境决定。

Reason: 避免多个问题被平均后掩盖关键风险，同时保留多个问题叠加造成额外社会影响或学习价值的空间。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ANTIQUE_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]]

Status: confirmed

Open Boundary: 附加问题如何影响传播、后果和学习反馈，以及多个轻微问题是否可能在特殊情况下形成更高的综合影响，尚未确定。

## DEC-019
Date: 2026-09-01

Decision: 同一物件的多个问题需要分别记录，并由 Game Core 独立判定是否被当前发现者识别。一次后续发现事件只反馈本次被识别的问题，未被识别的问题继续作为隐藏风险保留，不因发现其中一个问题而自动揭示全部问题。物件整体主问题等级仍由真实存在的问题中的最高严重程度决定。

Reason: 保留鉴定和后续事件的不确定性，避免一次检查自动清空所有风险，同时让不同发现者和不同情境能够揭示不同层次的问题。

Affected Docs: [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 多个问题在不同事件中分别暴露时，影响结算是否重复、如何合并，以及玩家已经学到的问题如何影响后续鉴定尚未确定。

## DEC-020
Date: 2026-09-01

Decision: 后续发现事件的当次影响判定只使用本次被当前发现者实际识别的问题。物件中尚未被识别的隐藏问题，不提前按照其真实严重程度产生信誉、口碑、关系或事件后果；这些问题继续保留为隐藏风险，直到未来被真实发现后再进入相应影响判定。物件整体真实主问题等级仍由所有真实问题中的最高等级记录。

Reason: 让玩家只为已经暴露的事实承担当次后果，避免 Game Core 依据玩家尚不知道的隐藏问题提前处罚，同时保留后续再次发现和风险逐步升级的空间。

Affected Docs: [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[EVENT_SYSTEM]], [[RELATIONSHIP_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 同一问题在同一传播圈层中再次被发现时的提示与记录方式，以及不同问题或不同传播圈层之间的新增影响如何合并尚未确定。

## DEC-021
Date: 2026-09-02

Decision: 同一个问题被不同 NPC 或不同发现者多次发现时，该问题的基础后果只结算一次，不重复施加同一基础信誉、关系或口碑影响。后续发现如果带来新的传播圈层、新的关系对象或新的事件条件，可以由 Game Core 结算新增影响；如果只是同一问题在同一影响范围内被重复确认，则不产生重复的基础后果。所有发现历史和已结算影响由 Game Core 保存。

Reason: 避免同一问题被重复发现后造成机械式重复惩罚，同时保留问题从个人认知扩散到行业圈层时持续发酵的可能。

Affected Docs: [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[EVENT_SYSTEM]], [[RELATIONSHIP_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: “同一影响范围”的具体判定方式、新传播圈层的识别、同一问题触发新事件时的新增影响上限尚未确定。

## DEC-022
Date: 2026-09-02

Decision: V1 将客观错误被发现后的传播范围暂分为三个层级：个人关系圈、行业圈、公众/市场圈。个人关系圈包括原买家及其直接关系；行业圈包括同行、懂行 NPC、相关商人或鉴定人；公众/市场圈包括更大范围的市场口碑、公开评价或重要事件。传播圈层只描述潜在影响范围，不代表问题必然扩散；Game Core 决定是否进入更大的圈层。

Reason: 为后续区分“同一范围内重复确认”和“进入新的社会影响范围”提供清晰结构，也使信誉、关系、口碑和事件后果可以按传播范围逐步扩大。

Affected Docs: [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[EVENT_SYSTEM]], [[RELATIONSHIP_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 三个传播圈层之间的具体边界、跨圈层传播条件、传播速度和每层对应的具体后果尚未确定。

## DEC-023
Date: 2026-09-02

Decision: V1 的跨圈层传播需要由具体事件或关系行为触发，不会自动扩大。个人关系圈进入行业圈的触发包括买家向同行咨询、再次转卖时请懂行者看货或进入正式鉴定；行业圈进入公众/市场圈的触发包括行业内形成公开争议、重要人物介入或事件被公开传播。没有满足明确触发条件时，问题停留在当前传播圈层。

Reason: 让口碑扩散具有可理解的因果链，避免玩家因一次隐蔽的错误直接遭遇全行业或公众惩罚，同时为后续事件设计提供明确入口。

Affected Docs: [[CORE_LOOP]], [[ANTIQUE_SYSTEM]], [[EVENT_SYSTEM]], [[RELATIONSHIP_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 各传播触发事件的具体条件、发生概率、时间间隔和玩家可否主动阻止或延缓传播尚未确定。

## DEC-024
Date: 2026-09-02

Decision: V1 允许玩家通过有限的主动行动阻止或延缓客观错误的传播，但不保证成功，也不自动撤销已经完成的交易。可用行动包括主动联系买家解释、请求暂缓转卖、提供补充信息或利用已有关系进行沟通。是否成功以及能否改变后续传播，由 Game Core 根据关系状态、行动时机、玩家提供的信息和当前事件条件结算。

Reason: 给玩家在错误暴露后处理局势的主动权，使长期经营不只是等待惩罚，同时保持“买定离手、钱货两清”和后果不可完全控制的风险。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 可用干预行动的具体解锁条件、时间窗口、资源消耗、成功判定和失败后果尚未确定。

## DEC-025
Date: 2026-09-02

Decision: 每个传播圈层阶段最多允许玩家进行一次主要干预。玩家不能在同一传播阶段通过重复沟通无限尝试重置传播或重新判定。若问题之后进入新的传播圈层，则该新阶段可以依据事件条件产生新的干预机会；干预是否占用当天的可支配时间或其他日程成本，留待 Time Model 确定。

Reason: 限制重复操作带来的系统利用，同时让玩家在个人关系圈、行业圈和公众/市场圈分别面对有限的危机处理选择。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 干预占用的具体时间或日程成本、可用时间窗口和失败后的具体后果尚未确定。

## DEC-026
Date: 2026-09-02

Decision: V1 将每次主要干预视为需要付出明确的时间或日程安排成本，不直接扣除固定金钱；具体成本、是否占用营业日安排以及是否受事件窗口限制，留待 Time Model 设计。干预本身仍需要遵守每个传播圈层阶段最多一次的限制。

Reason: 让危机处理与玩家的经营节奏和机会成本关联，避免 V1 先引入复杂的金钱收费规则，同时保留未来扩展不同干预成本的空间。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 干预的具体时间或日程成本、每日可支配时间结构以及不同干预行动是否消耗相同成本尚未确定。

## DEC-027
Date: 2026-09-02

Decision: V1 将玩家每天的可支配时间与日程安排视为有限经营资源。主要干预可能占用当天的时间或改变日程，因此可能减少玩家当天用于交易之外的主动鉴定、学习、外出或其他可选经营安排的时间。营业日的具体时段、活动时长和各类经营行为的占用规则留待 Time Model 设计。

Reason: 让危机干预真正进入经营取舍，而不是额外赠送的免费操作；同时把干预与 Short Loop 的一天营业结构连接起来，并避免使用明显的回合制资源表达。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 营业时段的数量与长度、可选经营行为的时间成本、时间冲突时的优先级以及干预的可用窗口尚未确定。

## DEC-028
Date: 2026-09-03

Decision: V1 将每日客人接待安排与玩家营业之外的可支配时间安排分开计算。每天约 4～6 名客人（2～3 名卖货客人和 2～3 名买货客人）属于 Short Loop 的固定营业安排；接待这些已安排客人不直接阻断玩家的其他时间安排。主要干预、交易之外的主动鉴定、学习、外出和其他可选经营活动需要通过时间或日程安排产生机会成本。主要干预不会直接取消已安排的客人，优先影响其他可选安排。

Reason: 保持 Short Loop 每日营业结构稳定，同时让时间与日程安排承担可选经营决策的机会成本，避免危机事件随机破坏基本接待循环。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 营业时段如何与客人交互之外的活动以及不可跳过的事件安排换算，尚未确定。

## DEC-029
Date: 2026-09-03

Decision: V1 原计划每天提供固定数量的行动机会，但该方案目前仅作为待评审候选。是否改为营业时段、日程安排或其他自然时间表达，留待 Time Model 与 Core Loop 体验评审。

Reason: 原方案试图让玩家面对明确的当日取舍，但固定次数可能产生回合制资源感，因此需要重新评审表达方式。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: under review

Open Boundary: 自然时间模型的具体结构、活动时长、冲突处理和机会成本尚未确定。

## DEC-030
Date: 2026-09-03

Decision: V1 初始曾将玩家每天的行动机会数量设为 3 次；由于该方案可能产生回合制资源感，目前不作为最终规则，是否保留仅待 Time Model 评审。

Reason: 该方案原本用于在危机干预、主动鉴定以及学习/外出等可选活动之间形成明确取舍，但需要先验证是否符合自然经营节奏。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: under review

Open Boundary: 自然时间模型中各类可选经营行为的时间成本、是否存在不占用主要时段的行为，以及时间冲突时的行为优先级尚未确定。

## DEC-031
Date: 2026-09-03

Decision: V1 中，除已经安排的客人接待及其必要交易流程外，所有可选经营活动原计划统一消耗 1 次行动机会；该统一成本方案目前不作为最终规则，后续改由自然时间或日程安排表达。主要干预、交易之外的主动鉴定、学习、外出以及其他可选经营活动仍需产生明确的机会成本。

Reason: 原方案试图降低玩家理解和 Agent 实现的复杂度，但固定行动点可能削弱自然经营感，因此需要改由时间与日程结构承载取舍。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: under review

Open Boundary: 各类可选经营活动的时间长度、时间冲突处理、是否允许调整已安排活动，以及不同活动是否需要差异化时间成本尚未确定。

## DEC-032
Date: 2026-09-03

Decision: 卖货客人到店后，玩家必须先进入观察、询问和鉴定流程，形成收购前判断后才能进入收购决策。该鉴定属于卖货交易分支的必要流程，不占用交易之外的可支配时间安排；玩家在该流程中可以选择结束调查、议价或放弃收购。与此不同，针对库存物件、非当前客人交易或其他经营目标的主动鉴定，仍属于可选经营活动，其时间成本留待 Time Model 确定。

Reason: 保证每次收购都建立在玩家主动判断之上，突出鉴定与对话的核心体验；同时避免玩家因处理已安排的卖货客人而被行动机会系统阻断。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ANTIQUE_SYSTEM]], [[KNOWLEDGE_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 卖货分支内观察、询问、鉴定各自能获得的信息量、是否存在额外调查选项，以及进入最终报价阶段后的可用行为尚未完全确定。

## DEC-033
Date: 2026-09-04

Decision: 买货客人到店后，玩家查看库存、重新评估与客人需求相关的物件、获得匹配提示、推荐物件、介绍物件、议价和完成出售，均属于当前买货交易的必要流程，不占用交易之外的可支配时间安排。针对未被当前客人关注的库存进行独立研究、重新鉴定或其他交易之外的处理，才属于可选经营活动。

Reason: 买货交易同样必须让玩家基于库存信息和新的判断完成出售，不能因为行动机会不足而无法正常处理已经到店的客人；同时保留交易之外活动的时间取舍空间。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ANTIQUE_SYSTEM]], [[KNOWLEDGE_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 买货交易中重新评估物件的具体触发方式、可获得的信息量，以及哪些行为属于“交易必要流程”仍需在 UX Flow 中细化。

## DEC-034
Date: 2026-09-04

Decision: 由于固定行动次数和统一行动成本可能让玩家产生明显的回合制资源感，V1 暂不锁定当前行动机会方案。DEC-027、DEC-029、DEC-030、DEC-031 中关于固定每日行动机会、每日 3 次、每项活动消耗 1 次以及不跨日累积的组合规则，统一进入 Time Model 与 Core Loop 体验评审。已确认的交易必要流程不应因该评审被打断；在方案重新确定前，不得将行动机会实现为最终的可见回合制资源系统。

Reason: 保护项目的经营沉浸感和自然时间感，避免为了表达机会成本而过早引入不符合目标体验的回合制界面与行为节奏。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: under review

Open Boundary: 自然时间模型的具体时段、活动时长、时间冲突处理，以及可选活动如何产生机会成本，尚未完全确定。

## DEC-035
Date: 2026-09-04

Decision: V1 采用自然时间与日程安排作为经营节奏的设计方向，不采用玩家直接看到的回合制行动点作为主要表达。一天由若干营业时段组成；客人到访按照 Game Core 的安排进入相应时段。已经安排的客人及其必要交易流程必须能够正常完成，不因交易之外的资源不足而被阻断。主动鉴定、学习、外出、问题发现后的主要干预和其他可选活动，通过占用时间、改变日程或使其他活动错过来产生机会成本。时段数量、长度、客人具体占用方式和时间冲突处理留待 Time Model 设计。

Reason: 保留经营中的时间压力和取舍，同时避免把玩家体验简化成“每天有几格行动点”的回合制资源管理。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed direction

Open Boundary: 上午、下午、晚上的具体时长、客人到访是否占用完整时段、多个客人如何排列、可选活动如何插入日程，以及错过活动的反馈和后果尚未确定。

## DEC-036
Date: 2026-09-04

Decision: V1 初步将一天划分为三个叙事时段：上午、下午、晚上。三个时段用于表达客人到访、事件触发和玩家日程变化，不等同于三次行动机会，也不要求每个时段只能完成一次行为。玩家不直接看到行动点计数；具体时段长度、客人安排密度和活动占用方式留待 Time Model 与试玩调整。

Reason: 提供易于理解的自然时间结构，让玩家感受到一天的经营节奏，同时避免将时间压力表现为回合制资源格。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ECONOMY]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: provisional for V1

Open Boundary: 三个时段的实际长度、多个客人如何分布、活动之间发生时间冲突时如何处理，以及玩家如何感知时间流逝尚未确定；交易交互可以跨越时段。

## DEC-037
Date: 2026-09-04

Decision: V1 允许同一个叙事时段内连续接待多名客人，不采用“一时段最多一名客人”的限制。上午、下午和晚上只表达自然时间阶段；每天 4～6 名客人的具体到访顺序、间隔和分布由 Game Core 安排。

Reason: 让三个时段承担节奏和日程表达，而不是变成固定容量的回合格子；同时保留每天接待 4～6 名客人的核心营业结构。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[UX_FLOW]], [[EVENT_SYSTEM]]

Status: confirmed

Open Boundary: 客人之间的具体到访间隔、单次交互跨越时段时的日程处理，以及高峰或空闲时段如何表现尚未确定；交互可以跨越时段，且不应因此默认顺延到下一营业日。

## DEC-038
Date: 2026-09-04

Decision: V1 允许一次客人交易交互自然跨越上午、下午和晚上时段。时段切换不自动中断正在进行的观察、询问、鉴定、推荐、议价或出售流程；只有交易完成、玩家放弃、NPC 离店或其他明确的 Game Core 结算结果，才会结束当前交互。

Reason: 避免把叙事时段变成回合边界，保持对话和交易的连续性，使时间推进服务于经营节奏而不是强制切断玩家行为。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[UX_FLOW]], [[EVENT_SYSTEM]]

Status: confirmed

Open Boundary: 交易跨越时段时的界面提示、事件是否可以在交互中插入，以及跨越时段对 NPC 耐心和其他状态的影响尚未确定。

## DEC-040
Date: 2026-09-04

Decision: V1 的时间流逝采用叙事化和适度压缩，而不是按现实分钟数快速推进。Game Core 应在正常交互、有限交谈耐心和既定来客安排下，保证当天约 4～6 名客人在当日白天的主要营业期间完成接待。若当前客人跨越时段，后续客人进入等待队列，但正常交易不会仅因时间推进而自动顺延到下一营业日；Game Core 通过安排到访间隔和抽象交互时长维持当天可完成性。

Reason: 保留一天之内的时间推进和经营节奏，同时确保玩家不会因为正常观察、询问、鉴定和议价而失去当天已经安排的客人。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[UX_FLOW]], [[EVENT_SYSTEM]]

Status: provisional for V1

Open Boundary: 交互时长如何抽象、极端情况下的队列处理，以及玩家主动拖延是否可能导致客人顺延尚未确定；V1 主要营业窗口优先安排在上午和下午，晚上尽量不安排新的普通客人。

## DEC-041
Date: 2026-09-04

Decision: V1 将上午和下午作为普通客人的主要接待窗口，Game Core 应优先把每天约 4～6 名客人安排在这两个时段内。晚上原则上不安排新的普通客人到访，主要用于当日结算、NPC 事件、外出和其他非日常接待活动。已经开始的客人交易可以跨越到晚上完成；晚间特殊客人或特殊事件是否例外，留待 Event Model 设计。

Reason: 让玩家拥有清晰的白天经营节奏，避免常规客人接待侵占晚间时间，同时保留跨时段交易的自然连续性。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[UX_FLOW]], [[EVENT_SYSTEM]]

Status: provisional for V1

Open Boundary: 晚间结算与事件的优先级，以及特殊客人是否可以在晚上到访尚未确定；上午和下午不设固定客人配额。

## DEC-042
Date: 2026-09-04

Decision: V1 不为上午和下午设置固定的客人数量配额，只保证每天约 4～6 名普通客人作为整体接待目标。Game Core 根据当天卖货客人与买货客人的组合、客人状态、店铺状态和节奏控制，灵活决定客人在上午与下午之间的分布、到访顺序和间隔；晚上仍原则上不安排新的普通客人。

Reason: 让系统可以根据当天的交易结构和叙事节奏自然安排来客，避免上午和下午变成机械填充的固定回合格。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[UX_FLOW]], [[EVENT_SYSTEM]]

Status: confirmed

Open Boundary: Game Core 如何在保证白天完成目标的同时控制客人类型连续性、空闲时段和特殊事件插入尚未确定；玩家界面不显示精确钟点。

## DEC-043
Date: 2026-09-04

Decision: V1 不向玩家显示具体几点几分，只显示上午、下午、晚上等叙事时段，以及当前客人、等待队列和必要的日程反馈。Game Core 可以保存内部顺序、时段位置或其他时间状态用于结算，但不要求将其表现为玩家可见的精确时钟，也不要求按现实分钟实时流逝。

Reason: 让玩家感受到时间和经营节奏，同时避免精确时钟带来的倒计时压力与过度模拟感。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[UX_FLOW]], [[EVENT_SYSTEM]]

Status: provisional for V1

Open Boundary: 时段切换提示、内部时间状态需要多高精度、玩家能否预览后续日程，以及特殊限时事件是否需要更精确的时间提示尚未确定。

## DEC-044
Date: 2026-09-04

Decision: V1 在当前客人交互期间，只向玩家提示是否还有客人在等待，不显示等待队列中的具体人数、身份、买货或卖货来意、需求或到访顺序。等待客人的完整权威状态由 Game Core 保存；只有客人正式进入交互后，玩家才通过交谈发现其来意和需求。LLM 不得提前泄露等待客人的隐藏状态。

Reason: 让玩家知道当天经营仍未结束，同时保留客人登场和通过对话判断来意的不确定性，避免队列界面提前替玩家完成识人过程。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: “仍有客人等待”的具体视觉与文字表现尚未确定。特殊预约客人的提前公开边界见 DEC-045。

## DEC-045
Date: 2026-09-04

Decision: V1 允许特殊预约客人在正式到访前向玩家公开预约所在的叙事时段，以及该客人愿意公开的身份信息。预约只构成等待队列隐藏规则的有限例外，不自动公开客人的买货或卖货来意、真实需求、预算、专业程度、急迫度或其他隐藏状态；除非某项信息被 Game Core 明确标记为预约时可公开，玩家仍需在正式交谈中发现。

Reason: 让特殊预约能够形成可规划的经营日程和期待感，同时保留通过交谈识别客人意图与需求的核心玩法，不让预约提示替玩家完成判断。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 特殊预约如何产生、是否可以安排在晚上，以及玩家错过或无法按时接待时如何处理尚未确定。预约是否计入每日接待目标见 DEC-046。

## DEC-046
Date: 2026-09-04

Decision: V1 中，特殊预约客人默认计入每天约 4～6 名客人的整体接待目标，并根据其由 Game Core 保存的权威来意，替代当天一名同类普通随机客人，以维持卖货客人与买货客人各约 2～3 名的日常结构。只有被 Game Core 明确标记为重要剧情例外的预约事件，才可以在常规接待总量之外额外出现。

Reason: 让预约产生可规划性和特殊感，同时避免预约日无条件增加接待压力、挤占晚间活动或破坏已经确定的一日营业节奏。重要剧情仍保留受控突破常规节奏的能力。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 不属于买货或卖货分支的特殊预约应如何计入每日接待结构，以及重要剧情例外最多可以增加多少接待量，留待 Event Model 与试玩决定。

## DEC-047
Date: 2026-09-04

Decision: V1 中，预约客人到达时不会打断正在进行的客人交易。预约客人进入等待状态，并在当前交易结束后优先于尚未开始交互的普通客人接受接待。由 Game Core 的正常到访安排或玩家完成当前必要交易流程所造成的等待，不视为玩家失约，不扣除预约客人的交谈耐心，也不产生关系、信誉或其他惩罚。LLM 只能表现 Game Core 已结算的等待状态，不得自行生成负面反应。

Reason: 保护单次对话与交易的连续性，同时兑现预约的日程优先级；玩家不应为系统自己安排出的时间重叠承担不可避免的惩罚。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 玩家主动外出、进行可选活动或在当前交易中明显拖延而导致无法接待预约客人时，何时构成真正失约及其后果尚未确定。

## DEC-048
Date: 2026-09-04

Decision: V1 中，如果玩家已知某一叙事时段存在预约，却主动选择会与预约冲突的外出或可选活动，系统必须在最终确认前明确警告可能错过预约。玩家仍可选择继续；若最终未能接待预约客人，Game Core 将其结算为主动失约，关闭本次预约对应的交易或事件机会，并默认降低与该 NPC 的关系。单次普通失约不直接降低全局信誉；只有预约对象具有行业影响力，或玩家已经形成反复失约记录时，才可能进一步进入行业口碑影响判定。LLM 不得自行判定失约或生成未结算的后果。

Reason: 让预约真正参与日程取舍，同时保证后果来自玩家知情后的选择，而不是系统不可控的排队冲突；关系损失提供直接而合理的代价，受控的口碑条件则防止单次失误被过度惩罚。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 关系下降的具体幅度、何种 NPC 属于具有行业影响力、多少次及多长时间范围内的失约构成“反复失约”，以及玩家能否修复失约关系尚未确定。

## DEC-049
Date: 2026-09-04

Decision: V1 允许玩家在来客间隔中进行可中断的店内轻量活动，也允许玩家在当前客人交互尚未结束时暂时切出对话界面，再通过当前客人的可识别头像、柜台卡片或等价入口点击返回。Game Core 必须保留同一客人的对话历史、已公开信息、耐心、交易阶段和未完成选择。单纯的界面切换不推进对话、不消耗耐心、不结束交易，也不公开等待队列中的其他客人；同一时间仍只有一名当前交互客人。外出、正式学习、拜访 NPC 等不可随时中断的活动仍需遵循日程与冲突规则，不能通过切出界面无限冻结当前客人。

Reason: 让店铺界面具有自然的空间感和可操作性，使玩家不必被锁死在聊天窗口中，同时维持单客交易的连续性、等待队列的信息隐藏和时间选择的真实性。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed direction

Open Boundary: 没有当前客人时，哪些店内活动可以在来客间隔中开始、其中哪些会推进内部时间，以及头像或柜台入口的最终视觉形式尚未确定。当前客人在场时的活动范围见 DEC-050。

## DEC-050
Date: 2026-09-04

Decision: V1 中，当前客人仍在柜台且交易尚未结束时，玩家只能暂时切换到不独立推进日程的信息查看，或执行本次交易的必要操作。允许范围包括查看库存及筛选结果、账本、历史交易记录、人物已公开资料、已有鉴定记录，以及观察、鉴定或选择本次交易涉及的物件。玩家不能在保持当前交互的同时开始独立学习、鉴定与本次交易无关的物件、外出、拜访 NPC 或其他需要独立推进日程的活动；这些活动只能在当前交易以成交、拒绝、放弃、NPC 离店或其他明确结果结束后开始。

Reason: 保留玩家随时查阅判断依据和操作交易内容的自由，同时防止通过界面切换无限冻结客人、规避时间成本或并行执行互相冲突的经营活动。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 没有当前客人时可开始的店内活动清单、耗时店内活动被新客人打断后的进度保存方式，以及各类活动的内部时间成本尚未确定。

## DEC-051
Date: 2026-09-04

Decision: V1 中，当店内没有当前客人时，玩家可以在来客间隔中开始允许中断的耗时店内活动。新客人到访时，Game Core 在活动的规则安全节点自动暂停活动，保存已经完成的有效进度，并进入客人接待。暂停不返还已经消耗的时间，也不清除已完成进度；当前客人交易结束后，玩家可以从保存状态继续活动。LLM 不能决定进度、时间回滚或延迟客人到访。

Reason: 让来客间隔具有实际用途，避免玩家只能空等，同时使客人接待保持优先，并让自然时间成本在活动被打断后仍然成立。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 哪些店内活动允许中断、每类活动的安全节点和总时长、未完成活动能否跨时段或跨日保留，以及同一时间能否保存多个暂停活动尚未确定。

## DEC-052
Date: 2026-09-04

Decision: V1 以活动是否依赖地点转换或他人日程作为可中断性的主要判断原则。整理或调整库存陈列、独立鉴定库存、查阅资料、阅读笔记或书籍等店内个人活动通常可中断；外出、拍卖、拜访 NPC、与师傅正式学习、参加行业活动及重大事件通常不可中断。每种活动的可中断性必须由 Game Core 的数据或规则预先定义；LLM 只能表现该结果，不能临时改变活动类型。

Reason: 用符合现实直觉的标准区分活动，既让玩家充分利用店内来客间隔，又保留地点移动、人物约定和重要事件带来的真实日程取舍。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ANTIQUE_SYSTEM]], [[KNOWLEDGE_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[UX_FLOW]]

Status: confirmed for V1

Open Boundary: 各活动的具体时长、安全节点、收益，以及少数不符合默认分类的例外活动尚未确定。跨时段与跨营业日保存规则见 DEC-053。

## DEC-053
Date: 2026-09-04

Decision: V1 中，可中断店内活动在安全节点保存的有效进度允许跨上午、下午、晚上以及跨营业日保留。玩家恢复活动时从最近保存的安全节点继续；已经消耗的时间不会返还，时段切换或当日结算本身也不会清除进度。活动的部分进度是否已经产生可用输出或收益，仍由 Game Core 根据该活动的结算节点决定。

Reason: 避免玩家因无法预测下一名客人的到访而不敢开始店内活动，也避免跨时段或跨日造成重复劳动；保留已消耗时间则确保中断不会消除活动的机会成本。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[ANTIQUE_SYSTEM]], [[KNOWLEDGE_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 同一时间可以保存多少个暂停活动、玩家能否主动取消并清除进度、各活动何时产生部分或完整收益尚未确定。

## DEC-054
Date: 2026-09-04

Decision: V1 不采用随现实时间持续运行的游戏时钟。玩家停留在界面中阅读资料、查看物件、浏览记录或思考对话回复时，不推进游戏时间，也不因此触发客人到访、NPC 耐心消耗、错过事件或其他时间后果。时间只在玩家确认并完成经 Game Core 识别的有意义行为、活动结算，或进入明确的日程推进节点时变化。LLM 生成耗时和玩家现实阅读速度均不参与时间结算。

Reason: 让玩家能够认真阅读线索和思考人物意图，避免核心判断玩法变成阅读速度测试；同时保留由行为和日程选择产生的时间成本，而不重新引入显性的回合制行动点。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed

Open Boundary: 哪些具体行为构成推进时间的“有意义行为”、各行为推进多少内部时间，以及时段切换阈值如何定义尚未确定。

## DEC-055
Date: 2026-09-04

Decision: V1 的单客交互不按玩家发送的对话消息数量推进时间。Game Core 只在完成调查、形成鉴定结算、结束议价、完成交易或完成单客结算等关键交互里程碑累计抽象时间；同一里程碑在同一次交互中只能结算一次，重复查看、返回界面或重复表达不会再次推进时间。对话行为仍可按语义规则独立消耗 NPC 耐心。店内学习、独立鉴定、外出和其他经营活动按照各自预定义的时长、安全节点或日程结果推进时间；库存、账本、资料、人物信息等只读查看与界面切换不推进时间。

Reason: 让完整交易和经营活动真实推动一天的节奏，同时避免按消息计时惩罚自然对话、详细表达或界面操作，并防止通过重复进入阶段造成时间重复结算。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]]

Status: confirmed direction

Open Boundary: 每类交易里程碑和经营活动具体推进多少内部时间、可否跳过某些里程碑、时段切换阈值以及时间成本的玩家可见精度尚未确定。

## DEC-056
Date: 2026-09-04

Decision: V1 将一日经营改为章节化营业流程：上午来客、午间过场、下午来客、晚上闭店结算。上午、下午和晚上是依次进入的流程节点，不是连续时间模拟、精确时钟或可见行动点。上午与下午共同安排每天约 4～6 名客人，玩家处理完当前阶段的来客后进入下一阶段；晚上不安排普通来客。V1 不包含外出、拍卖、正式学习、预约冲突、耗时活动中断恢复及其时间成本。DEC-027 至 DEC-031、DEC-035 至 DEC-043、DEC-045 至 DEC-048、DEC-051 至 DEC-055 中与连续时间、日程冲突、预约和耗时活动相关的规则不再约束 V1，保留为 Post-V1 候选。DEC-032、DEC-033、DEC-044、DEC-049 和 DEC-050 中关于交易必要流程、来客信息隐藏以及切出界面查阅资料的原则继续有效，但不再产生时间成本含义。

Reason: V1 应优先验证店内对话、人物判断、器物鉴定、议价和延迟后果能否构成有吸引力的经营循环。继续设计内部时长、外出日程和活动中断会扩大范围，并把体验推向当前不希望采用的时间管理或回合制经营。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed for V1

Open Boundary: 上午与下午来客的具体分布、午间过场的最终界面，以及 Post-V1 是否重新引入连续时间与店外活动，留待内容设计、UX Flow 和后续版本评审。

## DEC-057
Date: 2026-09-04

Decision: V1 采用“重要剧情节点由设计者编排，常规经营案件由 Game Core 生成或选取，具体交谈由 LLM 表达”的店内剧情经营结构。剧情推进不采用“每天至少一次”的硬性配额；剧情客人、消息、旧交易回访或爷爷线索可以隔数日出现，也可以在关键阶段连续数日出现。是否触发必须依据 Game Core 中已经定义的事件条件与内容安排，LLM 不得为了填充当天剧情而自行创造权威事件。

Reason: 让故事节奏能够在铺垫、日常经营和连续高潮之间变化，避免每日强制剧情造成机械感，同时保留每个重要故事节点的可控性和可测试性。

Affected Docs: [[CORE_LOOP]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]]

Status: confirmed direction

Open Boundary: 连续多少个纯经营日会导致叙事停滞、每个章节需要多少重要剧情节点，以及哪些条件可以让剧情连续多日推进，留待 Event Model 和具体章节样例验证。

## DEC-058
Date: 2026-09-05

Decision: V1 中，没有重要剧情推进的纯经营日必须具有一个由 Game Core 选择的数据化经营主题，使当天在来客构成、器物类别、交易动机、市场话题或氛围上形成可感知差异。剧情日可以在内容兼容时附带经营主题，但不强制。主题只在来客和案件生成前调整候选内容权重，不保证利润、捡漏或特定交易结果，不改变已经生成的器物真相、NPC 隐藏状态和权威事件。玩家通过开场信息、传闻、客人谈话和来客构成获得模糊信号，不查看后台倍率或最优策略提示。LLM 只能表达 Game Core 已选择和授权的主题。

Reason: 让没有主线推进的营业日仍然具有辨识度和经营预期，同时保留不确定性，避免主题退化为每日任务、答案提示或固定获利窗口。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed direction

Open Boundary: V1 的主题库包含哪些主题、主题如何根据世界与店铺状态选择、多久可以重复、权重影响强度，以及玩家能够看到多明确的提示，留待 Event Model 与具体营业日样例验证。

## DEC-059
Date: 2026-09-05

Decision: V1 的经营主题采用世界驱动与玩家驱动的混合来源，并允许 Game Core 在条件兼容时组合。世界驱动来源包括已经成立的市场趋势、城市传闻、行业事件、季节性需求和剧情阶段；玩家驱动来源包括公开陈列、历史成交表现、已形成的类别口碑、NPC 关系和已经传播的事件结果。玩家的隐藏库存、尚未被发现的真假问题、未传播交易事实及其他外界不可能知道的状态不得用于吸引对应客人或生成外界传闻。玩家形成某类经营口碑后，主题可以同时增加相关买家、普通卖家、试探者和风险交易的候选权重，不构成单向正反馈奖励。

Reason: 让世界变化和玩家过去的经营选择共同塑造之后的营业日，同时保持信息因果可信，避免系统利用隐藏状态作弊，也避免玩家通过重复单一品类获得无风险的滚雪球收益。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed direction

Open Boundary: 世界来源与玩家来源的选择比例、多个来源如何组合、公开与传播状态如何判定、同一来源的叠加上限，以及口碑带来的机会与风险比例，留待 Event Model 和 Relationship Model 细化。

## DEC-060
Date: 2026-09-05

Decision: V1 中，单笔普通公开交易只累积与器物类别、价格层级或经营表现相关的对外信号，不立即建立稳定口碑或必然改变次日主题；累计达到门槛后，该信号才取得玩家驱动主题的候选资格。与重要 NPC 的公开成交、相对玩家当前经营层级显著的高价值公开交易，或已经形成公开传播的重大事件，可以跳过普通累计过程并立即取得候选资格。“立即”只表示可以影响下一个尚未生成的营业日；当天来客与案件一旦生成，不得事后重排。取得资格不等于必然被选为下一日主题，最终选择和组合仍由 Game Core 决定。

Reason: 让普通经营通过长期积累产生可信口碑，同时使重大成交和关键事件具有及时反馈；主题只影响未来尚未生成的内容，可以避免状态回写、因果混乱和通过单笔交易操纵来客。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed direction

Open Boundary: 普通信号的累计门槛和衰减方式、如何按类别与价格层级分别记录、重要 NPC 的认定条件、高价值相对于当前经营层级的判定方法，以及取得候选资格后的选中概率尚未确定。

## DEC-061
Date: 2026-09-05

Decision: V1 的类别口碑由 Game Core 按器物类别保存精确内部状态，但不向玩家显示数值、百分比、进度条、档位门槛或距离下一档还需多少交易。玩家只看到四个模糊阶段：尚无名气、偶有人提起、逐渐形成口碑、在相关圈子里受到认可。阶段及其变化可以通过营业日开场、闭店摘要、市场传闻和 NPC 对话表现；单次内部数值变化不要求逐笔提示。LLM 只能使用 Game Core 授权的当前阶段、变化方向和可公开原因，不得推算或泄露精确进度。

Reason: 让玩家能够理解长期经营方向和行为反馈，同时避免类别经营变成刷进度条、计算固定交易次数或精确操纵来客的数值任务，并保持口碑通过世界反应被感知的沉浸感。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed for V1

Open Boundary: 四个阶段对应的内部阈值、普通信号增量、重大事件跨档限制、口碑是否衰减，以及类别口碑与全局信誉、诚信评价和 NPC 关系的关系尚未确定。

## DEC-062
Date: 2026-09-05

Decision: V1 将类别口碑、全局信誉和 NPC 关系保存为三个独立但可以受控联动的权威状态。类别口碑表示外界对玩家经营或擅长某个器物类别的认知，按类别分别记录；全局信誉表示市场对店铺整体可靠性与诚信的评价；NPC 关系表示具体人物对玩家的信任、态度和共同经历。一次交易或事件可以根据明确的对象、原因与传播范围影响一项、两项或三项，但不得使用统一声望值无差别加减，也不得根据其中一项自动推导另外两项。假货被真实发现后，Game Core 必须依据涉及类别、发现内容、买家身份、关系对象和传播圈层分别决定影响范围。

Reason: 专业名声、商业诚信和私人关系代表不同的玩家成长与后果。分开记录可以允许“懂瓷器但店铺诚信受质疑”或“市场尚无名气但某位 NPC 非常信任玩家”等有意义状态，并避免一次事件重复或过度处罚所有社会维度。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed for V1

Open Boundary: 全局信誉和 NPC 关系各自采用怎样的玩家可见阶段，哪些事件影响单项或多项，传播圈层如何把个人关系后果扩展为类别口碑或全局信誉，以及各维度对来客生成和交易行为的具体作用尚未确定。

## DEC-063
Date: 2026-09-05

Decision: V1 的全局信誉由 Game Core 保存精确内部状态，但玩家只看到四个模糊阶段：声誉受损、尚无定论、口碑稳定、值得信赖。全局信誉不显示精确值、百分比、进度条、阶段门槛或距离下一档所需行为。当前阶段及变化可以通过店铺状态、营业日开场与结算、市场传闻和普通客人的态度表现。LLM 只能使用 Game Core 授权的阶段、变化方向和可公开原因，不能根据单个 NPC 的态度推断整个市场的评价。

Reason: 让玩家能够理解店铺整体可靠性与诚信状况，同时避免通过精确数值计算信誉收益、刷固定行为或预测事件门槛，并保持全局信誉与类别口碑、个别 NPC 关系的表达差异。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed for V1

Open Boundary: 四个阶段对应的内部阈值、初始阶段、上升与下降来源、重大事件最多跨越多少阶段、是否自然恢复，以及各阶段如何具体影响普通客人的到访与交易态度尚未确定。

## DEC-064
Date: 2026-09-05

Decision: V1 的 NPC 关系由 Game Core 按具体人物保存精确内部状态，但玩家只看到五个统一阶段：防备、生疏、熟悉、信任、深交。内部数值、进度、阶段阈值和距离下一阶段所需互动不公开。五个阶段的机械含义对所有 NPC 保持一致，但具体言语、主动程度、信息透露和帮助意愿需要结合人物性格、身份与表达习惯呈现。关系阶段只是当前总体态度的摘要，不取代独立保存的具体记忆、承诺、冲突、利益条件和社会连接；高关系阶段不自动清除负面记忆，也不保证 NPC 无条件帮助玩家。

Reason: 统一阶段可以让玩家理解关系发展并让 Game Core 稳定判断条件，人物化表达则避免 NPC 变成共享同一套好感度台词。把记忆与关系阶段分开，可以保留人物行为的因果、矛盾与长期连续性。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[CHARACTERS]], [[RELATIONSHIP_SYSTEM]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed for V1

Open Boundary: 五个阶段对应的内部阈值、NPC 初始阶段、关系上升与下降来源、重大事件跨档限制、是否自然变化，以及关系阶段、具体记忆和人物利益共同决定行为的优先级尚未确定。

## DEC-065
Date: 2026-09-05

Decision: V1 的标准营业日在上午和下午各安排 2～3 名客人，总计约 4～6 名。4 名客人时采用上午 2 名、下午 2 名；5 名时采用 2/3 或 3/2，由 Game Core 根据当天买卖组合、剧情、经营主题和节奏决定哪一段安排 3 名；6 名时采用上午 3 名、下午 3 名。全日仍保持卖货客人 2～3 名、买货客人 2～3 名，但不为每个阶段分别设置买卖类型配额。剧情、后果回访和其他特殊客人默认占用标准名额；只有 Game Core 明确标记的重要剧情例外可以突破单阶段或全日人数范围。

Reason: 保证上午与下午都有足够内容形成清晰节奏，同时让 5 人营业日和买卖顺序保持变化；特殊内容优先替换常规来客可以控制每日对话总量，受控例外则保留剧情打破日常节奏的能力。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed for V1

Open Boundary: 5 人营业日决定 2/3 或 3/2 的具体权重、买卖类型连续出现的上限、重要剧情例外最多增加多少来客，以及这些参数是否需要随章节进度调整，留待营业日样例与试玩验证。

## DEC-066
Date: 2026-09-05

Decision: V1 的普通营业日中，全日来客序列最多连续出现 2 名同类客人，不得连续安排 3 名买家或 3 名卖家；上午与下午的阶段切换不重置连续计数。剧情节点或当日经营主题确有需要时，可以允许连续 3 名同类客人，但必须由对应事件或主题数据显式声明，并由 Game Core 在生成队列时验证。LLM 不得自行重排队列、改变客人身份或创造例外。

Reason: 允许最多 2 名可以保留自然波动和主题聚集感，禁止普通连续 3 名则避免玩家长时间只进行收购或只进行出售；跨阶段继续计数可以防止通过午间分界绕过节奏约束。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[OPEN_QUESTIONS]]

Status: confirmed for V1

Open Boundary: 允许连续 3 名同类客人的主题与剧情例外清单、例外在同一章节中的出现频率，以及连续客人是否还需要限制器物类别或交易难度重复，留待营业日样例和 Event Model 验证。

## DEC-067
Date: 2026-09-05

Decision: 除教学日或由 Game Core 明确标记的经营恢复日外，V1 每个标准营业日至少包含 1 名隐藏的判断挑战客人。判断挑战可以与买货、卖货、剧情锚点、后果回访等职责重叠，不等同于骗子、高价值器物或必然获利机会；其来源可以包括客人说法与器物线索不一致、真诚但错误的认知、买家隐藏用途或预算、库存只有弱匹配候选，以及高机会与高风险并存。Game Core 必须在交互前确定挑战来源、至少一项玩家有机会发现的有效线索、能够利用线索的相关行为和具有差异的可能结果。线索不保证完全确定、必然被发现或保证成功，但不得形成无证据随机猜测、无条件强制失败或由 LLM 临时创造矛盾。挑战标签及具体来源不向玩家展示；LLM 只能表达 Game Core 授权的线索、隐瞒和不确定性。

Reason: 每个标准营业日都应稳定提供一次“通过交谈和器物信息作判断”的核心体验，同时保持现实中的不确定性。允许挑战与其他内容职责重叠可以控制每日对话总量；隐藏标签并要求有效线索，可以避免玩家把特殊客人当成固定考题，也防止挑战退化为猜硬币或系统强制反转。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed for V1

Open Boundary: 标准营业日每天最多安排多少名判断挑战客人、挑战强度如何随章节成长、同类挑战的重复限制、首批挑战类型库，以及各类挑战的最小有效线索标准尚未确定。

## DEC-068
Date: 2026-09-05

Decision: V1 普通标准营业日安排 1～2 名判断挑战客人，不得让当天全部 4～6 名客人都成为判断挑战。教学日和由 Game Core 明确标记的经营恢复日允许为 0 名。重要剧情日确有需要时最多可以安排 3 名，但必须由剧情数据显式声明例外及原因，并由 Game Core 在生成队列时验证；LLM 不得自行提高数量或把普通客人升级为挑战。

Reason: 1～2 名可以稳定提供核心判断体验，同时保留普通交易作为节奏和难度对比，避免每名客人都带反转而造成持续警戒、对话疲劳和挑战贬值。教学与恢复日需要降低认知压力，剧情日则保留受控提高密度的空间。

Affected Docs: [[CORE_LOOP]], [[GAME_RULES]], [[EVENT_SYSTEM]], [[WORLD_STATE]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[UX_FLOW]], [[OPEN_QUESTIONS]]

Status: confirmed for V1

Open Boundary: 挑战强度如何随章节成长、同类挑战的重复限制、首批挑战类型库，以及各类挑战的最小有效线索标准尚未确定。

## DEC-071

Date: 2026-09-06

Decision: 沉浸式原型的场景入口采用“场景热点＋邻近悬停提示＋键盘聚焦”表达；人物对白区可以收起，当前会面摘要、会面状态和历史显示开关独立存在。经营记录、剧情调查、人物往来、器物判断在笔记中分栏，不把私人鉴定、系统结算或剧情选择伪装成人物对白。报价使用整数输入，实际钱货交割仍须玩家明确确认。每个剧情相关 NPC 都由故事数据提供可选的情境问题和快捷按钮；按钮只授权针对已取得线索的提问，不直接解决剧情节点，玩家仍可自由交谈。

Reason: 用户试玩显示，原型的主要障碍不是缺少功能，而是玩家无法稳定判断“场景上哪里能做什么、眼前这段信息属于谁、剧情下一步在哪里”。统一的信息层级和 NPC 提问入口能够降低认知负担，同时保留通过自由对话判断人物意图的不确定性。把快捷按钮限制为提问授权，可以让 LLM 获得明确边界而不替 Game Core 作决定。

Affected Docs: [[CORE_LOOP]], [[UX_FLOW]], [[EVENT_SYSTEM]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[IMMERSIVE_REVISION_PLAN]], [[IMMERSIVE_REVISION_ACCEPTANCE]]

Status: confirmed for immersive prototype revision

Boundary: 本决策不锁定正式 V1 的最终视觉布局、字体、素材风格或完整 UI 导航；热点位置、提示文案、笔记字段和剧情问题仍需通过用户试玩迭代。情境按钮不得成为唯一的剧情入口，也不得泄露未授权隐藏状态。

## DEC-072

Date: 2026-09-08

Decision: 沉浸式原型采用“探索场景”和“交谈场景”两种视觉状态。探索时显示简洁地点或家具入口；交谈时隐藏热点并压暗背景，让人物、当前器物和聊天成为前景。会面资料与新手提问默认收起，对话区自动跟随最新消息；请求期间先显示思考状态，完整回复到达后再逐字呈现。拍卖每场提供 6～8 件图录、可标记关注、2～4 名可观察竞买人，并按单件顺序进行举牌、跳过或离场。

Reason: 两轮试玩表明，场景热点、资料按钮和系统信息同时出现会遮挡人物与物件，并压缩真正的交谈空间。拍卖只有单件弹窗时也无法形成预展、观察他人和选择性参与的场景体验。

Affected Docs: [[UX_FLOW]], [[IMMERSIVE_REVISION_PLAN]], [[IMMERSIVE_REVISION_ACCEPTANCE]], [[PLAYTEST_NOTES]]

Status: confirmed for immersive prototype revision

Boundary: 这是原型交互与内容规模，不锁定正式版拍卖数值、竞买人算法、最终美术布局或生产架构。拍品、竞价与结算仍由 Game Core 决定；LLM 不得改变价格、物权或竞争结果。

## DEC-073

Date: 2026-09-08

Decision: 沉浸式原型的交易交谈界面采用对话优先结构。会面资料和提问提示使用不参与纵向排版的临时浮层；完整本次对话默认保留，界面提供回到最新而不隐藏历史；金额编辑器只在玩家主动开始议价或 Game Core 推进到报价阶段后出现。普通提问提示使用自然口语完整句，点击后先填入输入框供玩家修改与确认。新的私人判断只短暂出现在当前器物附近，随后由“判断”入口的未读圆点提示，打开该物件详情后清除。

Reason: 第三轮试玩显示，资料、提示、报价和判断即使默认收起，只要仍作为常驻纵向模块，就会持续争夺对话空间，使玩家无法回看 NPC 前后说法。对话是识人和交易判断的核心玩法，因此必须拥有稳定的主要显示区域；其他工具应按情境临时出现。

Affected Docs: [[UX_FLOW]], [[IMMERSIVE_REVISION_PLAN]], [[IMMERSIVE_REVISION_ACCEPTANCE]], [[PLAYTEST_NOTES]]

Status: confirmed for immersive prototype revision

Boundary: 此决定确认信息层级和交互时机，不锁定最终像素尺寸、配色、动效时长或生产版响应式断点。提问提示不得泄露隐藏答案，判断未读标记不得改变或暗示 Game Core 的权威真相。

## DEC-074

Date: 2026-09-09

Decision: 向买家推荐器物的开场介绍与后续回答建议，必须在显示或发送前根据该器物最新的玩家已知判断实时重建。观察、鉴定或复核改变判断后，不得继续使用选择器物时缓存的旧模板。建议只能使用 Game Core 授权的确定类别、已发现线索、玩家当前年代与品相判断、来源记录状态及买家已公开需求；不得读取权威隐藏真相，也不得自动向买家说出私人真品概率。概率转换为自然的不确定表达，明确判假时系统建议不再把器物作为真品介绍；玩家仍可编辑建议或自由输入。

Reason: 推荐话术如果不随判断更新，会让对话与玩家刚刚完成的鉴定脱节，也可能把旧结论错误地继续说给买家。实时重建能够让鉴定真正参与交易表达，同时维持 Game Core 决定事实、LLM与界面只解释玩家已知状态的边界。

Affected Docs: [[UX_FLOW]], [[ANTIQUE_SYSTEM]], [[AI_BOUNDARIES]], [[LLM_DESIGN]], [[IMMERSIVE_REVISION_ACCEPTANCE]]

Status: confirmed for immersive prototype revision

Boundary: 本决策不锁定最终话术数量、语气分类或措辞；系统建议不得替玩家作出出售决定，也不得把未发现线索或隐藏真伪加入介绍。
