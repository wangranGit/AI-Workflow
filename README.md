# AI-Workflow: 通用商业级 AI 增强型研发生命周期脚手架模版

> 面向生产级交付质量的通用 AI 协作研发生命周期治理框架。通过**刚性十步协同状态机**、**三角色专职代理分工**、**客观七维盲审一票否决制**、**本地自动化门禁**与**多工程矩阵防漂移沙盒**，彻底根除大模型在编码场景下的“幻觉编码、代码膨胀、自审自编、破坏架构、测试侵入”等系统性缺陷。

---

## 🌟 核心设计理念

1. **确定性规约 (Strict SOP)**：将软件工程划分为标准化的 10 步生命周期，步步有卡点、步步有证据；
2. **多代理专职协同 (Orchestrator-Workers Architecture)**：
   - **Orchestrator (总控架构师)**：负责需求对齐、契约冻结、分支管理与门禁调度，**严禁总控直接改业务源码**；
   - **Component Coder (专职开发代理)**：窄上下文作业，专注遵循 Protocol 契约，单文件不超过 500 行，生产代码 0 测试入侵；
   - **Code Reviewer (独立客观审查代理)**：只读权限，执行七维盲审与**一票否决制**。
3. **零 Token 机械门禁**：单元测试、语法检查与代码静态分析必须由本地原生工具链秒级完成，杜绝浪费 Token 当编译器。
4. **全生命周期双向闭环**：不仅支持下游无损拉取升级，更支持业务项目安全反哺模版，配备自动化沙盒矩阵测试彻底杜绝规则冲突与商业标识泄露。

---

## 🚀 核心工具链矩阵

| 脚本工具 | 定位与核心职责 | 安全防护与合规卡点 |
| :--- | :--- | :--- |
| **[`scripts/setup.sh`](file:///Users/wangran/Desktop/AI-Workflow/scripts/setup.sh)** | **新工程一键接入**：自动推断参数、生成配置、植入代理 Prompt、文档骨架与门禁 | 自动参数化替换占位符，耗时 < 30 秒 |
| **[`scripts/update.sh`](file:///Users/wangran/Desktop/AI-Workflow/scripts/update.sh)** | **上游模版拉取升级 (模版➔项目)**：自动拉取 Git 最新提交，同步最新规则与 Prompt | 🛡️ **严格保护**：项目级配置与业务任务文档绝不覆盖，输出差异看板并备份 `AGENTS.md.bak` |
| **[`scripts/sync-upstream.sh`](file:///Users/wangran/Desktop/AI-Workflow/scripts/sync-upstream.sh)** | **业务实践安全反哺 (项目➔模版)**：将业务项目中调优的通用规则安全推回模版仓库 | 🔍 **严格拦截**：仅同步通用 `.agents/`，自动执行零商业标识扫描，模版端切独立贡献分支 |
| **[`scripts/verify_workflow.sh`](file:///Users/wangran/Desktop/AI-Workflow/scripts/verify_workflow.sh)** | **全功能自动化 CI 门禁矩阵**：多项目协同、模版合并时的终极质检武器 | 🧪 **沙盒矩阵**：静态零标识 + 占位符完整性 + 全新接入沙盒 + 升级兼容性沙盒 + 反哺沙盒 |

---

## 📖 极简操作指南

### 1. 新项目接入
在任何新项目根目录下运行：
```bash
/path/to/AI-Workflow/scripts/setup.sh .
```

### 2. 下游项目升级模版
在已有项目根目录下运行：
```bash
/path/to/AI-Workflow/scripts/update.sh .
```
终端将自动拉取远程最新模版，并打印 **“下游规则变更差异看板 (Workflow Diff)”**。

### 3. 将项目中的工作流优化反哺回模版
当业务项目打磨了更高效的 Prompt 或审查规则，在项目根目录下运行：
```bash
/path/to/AI-Workflow/scripts/sync-upstream.sh .
```
脚本将自动执行商业敏感词拦截，并在模版仓库中生成隔离分支（如 `contrib/<project>_<timestamp>`），等待 Maintainer 审阅合入。

### 4. 模版仓库多项目合并自检 (CI Gate)
模版 Maintainer 在合并任何改动前，运行：
```bash
bash scripts/verify_workflow.sh
```
必须 4 项矩阵（零标识、契约完整性、全新接入沙盒、老项目保护沙盒）全部 100% 绿灯方可合入主干发布新版本。

---

## ⚙️ 配置文件说明 (`workflow.config.json`)

```json
{
  "projectName": "MyProject",          // 项目名称
  "projectType": "general",            // 工程类型 (general / swift / go / node / python)
  "version": "1.1.0",                  // 配置文件版本
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
