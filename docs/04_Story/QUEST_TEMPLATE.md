---
title: Quest Template
aliases:
  - 剧情任务模板
status: draft
owner: human
last_reviewed: 2026-09-07
tags:
  - story
  - template
---

# 剧情任务模板

> [!tip] 使用方法
> 复制本模板建立新任务文档。所有 `[Required]` 项在进入实现 Task 前必须填写；不明确内容写入 Open Questions，不要靠正文暗示定案。

---

## Frontmatter

```yaml
---
title:
quest_id: CH##-Q##
chapter: CH##
status: idea | draft | review | confirmed | locked
owner: human
last_reviewed:
story_functions:
  - main
  - character
  - object
  - business
  - consequence
related_characters: []
related_items: []
related_locations: []
depends_on: []
---
```

## 1. Goal [Required]

- 玩家面对的核心问题：
- 本任务的情感变化：
- 本任务为何必须可玩，而不只是一段对白：

## 2. Status Boundary [Required]

- 已确认事实：
- 本任务新增提案：
- 明确不在本任务中决定：

## 3. Dramatic Core [Required]

- 主要人物想要：
- 主要人物担心：
- 玩家眼前的诱因：
- 不能同时满足的目标：
- 器物/记录在冲突中的作用：

## 4. Truth Layers [Required]

### Objective Truth

- _待填写_

### Character Knowledge

| 人物 | 亲历 | 听闻 | 相信/怀疑 | 暂不愿说 | 绝不可能知道 |
|---|---|---|---|---|---|
| | | | | | |

### Player Knowledge

- 任务开始时：
- 可取得：
- 永不直接公开的后台信息：

### Public Knowledge

- 当前传播圈层：
- 可扩大条件：

## 5. Entry [Required]

- 入口形式：来访 / 器物 / 信件 / 电话 / 传闻 / 记录 / 回访
- 最早阶段：
- 必要旗标：
- 必要具体记忆：
- 关系/知识/资金等辅助门槛：
- 不得触发条件：

## 6. Evidence and Fairness [Required]

| 证据 | 获得方式 | 能证明 | 不能证明 | 所需能力/条件 |
|---|---|---|---|---|
| | | | | |

- 玩家至少能据以作判断的有效线索：
- 失败是否来自玩家可理解的风险：
- 是否存在无证据猜测或强制失败：否 / 需修改

## 7. Nodes [Required]

| Node ID | 场景/人物 | 前置 | 玩家行动 | Core 结算 | 即时反馈 | 后续回响 |
|---|---|---|---|---|---|---|
| CH##-Q##-N## | | | | | | |

## 8. Choices [Required]

### Choice A

- 玩家意图：
- Game Core 检查：
- 状态变化：
- 人物具体记忆：
- 当下反馈：
- 后续可能：

### Choice B

- 玩家意图：
- Game Core 检查：
- 状态变化：
- 人物具体记忆：
- 当下反馈：
- 后续可能：

### Defer / Refuse / Failure

- 暂缓是否可恢复，怎样恢复：
- 拒绝是否关闭路线，明确反馈是什么：
- 失败如何向前，不恢复哪些已失去机会：

## 9. Game Core / LLM Boundary [Required]

### Game Core Owns

- 触发条件：
- 客观事实：
- 物权/资金/库存：
- 关系、记忆、信誉与口碑：
- 旗标、随机与后果：

### LLM May Express

- _待填写_

### LLM Must Not Invent

- _待填写_

## 10. Presentation

- 已知事实栏：
- 我的疑问栏：
- 可走访方向：
- 场景主意象：
- 幽默来源：
- 禁止使用的表达：

## 11. Dependencies and Capacity [Required]

- 相关设计文档：
- 是否占用标准来客名额：
- 是否为判断挑战：
- 是否需要重要剧情例外：
- 是否涉及正式 V1 范围外玩法：

## 12. Acceptance Criteria [Required]

- [ ] 玩家能说明当前问题而不会提前知道答案。
- [ ] 至少一项证据明确写出“能证明/不能证明”。
- [ ] 所有选择都有可追踪的差异或明确被标为表达分支。
- [ ] 暂缓、拒绝与失败路径均有定义。
- [ ] 权威状态全部由 Game Core 结算。
- [ ] 人物知情范围与关系记忆可验证。
- [ ] 文本符合 [[NARRATIVE_STYLE_GUIDE]]。
- [ ] 与 [[GAME_RULES]]、[[EVENT_SYSTEM]]、[[AI_BOUNDARIES]] 无冲突。

## 13. Tests

- 条件测试：
- 分支测试：
- 存读档/幂等测试：
- 知情边界测试：
- 文本人工审阅：

## 14. Open Questions

- _待填写_

## 15. Result

### Changed Files

### Tests

### Deviations

### Known Issues
