---
title: Dev Workflow — Multi-Model Pipeline
status: draft
owner: human
last_reviewed:
scope: 开发流程文档（不改变任何 locked 游戏规则；被本仓库事实源规则约束）
---

# DEV_WORKFLOW — 试玩反馈改版的多模型分层协作工作流

> 目标：在「试玩 → 反馈（文字+截图）→ 意图识别 → 修改 → 验证 → 新试玩包」闭环中，
> 用不同成本/能力的模型承担不同角色，把贵模型（Kimi K3）只花在**决策点**上，
> 便宜模型（DeepSeek V4 Flash 系）承担高频跑腿，Codex Plus 订阅作为**固定成本池**承接重活编码。

## 1. 背景与核心原则

- 试玩反馈里的任务**思维浓度差异极大**：截图意图识别、条目归类、改数据是"跑腿"；
  优先级排序、跨系统权衡、会触碰 locked 规则的决策是"思考"。
- 贵模型贵在输入/输出 token（K3 ≈ Flash 输入 ×21、输出 ×54，见 §2），**上下文长度同样付费**：
  喂给贵模型的文档越多越贵，裁剪上下文与选模型同等重要。
- 原则一：**默认走便宜模型，逐级升级（escalation ladder）**，贵模型只处理少数派。
- 原则二：**机器能免费验证的绝不花钱给模型验证**（本地回归、截图检查是免费的）。
- 原则三：Codex Plus 是订阅制固定成本 → 编码执行尽量先用它，把按量付费的额度留给它覆盖不了的任务。
- 原则四：生图与 LLM token 预算**分开管理**；先判断"是否真的需要新图"，能复用/裁切就不生图。

## 2. 可用资源盘点（本机实测，2026-09）

### 2.1 按量付费 LLM（已在 DeepSeek Harness 接入）

| 资源 | Harness provider / model id | 能力 | 输入↔输出 $/1M token（Harness 内置价格目录） | 定位 |
|---|---|---|---|---|
| DeepSeek V4 Flash | `deepseek-official` / `deepseek-v4-flash` | 文本；思考档 low/high/max | 0.14 / 0.28（缓存读 0.0028） | **执行者/跑腿**（默认） |
| DeepSeek V4 Flash Vision Exp | `deepseek-official` / `deepseek-v4-flash-vision-exp` | 文本+**图像输入** | flash 量级（需实测） | 反馈录入、截图意图识别 |
| DeepSeek V4 Pro | `deepseek-official` / `deepseek-v4-pro` | 更强推理/agentic 编码 | 0.435 / 0.87 | 中档升级位（执行遇难） |
| Kimi K3 | `kimi-coding` / `k3` | 文本+图像；1M ctx；自适应思考（low/high/max） | 3 / 15（缓存读 0.3） | **决策者**（版本级思考） |
| Kimi K3-256K | `kimi-coding` / `k3-256k` | 文本+图像；256k ctx | 目录成本为 0 → **待验证**（可能套餐/另类计费） | 待定（见 Open Questions） |
| Kimi For Coding（K2.7 Code） | `kimi-coding` / `kimi-for-coding` | 文本+图像；256k ctx；编码优化 | 0.95 / 4（缓存读 0.19） | 编码执行升级位 |
| Kimi For Coding HighSpeed | `kimi-coding` / `kimi-for-coding-highspeed` | 同上，更快 | 1.9 / 8 | 同上（要速度时） |

注：
- 价格来自 Harness 内置 `pi-ai` 价格目录快照（2026-08），是**估算锚点**，实际账单以服务商为准，
  需在 §6 计量中回填校准。DeepSeek/Kimi 均开启上下文缓存可显著摊薄重复读取（见 §5）。
- Kimi `kimi-coding` provider 的 base URL 是 `https://api.kimi.com/coding`（编程向计费口径），
  与开放平台 `platform.kimi.com`（当前提供 `kimi-k3` / `kimi-k2.7-code` / `kimi-k2.7-code-highspeed` / `kimi-k2.6`）口径不同，不能混用。
- 文本类任务**别用贵模型看图**：只有 `deepseek-v4-flash-vision-exp`、`k3`、`kimi-for-coding` 支持图像输入。

### 2.2 订阅制（固定成本池）

| 资源 | 现状 | 定位 |
|---|---|---|
| Codex Plus（OpenAI 账户） | CLI `codex 0.153.4` 可用，pinned 路径 `C:\Users\cyh\AppData\Local\OpenAI\Codex\bin\27d6a192e9c98618\codex.exe`（npm 全局 shim 已损坏，勿用）；当前模型 `gpt-6-astra` | **编码主力**：纯代码补丁、测试脚本 |

脚本化调用要点（已实测 help）：
`codex exec -C <repo> [-m gpt-6-astra] [-s workspace-write] -c 'sandbox_permissions=[...]' "<task>"`，
可用 `--json` / JSON Schema 拿结构化结果；本仓库在 Codex 配置里已是 trusted 项目。
⚠️ 订阅有**速率/周限额**，超限后自动回落到 `kimi-for-coding` / `deepseek-v4-pro` lane。

### 2.3 图像生成：尚未接入（Open Question）

候选（需你开通后实测官方单价并回填路由表，第三方量级参考）：
- **火山方舟 / 即梦 Seedream 系列**：国内 API，文生图常规尺寸约几分～几毛/张，图生图/高清档约 0.2～0.5 元/张（第三方文章量级，非官方报价）。
- **硅基流动 SiliconFlow**（FLUX.2 / FLUX.1 Kontext 等开源权重托管）：通常更便宜，风格批量出图友好。
- Kimi 开放平台当前目录为对话/视觉/编程模型，**未见公开文生图 API**；其视觉仅作理解输入，不顶替生图。

参考：[Kimi 平台模型列表](https://platform.kimi.com/docs/models) · [即梦收费标准（第三方，仅量级参考）](https://www.hsydls.com/Doc/9806.html) · [SiliconFlow FLUX.2](https://www.siliconflow.com/zh-tw/blog/flux.2-now-on-siliconflow-designed-for-real-world-creative-workflows)

## 3. 角色金字塔与默认路由

```
                    ┌───────────────────────────┐
  决策者(低频)       │ K3：版本优先级/跨系统权衡/   │  每试玩轮 ≤ 1~2 次
                    │ 会碰 locked 规则的裁决       │
                    └───────────┬───────────────┘
                    ┌───────────▼───────────────┐
  中档(按需)         │ V4-Pro / kimi-for-coding   │  执行遇难、复核存疑时
                    └───────────┬───────────────┘
  执行者(高频)       │ Flash / Flash-Vision /      │  90%+ 的调用
                    │ Codex(订阅,固定成本)          │
                    └───────────────────────────┘
```

**升级触发（至少满足一条才升档）**：
1. 意图歧义/低置信（P1 输出 confidence 低于阈值，且无法本地消除）；
2. 涉及 locked 规则 / GAME_RULES / WORLD_STATE 的语义变化（只标记，裁决仍需走 DECISIONS + 人）；
3. 需要跨 ≥2 个系统（ECONOMY / ANTIQUE / RELATIONSHIP / STORY…）做权衡；
4. 便宜执行者连续 2 轮本地回归失败。
- 生图、Codex 不在上述 token 阶梯内，独立判断。

## 4. 端到端流水线（P0 → P6）

| 阶段 | 执行者 | 输入 | 产出（仓库落点） |
|---|---|---|---|
| **P0 版本决策** | K3（决策点，每轮试玩 1 次） | 本轮全部反馈条目 + 相关设计 doc 片段 + 当前 locked 摘要 | 本轮改动优先级、冲突提示、拆单建议（追加 [[PLAYTEST_NOTES]] / 计划 doc） |
| **P1 意图识别** | Flash-Vision（图片先压缩/裁切） | 试玩反馈原文 + 截图 | 结构化条目：`category / lane / evidence / screenshot_refs / expected_vs_actual / conflict_flag / confidence` |
| **P2 规格化+路由** | Flash | P1 条目 + 相关系统 doc | 按 `tasks/TASK_TEMPLATE.md` 的任务卡（含 AC / Files Allowed / lane 标签） |
| **P3 执行** | 见 lane 表 | 任务卡 | 代码/数据/素材改动（.agent-demo 补丁镜像或直接改 prototype） |
| **P4 本地验证** | 免费机器 | 改动 | `run_checks.ps1` 八组回归 + `capture_immersive_ui.gd` 截图（需要时 Flash-Vision 复核关键帧） |
| **P5 复核** | Flash 清单自查；跨规则/疑难 → K3 | P3 改动 + 相关 doc | PASS/FAIL + 偏差清单 |
| **P6 交付+计量** | Flash（汇总） | 全程记录 | 补丁说明（PATCH_NOTES 风格：Changed Files / Tests / Deviations / Known Issues）+ 成本行（§6） |

### P3 执行 lane 表

| Lane | 任务示例 | 默认执行者 | 失败/升级 |
|---|---|---|---|
| A 代码 | GDScript 补丁、场景/UI 逻辑、回归脚本 | **Codex CLI**（订阅池） | 2 轮失败 → `kimi-for-coding` → `deepseek-v4-pro` |
| B 数据/内容 | `immersive_content.json`、文案、平衡数值、白名单 | Flash（数据模板化、批量并行） | 需叙事判断 → `kimi-for-coding` / P0 并入决策 |
| C 设计裁决 | 玩法节奏、经济、会触碰 locked | **K3**（P0 已发生，此处不重复） | 产出 DECISIONS 草稿交人确认 |
| D 生图 | 立绘/物件/场景卡 | 独立图像 API（§2.3） | 先复用裁切，确认必要才生图；重要资产才走高档位 |

### 与 AGENTS.md 的衔接（红线）

1. 任何 lane 的实现都必须遵守 docs 事实源；**locked 规则不可由 agent 改变**，P0/C 只是给人的建议，落到 `DECISIONS` 并经人确认。
2. World State 修改必须经 Game Core，agent 不直接改权威状态。
3. 任务卡必须含 Acceptance Criteria；P6 必须按模板报告 Changed Files / Tests / Deviations / Known Issues。
4. 未确认内容记 Open Question，不许在实现里偷偷造永久规则。
5. P1/P2 的可疑设计不明确时，产出问题条目交人（或并入 P0），不得凭空补全设计。

## 5. 成本控制杠杆（实施时逐条落实）

1. **上下文裁剪**：任务只带相关设计 doc 片段与相关文件，不整仓灌给模型（尤其 K3）。
2. **结构化输出 + 输出上限**：P1/P2 用 JSON Schema + 短输出；max_tokens 按任务类型设档。
3. **失败升级代替无限重试**：便宜模型单任务 ≤2 次，超了升档，不允许便宜模型空转烧 token。
4. **缓存**：DeepSeek/Kimi 上下文缓存开启；相同设计片段跨任务复用（如每任务同一段 GAME_RULES）。
5. **Codex 优先**：编码重活进订阅池，按量付费只兜底。
6. **生图独立预算** + 出图前由 Flash 判定必要性；批量小素材走廉价档，个别精修走高档。
7. **截图压缩/裁切后再发视觉模型**（按图面积计费；只裁关键区域、降到够用的分辨率）。
8. **并行节流**：琐碎子任务批量并行省时间，但按 lane 限额并发，避免突发账单。
9. **计量回填**（§6）：每任务记账，成本与误分类率用于调整 §3 阈值——两周内完成首次校准。

## 6. 计量与复盘

每个任务在结果区追加一行成本表（实施时定字段与落点）：

| 字段 | 说明 |
|---|---|
| task_id / lane / stage | 任务卡 id 与 lane（P0–P6） |
| provider / model | 实际执行模型 |
| tokens_in / tokens_out / cache_read | 输入/输出/缓存读 token |
| cost_est | 按 §2 目录估算（USD）与实际账单差额 |
| attempts | 尝试次数（升级记录） |
| verdict | PASS / FAIL / escalated |

**每周复盘**：按 lane 汇总费用占比、FAIL 率、升级率；据此调整 §3 升级触发与各 lane 默认模型。
复盘结论写入本文件或独立 COST_LOG（Open Question OQ4）。

## 7. Open Questions

- **OQ1 生图供应商与单价**：选定即梦/硅基流动/其他，实测单价后回填 §2.3 与 lane D。
- **OQ2 Codex 自动化授权**：非交互 `codex exec` 在沙箱策略（workspace-write）下的试点与周限额实测。
- **OQ3 预算上限**：每轮试玩改版 / 每月的总预算上限（默认未设，必须先定再放开自动执行）。
- **OQ4 计量落点**：成本行记录到任务卡、独立 COST_LOG、还是复用 DSH session 日志聚合。
- **OQ5 `k3-256k` 计费**：目录成本为 0 的含义（套餐/另类计费？）需实测一次确认。
- **OQ6 口径差**：`api.kimi.com/coding`（编程计费）与 `platform.kimi.com`（开放平台）价格/模型的差异是否影响 lane 分配。
- **OQ7 文档引用**：本文件定稿后，是否在 `AGENTS.md` 增加一行引用（改变 Agent 规则，需你批准）。

## 8. 下一步（经你确认后实施，顺序执行）

1. 确认本文档方向与 OQ3 预算上限。
2. 选定生图供应商（OQ1），否则 lane D 继续走"复用裁切"。
3. 在 DSH 中把本流程实现为可重复运行的 workflow 骨架（每阶段固定 provider/model，按路由表发任务）。
4. 用**最近一次真实试玩反馈**端到端试跑一轮，产出成本与误分类率，校准 §3 阈值。
5. 满足 §3 规则的任务自动闭环；含 locked 风险的任务止步于"建议"，交你裁决。

## 9. 参考

- [Kimi 开放平台模型列表与说明](https://platform.kimi.com/docs/models)（kimi-k3 / k2.7-code / k2.6）
- [Kimi API 定价（官方，以平台为准）](https://platform.kimi.com/docs/pricing/chat)
- [火山引擎即梦收费标准（第三方，仅量级参考）](https://www.hsydls.com/Doc/9806.html)
- [SiliconFlow FLUX.2 说明](https://www.siliconflow.com/zh-tw/blog/flux.2-now-on-siliconflow-designed-for-real-world-creative-workflows)
- 本机盘点来源：Harness `settings.yaml`、`.credentials.yaml`（键名）、`@earendil-works/pi-ai` 价格目录、`@deepseek-ai/dsh-llm-deepseek` 模型目录、`~/.codex/config.toml` 与 codex CLI `--help`。
