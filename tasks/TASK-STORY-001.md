---
title: TASK-STORY-001 Story and Quest Documentation Architecture
status: review
owner: agent
last_reviewed: 2026-09-07
---

# TASK-STORY-001

## Goal

基于现有设计文档与第一章原型内容，建立适合在 Obsidian 中浏览、扩写和监督的系统化剧情与任务文档架构。

## Design Sources

- [[GAME_VISION]]
- [[DESIGN_PILLARS]]
- [[CORE_LOOP]]
- [[GAME_RULES]]
- [[WORLD]]
- [[CHARACTERS]]
- [[EVENT_SYSTEM]]
- [[WORLD_STATE]]
- [[AI_BOUNDARIES]]
- [[CHAPTER_ONE_SPEC]]
- [[CHAPTER_ONE_RESEARCH]]
- [[IMMERSIVE_REVISION_PLAN]]
- [[DECISIONS]]

## Scope

- 剧情总入口与状态图例。
- 故事母题、创作红线与事实分层。
- 长线故事功能槽位与篇章曲线。
- 任务类型、节点模型、分支原则与标准模板。
- 玩家、爷爷及第一章八名 NPC 的人物弧管理。
- 第一章证据链、十日节奏、节点与收束映射。
- 浪漫、宏伟且带人物化幽默的文风规范。
- 剧情专属 Open Questions。

## Out of Scope

- 不实现或修改游戏代码、数据与 World State。
- 不锁定第一章之外的具体主线、章名、城市名、爱情线或最终结局。
- 不修改既有 confirmed/locked 规则。
- 不替代现实古玩研究与法律意见。

## Acceptance Criteria

- [x] 不改变任何 locked/confirmed 规则。
- [x] 建立剧情总纲、人物弧、章节/任务层级与任务模板。
- [x] 文档可从 `docs/INDEX.md` 与 `docs/04_Story/STORY.md` 导航。
- [x] 事实、提案和 Open Question 有清晰状态边界。
- [x] 第一章 8 人、10 日、8 个故事节点与 3 种收束均被映射。
- [x] 所有权威状态继续由 Game Core 结算，LLM 只负责授权表达。
- [x] 只修改 Markdown 设计/任务文档，不实现游戏代码。
- [ ] Human Designer 审阅并确认母题、长线槽位与文风方向。

## Files Allowed To Change

- `docs/INDEX.md`
- `docs/04_Story/*.md`
- `tasks/TASK-STORY-001.md`

## Tests

- 检查所有新增 Obsidian wikilink 目标存在。
- 检查 Markdown frontmatter 与标题。
- 检查 Git diff 未包含代码或数据文件。
- 人工核对第一章规格与两份原型内容数据。

## Result

### Changed Files

- 更新：`docs/04_Story/STORY.md`、`docs/INDEX.md`。
- 新增：`STORY_BIBLE.md`、`MASTER_STORY_ARC.md`、`QUEST_ARCHITECTURE.md`、`CHARACTER_ARCS.md`、`CH01_OLD_DEBTS.md`、`NARRATIVE_STYLE_GUIDE.md`、`STORY_OPEN_QUESTIONS.md`、`QUEST_TEMPLATE.md`。
- 新增本任务记录：`tasks/TASK-STORY-001.md`。

### Tests

- Wikilink/frontmatter 临时检查脚本：通过，共检查 11 个剧情/任务文件；临时脚本已删除。
- `git diff --check`：本轮跟踪文件通过；新增文件除正常 `--no-index` 差异退出码外无空白错误。
- 人工内容核对：第一章 8 名 NPC、10 个营业日、8 个故事节点、3 种收束与原型数据一致。
- Scope 检查：未修改代码、JSON 数据或权威 World State。

### Deviations

长期主线只建立功能槽位，未擅自编写完整主线或最终结局。

### Known Issues

- 第一章 `catalogue` 前置条件在章节数据与沉浸式调查数据之间不一致。
- 部分拒绝选项的永久关闭范围及十日后延期回收尚未定义。
