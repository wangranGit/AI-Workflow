# AI-Workflow 模版版本发布历史 (Changelog)

本文档记录 AI-Workflow 通用商业级研发流水线模版的版本迭代历史。

---

## [v1.0.0] - 2026-11-06

### 新增功能
- **十步协同刚性状态机**：立项、澄清、AC标准、架构设计、分支隔离开发、独立代码审查、本地自动化门禁、人工验收、任务归档、代码合入。
- **三角色专职代理分工**：
  - `Pipeline Orchestrator`（总控架构师规范与技能）
  - `Component Coder`（专职开发子代理规范，单文件行数受控，0 测试代码侵入）
  - `Code Reviewer`（专职独立只读审查代理，七维盲审，一票否决制）
- **一键接入与更新工具集**：
  - `scripts/setup.sh`：新工程一键快速接入脚本；
  - `scripts/update.sh`：无损增量平滑升级脚本（核心更新，业务配置与进度保护）；
  - `scripts/verify_workflow.sh`：敏感标识与第三方商标合规自动化校验脚本。
- **通用文档与门禁模版**：
  - `templates/AGENTS.template.md`（参数化项目级规则模版）
  - `templates/DOCS/ARCHITECTURE.template.md`（系统架构 RFC 模板）
  - `templates/DOCS/PROGRESS.template.md`（任务追踪看板）
  - `templates/DOCS/PIPELINE_METRICS.template.md`（流水线指标度量与架构纠偏教训台账）
  - `templates/gates/Makefile.template`（秒级自动化本地门禁入口）
