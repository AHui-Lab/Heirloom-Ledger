---
title: TASK-STORY-002 历史调研与故事重构提案
status: review
owner: agent
last_reviewed: 2026-09-15
---

# TASK-STORY-002

## Goal

延续用户提出的家庭归属冲突、爷爷长期保管的责任、需要取舍的收购委托与旧日城市关系，补充可核查的历史调研，并形成可在 Obsidian 审阅的具体故事提案。

## Sources and Scope

- 设计依据：[[STORY]]、[[STORY_BIBLE]]、[[MASTER_STORY_ARC]]、[[CHARACTER_ARCS]]、[[QUEST_ARCHITECTURE]]、[[NARRATIVE_STYLE_GUIDE]]、[[STORY_OPEN_QUESTIONS]]、[[GAME_VISION]]、[[WORLD]]、[[GAME_RULES]]、[[EVENT_SYSTEM]]。
- 外部依据：博物馆、故宫博物院院刊、UNESCO 的公开资料，来源写入研究文档。
- 产出：历史素材研究、具体主线候选、首条交易故事、分支代价、长线变化与待决问题。
- 修改范围：Markdown 剧情文档与本任务记录；既有实现与原型数据不在任务范围。

## Acceptance Criteria

- [x] 至少整理 4 个有来源的素材，每个区分史实、创作推导和不可直接套用之处。
- [x] 新提案明确保留用户表达的创作偏好，同时不把讨论中的方案当作已确认设定。
- [x] 形成包含人物诉求、交易因果、证据边界、不同结果和后续回响的具体故事。
- [x] 检查南迁背景与爷爷年龄的代际衔接。
- [x] 明确与既有第一章的关系，避免两份文档同时声称不同内容是事实。
- [x] 新文档可从剧情总入口访问，待决事项有稳定编号。
- [x] 完成链接、空白与变更范围检查，报告 Changed Files / Tests / Deviations / Known Issues。

## Result

### Changed Files

- 新增 `docs/04_Story/HISTORICAL_STORY_RESEARCH.md`：五组来源、创作转化和研究边界。
- 新增 `docs/04_Story/STORY_REBUILD_PROPOSAL.md`：梗概、人物利益、七个节点、五类结果、后续案件与两段样稿。
- 更新 `docs/04_Story/STORY.md`：本轮审阅入口。
- 更新 `docs/04_Story/STORY_OPEN_QUESTIONS.md`：SR-001 至 SR-006。
- 新增本任务记录。

### Tests

- 临时 Node 检查：5 个文件、52 个 wikilink 目标、frontmatter 和行尾空白全部通过；检查脚本随后移除。
- 跟踪文件的定向 `git diff --check` 通过；Git 提示既有环境的 LF/CRLF 转换，不影响内容检查。
- 对照编辑前后的状态，本轮只新增或修改上述 5 个 Markdown 文件；用户已有原型、UI 与其他设计变更未纳入本任务。
- 人工审阅：历史事实与原创设想有分隔；人物知情和证据局限明确；V1 未引入外出或时间消耗规则。
- 首次内联 Node 命令因当前 shell 的引号处理失败，改用临时脚本后验证通过；未产生内容变更。

### Deviations

- 无任务范围偏离。研究与重构以独立候选文档呈现，不将未确认情节覆盖到既有第一章。

### Known Issues

- 湖南博物院展品页直接打开失败，本轮仅采用可检索官方摘要中的有限事实，已在研究正文标记。
- 城市、时代、器物工艺与完整权利链尚未确定；需按 SR 编号继续审阅与针对性研究。
- 新方向与愿景中“爷爷的良苦用心”存在表述张力，确认方向后需同步处理。
- 既有第一章数据一致性问题未在本任务中复测或修复；见前次任务及第一章文档。
