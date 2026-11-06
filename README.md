# AI-Workflow: 通用商业级 AI 增强型研发生命周期脚手架模版

> 面向生产级交付质量的通用 AI 协作研发生命周期治理框架。通过**刚性十步协同状态机**、**三角色专职代理分工**、**客观七维盲审一票否决制**与**本地自动化门禁**，彻底根除大模型在编码场景下的“幻觉编码、代码膨胀、自审自编、破坏架构、测试侵入”等系统性缺陷。

---

## 🌟 核心设计理念

1. **确定性规约 (Strict SOP)**：将软件工程划分为标准化的 10 步生命周期，步步有卡点、步步有证据；
2. **多代理专职协同 (Orchestrator-Workers Architecture)**：
   - **Orchestrator (总控架构师)**：负责需求对齐、契约冻结、分支管理与门禁调度，**严禁总控直接改业务源码**；
   - **Component Coder (专职开发代理)**：窄上下文作业，专注遵循 Protocol 契约，单文件不超过 500 行，生产代码 0 测试入侵；
   - **Code Reviewer (独立客观审查代理)**：只读权限，执行七维盲审与**一票否决制**。
3. **零 Token 机械门禁**：单元测试、语法检查与代码静态分析必须由本地原生工具链秒级完成，杜绝浪费 Token 当编译器。
4. **全生命周期可观测性**：基于指标文档全流程追踪主干污染率、代码行数警戒、审查拦截率及用户纠偏教训台账。

---

## 🚀 极简接入指南 (新项目使用)

### 方式 1：本地直接执行接入 (推荐)
在你的新工程根目录下运行以下命令（传入 AI-Workflow 模版目录路径）：
```bash
/path/to/AI-Workflow/scripts/setup.sh
```
或者在当前目标项目目录下直接指定运行：
```bash
bash /Users/wangran/Desktop/AI-Workflow/scripts/setup.sh .
```

### 方式 2：托管至 Git 远程仓库后通过 curl 接入
将本模版仓库 Push 到团队 Git 仓库（如 GitLab / GitHub）后，新项目仅需一行命令：
```bash
curl -fsSL https://<your-git-host>/AI-Workflow/raw/main/scripts/setup.sh | bash
```

### 接入后自动就绪的资产：
- ✅ `AGENTS.md`：根目录总控规则（自动适配项目名、主干分支、门禁指令与行数阈值）；
- ✅ `workflow.config.json`：项目级研发配置文件；
- ✅ `.agents/`：专职 Coder 与 Reviewer Prompt、治理法则及流水线技能；
- ✅ `DOCS/`：系统架构设计、任务追踪看板、流水线指标与 RFC 模板；
- ✅ `Makefile`：本地秒级自动化门禁入口。

---

## 🔄 平滑升级指南 (模版如何演进更新)

当上游 AI-Workflow 模版发布新版本（Prompt 调优、新审查维度、规则优化）时，下游项目可无损升级：

在项目根目录下执行：
```bash
bash /path/to/AI-Workflow/scripts/update.sh
```

### 升级保护策略：
- 🛡️ **绝对保护（不覆盖）**：
  - `workflow.config.json`（保留项目已配置的门禁命令与自定义规则）
  - `DOCS/PROGRESS.md`（保留项目实际任务看板）
  - `DOCS/ARCHITECTURE.md`（保留项目实际架构文档）
  - `DOCS/PIPELINE_METRICS.md`（保留项目历史度量与纠偏台账）
- 🔄 **自动同步更新**：
  - `.agents/agents/`（更新最新开发与审查 Subagent Prompt）
  - `.agents/rules/`（更新最新治理红线与调度协议）
  - `.agents/skills/`（更新最新自检与度量技能）
  - `AGENTS.md`（以最新模板重新渲染，原文件自动备份为 `AGENTS.md.bak`）

---

## ⚙️ 配置文件字典说明 (`workflow.config.json`)

```json
{
  "projectName": "MyProject",          // 项目名称
  "projectType": "general",            // 工程类型 (general / swift / go / node / python)
  "version": "1.0.0",                  // 配置文件版本
  "git": {
    "mainBranch": "main",              // 主干分支名称 (受保护分支)
    "featureBranchPrefix": "feature/", // 功能分支前缀
    "fixBranchPrefix": "fix/"          // 修复分支前缀
  },
  "gate": {
    "command": "make check",           // 自动化门禁命令 (秒级执行)
    "timeoutSeconds": 30               // 门禁执行超时限制
  },
  "quality": {
    "maxFileLinesWarning": 500,        // 单文件代码行数警告阈值
    "maxFileLinesError": 800,          // 单文件代码行数强制拆解阈值
    "requireSevenDimensionReview": true,// 必须由独立审查代理七维盲审
    "disallowSilentErrorSwallowing": true // 严禁无日志吞没异常
  },
  "observability": {
    "enablePersistentMetrics": true,   // 启用指标追踪与教训台账
    "metricsFile": "DOCS/PIPELINE_METRICS.md"
  }
}
```

---

## 🛡️ 零商业标识与合规保障

本模版已内置自动化合规检查工具，严禁任何业务特定标签或第三方侵权商标：
```bash
bash scripts/verify_workflow.sh
```
确保全生命周期交付的通用性、中立性与可移植性。
