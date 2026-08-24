---
title: World State
status: draft
owner: human
last_reviewed:
---

# World State
World State 是 Game Core 管理的权威游戏状态，至少需要能够表达玩家资金、库存、知识、经验、关系、事件条件、成就及世界中的 NPC/机会状态。

示例（仅为边界示意，不是当前数据结构）：
```yaml
item_id: item_0001
category: porcelain
actual_period: late_qing
claimed_period: kangxi
authenticity: imitation
base_market_value: 3200
seller_expectation: 1800
identification_difficulty: 72
```

上述真实字段不应直接暴露给玩家或由 LLM 改写。具体 schema、持久化方式和事件状态机待定。
