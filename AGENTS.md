# Agent 工作规则

1. `docs/` 是游戏设计的主要事实来源。
2. Agent 不能自行改变已经 `locked` 的游戏规则。
3. Code 与 locked docs 冲突时，以 docs 为准。
4. 实现功能前必须读取相关设计文档。
5. 如果设计不明确，不得偷偷创造永久规则。
6. 未确定内容应记录为 Open Question。
7. 所有 World State 修改最终必须经过 Game Core。
8. LLM 不能直接修改权威游戏状态。
9. 每个开发 Task 必须拥有明确 Acceptance Criteria。
10. 实现 Task 后必须报告 Changed Files / Tests / Deviations / Known Issues。
11. 避免把故事文本硬编码进 Game Core。
12. 优先采用数据驱动设计。
13. 当前阶段禁止实现实际游戏代码，除非后续 Task 明确要求。

## 工作流

Human Designer → Obsidian Design Docs → Task Spec → Agent → Code → Tests
