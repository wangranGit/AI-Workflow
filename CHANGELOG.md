# AI-Workflow 模版版本发布历史 (Changelog)

本文档记录 AI-Workflow 通用商业级研发流水线模版的版本迭代历史。

---

## [v1.2.0] - 2026-11-06

### 新增五角色协同矩阵架构 (5-Agent Architecture)
- **新增 `unit-tester.md` (专职单测质量对抗代理)**：
  - 彻底终结 Coder 自产自查的“确认偏差”；
  - 运行机制：**模式 B（双盲对抗验收模式）**，严格基于 Step 3 AC 标准与 Step 4 公开契约独立设计编写极端边界、故障注入、并发竞态与冷启动恢复单测。
- **新增 `doc-architect.md` (专职技术文档架构代理)**：
  - 终结文档简略流水账与形式主义；
  - 专职沉淀**三层全景活字典**：
    1. 宏观进度与指标台账 (`DOCS/PROGRESS.md` & `DOCS/PIPELINE_METRICS.md`)；
    2. 全局架构 DAG 依赖图与分层图 (`DOCS/ARCHITECTURE.md`)；
    3. 微观模块级深入设计：在 `DOCS/MODULES/<MODULE>_DESIGN.md` 中强制产出 Mermaid 时序图、公开 Protocol 字典、状态机跃迁与存储表结构。
- **升级 `component-coder.md`**：剥离单测编写职责，专注高内聚低耦合纯净业务代码实现与单一职责（文件 < 500 行）。
- **更新流水线状态机与门禁**：
  - 更新十步流水线为五角色协同拓扑；
  - 更新 `scripts/verify_workflow.sh` 包含 20 项模版资产的沙盒矩阵验证。

---

## [v1.1.0] - 2026-11-06

### 自动化双向工具链升级
- **升级 `scripts/update.sh`**：支持自动检测模版仓库的 Git 远程并执行 `git pull`，渲染下游变更差异看板；
- **新增 `scripts/sync-upstream.sh`**：支持业务项目将通用优化安全反哺至模版仓库，带零标识拦截与贡献分支隔离；
- **升级 `scripts/verify_workflow.sh`**：全功能 CI 沙盒矩阵测试（全新接入、升级保护、反哺隔离）。

---

## [v1.0.0] - 2026-11-06

### 初始发布
- 通用商业级研发十步流水线与九大红线；
- 自动化本地秒级门禁 `Makefile`；
- 一键初始化脚本 `scripts/setup.sh`。
