#!/usr/bin/env bash
# ==============================================================================
# AI-Workflow 新项目一键初始化脚本 (Setup Script)
# ==============================================================================
set -euo pipefail

# 颜色输出
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# 确定模版仓库根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 确定目标项目目录 (默认为当前工作目录，或通过第1参数指定)
TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

log_info "AI-Workflow 模版根目录: ${TEMPLATE_ROOT}"
log_info "目标接入项目目录: ${TARGET_DIR}"

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
    # 从已有配置解析（若安装了 jq）
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

# 3. 部署 .agents 核心目录 (通用代理与规则)
log_info "正在同步 .agents 通用代理体系..."
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
log_info "正在初始化 DOCS/ 文档骨架..."
mkdir -p "${TARGET_DIR}/DOCS/TEMPLATES"

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

# 7. 写入工作流元信息 (记录模版版本与更新源)
mkdir -p "${TARGET_DIR}/.agents/.meta"
echo "TEMPLATE_SOURCE=\"${TEMPLATE_ROOT}\"" > "${TARGET_DIR}/.agents/.meta/upstream.env"
echo "INSTALLED_DATE=\"$(date)\"" >> "${TARGET_DIR}/.agents/.meta/upstream.env"

echo ""
echo "=================================================================="
log_success "🎉 AI-Workflow 流水线成功植入项目: ${PROJECT_NAME} !"
echo "=================================================================="
echo "已就绪的核心资产:"
echo "  1. 根目录规则: AGENTS.md (包含九大红线与十步状态机)"
echo "  2. 项目配置文件: workflow.config.json"
echo "  3. 专职代理 Prompt: .agents/agents/component-coder.md, code-reviewer.md"
echo "  4. 治理规范与技能: .agents/rules/ 与 .agents/skills/pipeline-core/"
echo "  5. 架构与指标文档: DOCS/ARCHITECTURE.md, PROGRESS.md, PIPELINE_METRICS.md"
echo "  6. 自动化门禁指令: ${GATE_COMMAND}"
echo ""
echo "后续如需升级模版，可随时在项目内运行: ${TEMPLATE_ROOT}/scripts/update.sh"
echo "=================================================================="
