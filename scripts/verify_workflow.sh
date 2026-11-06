#!/usr/bin/env bash
# ==============================================================================
# AI-Workflow 全功能 CI 门禁与多工程沙盒矩阵自检工具 (Verify Script - v1.2.0)
# 作为多项目更新、协同共建时的终极自动化质检武器。
# 检验维度：
# 1. 静态检测：零商业标识与第三方侵权商标检测 (Zero-Leak)
# 2. 契约检测：核心模板占位符防篡改检测 (Template Integrity)
# 3. 语法检测：所有生命周期脚本语法严格校验
# 4. 沙盒矩阵测试 (Sandbox Matrix Test)：
#    - Case 1: 全新工程首次接入测试 (Fresh Setup)
#    - Case 2: 老工程增量升级兼容性测试 (Legacy Update & Config Protection)
#    - Case 3: 业务工程安全反哺测试 (Upstream Sync & Branch Isolation)
# ==============================================================================
set -euo pipefail

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${BOLD}${BLUE}==================================================================${RESET}"
echo -e "${BOLD}${BLUE}    🛡️  AI-Workflow 全功能自动化 CI 门禁矩阵测试启动 (v1.2.0)     ${RESET}"
echo -e "${BOLD}${BLUE}==================================================================${RESET}"

# ------------------------------------------------------------------------------
# 阶段 1: 零商业标识与侵权词拦截扫描
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[1/4] 正在执行零商业标识与侵权商标检测 (Zero-Leak Check)...${RESET}"
FORBIDDEN_WORDS=(
    "WhatsApp"
    "Telegram"
    "WeChat"
    "IM-SDK"
    "IMModels"
    "IMStorage"
    "IMTransport"
    "IMUI"
    "IMSyncEngine"
    "IMLocalServer"
    "IMChatCore"
)

VIOLATIONS_FOUND=0
for word in "${FORBIDDEN_WORDS[@]}"; do
    MATCHES=$(grep -rn "${word}" "${TEMPLATE_ROOT}" \
        --exclude-dir=".git" \
        --exclude="verify_workflow.sh" \
        --exclude="sync-upstream.sh" || true)
    if [ -n "${MATCHES}" ]; then
        log_error "【合规拦截】发现违规残留标识词 '${word}':"
        echo "${MATCHES}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    fi
done

if [ ${VIOLATIONS_FOUND} -eq 0 ]; then
    log_success "通过：模版仓库内 0 商业标识残留，完全中立合规！"
else
    log_error "失败：共发现 ${VIOLATIONS_FOUND} 处标识残留，必须清理！"
    exit 1
fi

# ------------------------------------------------------------------------------
# 阶段 2: 模板占位符防篡改检测与文件完整性
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[2/4] 正在检测核心模板占位符完整性 (Template Integrity Check)...${RESET}"
REQUIRED_PLACEHOLDERS=(
    "{{PROJECT_NAME}}"
    "{{MAIN_BRANCH}}"
    "{{GATE_COMMAND}}"
    "{{MAX_FILE_LINES}}"
)

for ph in "${REQUIRED_PLACEHOLDERS[@]}"; do
    if ! grep -q "${ph}" "${TEMPLATE_ROOT}/templates/AGENTS.template.md"; then
        log_error "模板被破坏！templates/AGENTS.template.md 缺失关键占位符: ${ph}"
        exit 1
    fi
done
log_success "通过：templates/AGENTS.template.md 占位符结构完好！"

REQUIRED_FILES=(
    "README.md"
    "CHANGELOG.md"
    "workflow.config.template.json"
    ".gitignore"
    "scripts/setup.sh"
    "scripts/update.sh"
    "scripts/sync-upstream.sh"
    "scripts/verify_workflow.sh"
    ".agents/agents/component-coder.md"
    ".agents/agents/unit-tester.md"
    ".agents/agents/code-reviewer.md"
    ".agents/agents/doc-architect.md"
    ".agents/rules/pipeline_governance.md"
    ".agents/skills/pipeline-core/SKILL.md"
    "templates/AGENTS.template.md"
    "templates/DOCS/ARCHITECTURE.template.md"
    "templates/DOCS/PROGRESS.template.md"
    "templates/DOCS/PIPELINE_METRICS.template.md"
    "templates/DOCS/RFC_DESIGN_TEMPLATE.md"
    "templates/gates/Makefile.template"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${TEMPLATE_ROOT}/${file}" ]; then
        log_error "缺失核心必要文件: ${file}"
        exit 1
    fi
done
log_success "通过：所有 ${#REQUIRED_FILES[@]} 项核心模版文件全部就绪！"

# ------------------------------------------------------------------------------
# 阶段 3: 脚本执行权限与语法解析校验
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[3/4] 正在检验脚本执行权限与 Bash 语法规范...${RESET}"
chmod +x "${TEMPLATE_ROOT}/scripts/"*.sh

for script in "${TEMPLATE_ROOT}/scripts/"*.sh; do
    bash -n "${script}"
    log_success "脚本语法校验通过: $(basename "${script}")"
done

# ------------------------------------------------------------------------------
# 阶段 4: 多工程端到端沙盒矩阵测试 (Sandbox Matrix Test)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[4/4] 启动多工程全流程沙盒矩阵兼容性测试 (Sandbox Matrix Test)...${RESET}"

SANDBOX_ROOT="/tmp/ai-workflow-ci-matrix"
rm -rf "${SANDBOX_ROOT}"
mkdir -p "${SANDBOX_ROOT}"

# --- Case 1: 全新工程首次接入测试 (Fresh Setup) ---
log_info "[Matrix 1/3] 执行全新工程首次接入测试 (Fresh Setup)..."
FRESH_PROJECT="${SANDBOX_ROOT}/FreshProject"
mkdir -p "${FRESH_PROJECT}"
bash "${TEMPLATE_ROOT}/scripts/setup.sh" "${FRESH_PROJECT}" >/dev/null

# 断言核心文件与5角色生成
if [ ! -f "${FRESH_PROJECT}/workflow.config.json" ] || \
   [ ! -f "${FRESH_PROJECT}/AGENTS.md" ] || \
   [ ! -f "${FRESH_PROJECT}/.agents/agents/unit-tester.md" ] || \
   [ ! -f "${FRESH_PROJECT}/.agents/agents/doc-architect.md" ] || \
   [ ! -f "${FRESH_PROJECT}/DOCS/ARCHITECTURE.md" ] || \
   [ ! -f "${FRESH_PROJECT}/Makefile" ]; then
    log_error "全新接入测试失败：核心文件或5角色未成功生成！"
    exit 1
fi

# 断言占位符已正确替换，无生硬占位符残留
if grep -q "{{PROJECT_NAME}}" "${FRESH_PROJECT}/AGENTS.md"; then
    log_error "全新接入测试失败：AGENTS.md 中仍残留未替换的占位符！"
    exit 1
fi

# 验证 Makefile 门禁
(cd "${FRESH_PROJECT}" && make check >/dev/null)
log_success "✅ Matrix 1/3 全新工程接入沙盒验证 100% 达标！"

# --- Case 2: 老工程增量升级兼容性测试 (Legacy Update & Config Protection) ---
log_info "[Matrix 2/3] 执行老工程增量升级兼容性测试 (Config Protection)..."
LEGACY_PROJECT="${SANDBOX_ROOT}/LegacyProject"
mkdir -p "${LEGACY_PROJECT}"
bash "${TEMPLATE_ROOT}/scripts/setup.sh" "${LEGACY_PROJECT}" >/dev/null

# 模拟老工程修改了个性化业务配置与业务任务看板
sed -i '' 's/"make check"/"make custom_gate"/g' "${LEGACY_PROJECT}/workflow.config.json"
echo "### 业务独占任务 [Task-999-SecretBusinessFeature]" >> "${LEGACY_PROJECT}/DOCS/PROGRESS.md"

# 执行升级
bash "${TEMPLATE_ROOT}/scripts/update.sh" "${LEGACY_PROJECT}" >/dev/null

# 硬性断言：业务独占任务不得被覆盖冲掉！
if ! grep -q "Task-999-SecretBusinessFeature" "${LEGACY_PROJECT}/DOCS/PROGRESS.md"; then
    log_error "严重缺陷：增量升级冲掉了老项目的业务任务看板 (DOCS/PROGRESS.md)！"
    exit 1
fi

# 硬性断言：用户自定义的门禁命令不得被覆盖重置！
if ! grep -q "make custom_gate" "${LEGACY_PROJECT}/workflow.config.json"; then
    log_error "严重缺陷：增量升级冲掉了老项目的自定义门禁配置 (workflow.config.json)！"
    exit 1
fi

# 断言备份文件生成
if [ ! -f "${LEGACY_PROJECT}/AGENTS.md.bak" ]; then
    log_error "严重缺陷：增量升级未生成 AGENTS.md.bak 备份文件！"
    exit 1
fi
log_success "✅ Matrix 2/3 老工程增量升级与业务配置保护验证 100% 达标！"

# --- Case 3: 业务工程安全反哺与分支隔离测试 (Upstream Sync) ---
log_info "[Matrix 3/3] 执行业务工程安全反哺与分支隔离测试 (Upstream Sync)..."
CONTRIB_PROJECT="${SANDBOX_ROOT}/ContribProject"
mkdir -p "${CONTRIB_PROJECT}"
bash "${TEMPLATE_ROOT}/scripts/setup.sh" "${CONTRIB_PROJECT}" >/dev/null

# 模拟业务工程在本地优化了一条审查规则
echo "<!-- 优化通用审查规则示例 -->" >> "${CONTRIB_PROJECT}/.agents/agents/code-reviewer.md"

# 执行反哺
bash "${TEMPLATE_ROOT}/scripts/sync-upstream.sh" "${CONTRIB_PROJECT}" >/dev/null

# 检查模版仓库是否切出了 contrib 分支
(
    cd "${TEMPLATE_ROOT}"
    CURRENT_BRANCH="$(git symbolic-ref --short HEAD)"
    if [[ "${CURRENT_BRANCH}" != contrib/* ]]; then
        log_error "反哺隔离测试失败：未在独立贡献分支提交变更！当前分支: ${CURRENT_BRANCH}"
        exit 1
    fi
    # 验证完毕后清理测试贡献分支，切回 main
    git checkout -q main
    git branch -D "${CURRENT_BRANCH}" >/dev/null 2>&1 || true
    # 丢弃反哺模拟留在 working tree 的测试修改
    git checkout -- .agents/agents/code-reviewer.md
)
log_success "✅ Matrix 3/3 业务工程安全反哺与分支隔离验证 100% 达标！"

# ------------------------------------------------------------------------------
# 清理临时沙盒测试目录
# ------------------------------------------------------------------------------
rm -rf "${SANDBOX_ROOT}"

echo ""
echo -e "${BOLD}${GREEN}==================================================================${RESET}"
echo -e "${BOLD}${GREEN}  🎉 恭喜！AI-Workflow 全功能 CI 门禁矩阵测试全部 100% 绿灯通过！ ${RESET}"
echo -e "${BOLD}${GREEN}==================================================================${RESET}"
echo "测试总结报告:"
echo "  1. 静态检测: 0 商业标识残留 / 0 第三方侵权商标"
echo "  2. 契约检测: 核心占位符完好 / 20 项模版文件无缺失"
echo "  3. 脚本语法: setup.sh / update.sh / sync-upstream.sh / verify 严格合规"
echo "  4. 沙盒矩阵: 全新接入顺利 / 老项目配置 100% 受保护 / 反向同步安全隔离"
echo -e "${GREEN}==================================================================${RESET}"
