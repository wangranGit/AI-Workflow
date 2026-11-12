#!/usr/bin/env bash
# ==============================================================================
# AI-Workflow 新项目一键初始化脚本 (Setup Script - v1.2.1)
# 支持方式：
# 1. 本地执行: /path/to/AI-Workflow/scripts/setup.sh .
# 2. 远程一键: curl -fsSL https://raw.githubusercontent.com/wangranGit/AI-Workflow/main/scripts/setup.sh | bash
# ==============================================================================
set -euo pipefail

# 颜色输出
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

DEFAULT_REMOTE_REPO="https://github.com/wangranGit/AI-Workflow.git"
CLEANUP_TEMP_DIR=""

cleanup() {
    if [ -n "${CLEANUP_TEMP_DIR}" ] && [ -d "${CLEANUP_TEMP_DIR}" ]; then
        rm -rf "${CLEANUP_TEMP_DIR}"
    fi
}
trap cleanup EXIT

# 确定目标项目目录 (默认为当前工作目录，或通过第1参数指定)
TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

# 确定模版来源
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
TEMPLATE_ROOT=""

if [ -n "${SCRIPT_DIR}" ] && [ -d "${SCRIPT_DIR}/../.agents" ]; then
    TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
    # 处于 curl 管道运行或独立运行状态，自动拉取远程模版
    log_info "检测到远程/管道执行模式，正在自动获取最新 AI-Workflow 模版资产..."
    CLEANUP_TEMP_DIR="$(mktemp -d)"
    git clone --depth 1 "${DEFAULT_REMOTE_REPO}" "${CLEANUP_TEMP_DIR}" >/dev/null 2>&1
    TEMPLATE_ROOT="${CLEANUP_TEMP_DIR}"
fi

log_info "模版资产来源: ${TEMPLATE_ROOT}"
log_info "目标接入工程: ${TARGET_DIR}"

# 1. 检查目标项目目录合法性
if [ ! -d "${TARGET_DIR}" ]; then
    log_error "目标目录不存在: ${TARGET_DIR}"
    exit 1
fi

cd "${TARGET_DIR}"

if [ ! -d ".git" ]; then
    log_warn "目标目录不是 Git 仓库，正在执行 git init 初始化..."
    git init
    log_success "Git 仓库初始化完毕。"
fi

# 2. 识别项目基础信息与配置生成
PROJECT_NAME="$(basename "${TARGET_DIR}")"
MAIN_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")"
GATE_COMMAND="make check"
MAX_FILE_LINES=500
CURRENT_DATE="$(date +%Y-%m-%d)"

CONFIG_FILE="${TARGET_DIR}/workflow.config.json"
if [ -f "${CONFIG_FILE}" ]; then
    log_info "检测到已有配置文件: workflow.config.json，保持现有配置。"
    if command -v jq >/dev/null 2>&1; then
        PROJECT_NAME="$(jq -r '.projectName // "'"${PROJECT_NAME}"'"' "${CONFIG_FILE}")"
        MAIN_BRANCH="$(jq -r '.git.mainBranch // "'"${MAIN_BRANCH}"'"' "${CONFIG_FILE}")"
        GATE_COMMAND="$(jq -r '.gate.command // "'"${GATE_COMMAND}"'"' "${CONFIG_FILE}")"
        MAX_FILE_LINES="$(jq -r '.quality.maxFileLinesWarning // '"${MAX_FILE_LINES}"'' "${CONFIG_FILE}")"
    fi
else
    log_info "生成项目级配置文件 workflow.config.json..."
    sed \
        -e "s/\"MyProject\"/\"${PROJECT_NAME}\"/g" \
        -e "s/\"main\"/\"${MAIN_BRANCH}\"/g" \
        "${TEMPLATE_ROOT}/workflow.config.template.json" > "${CONFIG_FILE}"
    log_success "已生成 workflow.config.json"
fi

# 3. 部署 .agents 核心目录 (通用5角色代理、规则与技能)
log_info "正在同步 .agents 通用五角色代理体系..."
mkdir -p "${TARGET_DIR}/.agents/agents"
mkdir -p "${TARGET_DIR}/.agents/rules"
mkdir -p "${TARGET_DIR}/.agents/skills/pipeline-core"

cp -R "${TEMPLATE_ROOT}/.agents/agents/"* "${TARGET_DIR}/.agents/agents/"
cp -R "${TEMPLATE_ROOT}/.agents/rules/"* "${TARGET_DIR}/.agents/rules/"
cp -R "${TEMPLATE_ROOT}/.agents/skills/pipeline-core/"* "${TARGET_DIR}/.agents/skills/pipeline-core/"

# 4. 生成项目根目录统一规则 AGENTS.md
log_info "正在生成项目级 AGENTS.md 规范文件..."
sed \
    -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
    -e "s/{{MAIN_BRANCH}}/${MAIN_BRANCH}/g" \
    -e "s/{{GATE_COMMAND}}/${GATE_COMMAND}/g" \
    -e "s/{{MAX_FILE_LINES}}/${MAX_FILE_LINES}/g" \
    "${TEMPLATE_ROOT}/templates/AGENTS.template.md" > "${TARGET_DIR}/AGENTS.md"

# 5. 生成 DOCS 文档骨架
log_info "正在初始化 DOCS/ 三层文档骨架..."
mkdir -p "${TARGET_DIR}/DOCS/TEMPLATES"
mkdir -p "${TARGET_DIR}/DOCS/MODULES"

# 复制 RFC 设计模版
cp "${TEMPLATE_ROOT}/templates/DOCS/RFC_DESIGN_TEMPLATE.md" "${TARGET_DIR}/DOCS/TEMPLATES/"

# 初始化 ARCHITECTURE.md (存在则不覆盖)
if [ ! -f "${TARGET_DIR}/DOCS/ARCHITECTURE.md" ]; then
    sed -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
        "${TEMPLATE_ROOT}/templates/DOCS/ARCHITECTURE.template.md" > "${TARGET_DIR}/DOCS/ARCHITECTURE.md"
    log_success "已生成 DOCS/ARCHITECTURE.md"
else
    log_info "DOCS/ARCHITECTURE.md 已存在，跳过覆盖。"
fi

# 初始化 PROGRESS.md (存在则不覆盖)
if [ ! -f "${TARGET_DIR}/DOCS/PROGRESS.md" ]; then
    sed -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
        -e "s/{{DATE}}/${CURRENT_DATE}/g" \
        "${TEMPLATE_ROOT}/templates/DOCS/PROGRESS.template.md" > "${TARGET_DIR}/DOCS/PROGRESS.md"
    log_success "已生成 DOCS/PROGRESS.md"
else
    log_info "DOCS/PROGRESS.md 已存在，跳过覆盖。"
fi

# 初始化 PIPELINE_METRICS.md (存在则不覆盖)
if [ ! -f "${TARGET_DIR}/DOCS/PIPELINE_METRICS.md" ]; then
    sed -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
        -e "s/{{DATE}}/${CURRENT_DATE}/g" \
        -e "s/{{MAX_FILE_LINES}}/${MAX_FILE_LINES}/g" \
        "${TEMPLATE_ROOT}/templates/DOCS/PIPELINE_METRICS.template.md" > "${TARGET_DIR}/DOCS/PIPELINE_METRICS.md"
    log_success "已生成 DOCS/PIPELINE_METRICS.md"
else
    log_info "DOCS/PIPELINE_METRICS.md 已存在，跳过覆盖。"
fi

# 6. 初始化 Makefile 门禁入口 (如果项目没有 Makefile)
if [ ! -f "${TARGET_DIR}/Makefile" ]; then
    log_info "未检测到 Makefile，正在从模板生成门禁入口 Makefile..."
    sed -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
        "${TEMPLATE_ROOT}/templates/gates/Makefile.template" > "${TARGET_DIR}/Makefile"
    log_success "已生成基础 Makefile (可直接执行 make check)"
else
    log_info "检测到已有 Makefile，保持现有配置。"
fi

# 7. 写入工作流元信息与运维脚本 (记录模版来源与更新入口)
mkdir -p "${TARGET_DIR}/.agents/.meta"
mkdir -p "${TARGET_DIR}/scripts"

# 将 update.sh 与 sync-upstream.sh 随附复制到项目的 scripts/ 目录下，方便项目在没有本地模版路径时也能随时升级与反哺
cp "${TEMPLATE_ROOT}/scripts/update.sh" "${TARGET_DIR}/scripts/"
cp "${TEMPLATE_ROOT}/scripts/sync-upstream.sh" "${TARGET_DIR}/scripts/"
chmod +x "${TARGET_DIR}/scripts/"*.sh

echo "TEMPLATE_SOURCE=\"${DEFAULT_REMOTE_REPO}\"" > "${TARGET_DIR}/.agents/.meta/upstream.env"
echo "LOCAL_TEMPLATE_PATH=\"${TEMPLATE_ROOT}\"" >> "${TARGET_DIR}/.agents/.meta/upstream.env"
echo "INSTALLED_DATE=\"$(date)\"" >> "${TARGET_DIR}/.agents/.meta/upstream.env"

echo ""
echo -e "${BOLD}${GREEN}==================================================================${RESET}"
log_success "🎉 AI-Workflow 五角色流水线成功植入工程: ${PROJECT_NAME} !"
echo -e "${BOLD}${GREEN}==================================================================${RESET}"
echo "已就绪的核心资产:"
echo "  1. 根目录规则: AGENTS.md (包含九大红线与五角色十步状态机)"
echo "  2. 项目配置文件: workflow.config.json"
echo "  3. 专职代理 Prompt: .agents/agents/ (component-coder, unit-tester, code-reviewer, doc-architect)"
echo "  4. 治理规范与技能: .agents/rules/ 与 .agents/skills/pipeline-core/"
echo "  5. 三层架构文档: DOCS/ARCHITECTURE.md, PROGRESS.md, PIPELINE_METRICS.md, MODULES/"
echo "  6. 自动化门禁指令: ${GATE_COMMAND}"
echo "  7. 项目自带运维工具: scripts/update.sh, scripts/sync-upstream.sh"
echo ""
echo "后续在本项目中如需平滑更新模版，只需执行: bash scripts/update.sh"
echo -e "${GREEN}==================================================================${RESET}"
