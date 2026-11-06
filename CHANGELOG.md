# AI-Workflow 模版版本发布历史 (Changelog)

本文档记录 AI-Workflow 通用商业级研发流水线模版的版本迭代历史。

---

## [v1.1.0] - 2026-11-06

### 新增与升级功能
- **升级 `scripts/update.sh`**：
  - 支持自动检测模版仓库的 Git 远程并执行 `git pull` 获取最新提交；
  - 新增 **下游规则变更差异看板 (Workflow Diff Summary)**，升级前清晰展现规则变更点；
  - 维持对 `workflow.config.json` 与业务任务文档的严格保护，生成 `AGENTS.md.bak` 备份。
- **新增 `scripts/sync-upstream.sh`**：
  - 支持业务项目将通用优化安全反哺至上游模版仓库；
  - 内置 **零商业标识与侵权商标强拦截 (Zero-Leak Check)**，阻断业务私有词汇外泄；
  - 自动在模版仓库切出独立贡献分支（`contrib/<project>_<timestamp>`），主干分支 100% 隔离。
- **升级 `scripts/verify_workflow.sh` 为全功能自动化 CI 门禁矩阵**：
  - 集成**多工程沙盒矩阵兼容性测试 (Sandbox Matrix Test)**；
  - 自动化验证 Case 1（全新工程接入）、Case 2（老工程升级与配置不被冲断言）、Case 3（反向同步与分支隔离）。

---

## [v1.0.0] - 2026-11-06

### 初始发布
- 十步协同刚性状态机（需求澄清、契约冻结、分支隔离、七维盲审、本地门禁、双层文档）；
- 三角色专职协同规范（Orchestrator、Component Coder、Code Reviewer）；
- 一键初始化脚本 `scripts/setup.sh`。
