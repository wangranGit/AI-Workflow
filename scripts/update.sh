#!/usr/bin/env bash
# ==============================================================================
# AI-Workflow 增量无损平滑更新脚本 (Update Script)
# ==============================================================================
set -euo pipefail

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# 1. 确定目标项目目录 (默认为当前工作目录，或通过第1参数指定)
TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

# 2. 确定模版来源
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

UPSTREAM_META="${TARGET_DIR}/.agents/.meta/upstream.env"
if [ -f "${UPSTREAM_META}" ]; then
    # 读取上次安装的模版路径
    # shellcheck disable=SC1090
    source "${UPSTREAM_META}"
    if [ -n "${TEMPLATE_SOURCE:-}" ] && [ -d "${TEMPLATE_SOURCE}" ]; then
        TEMPLATE_ROOT="${TEMPLATE_SOURCE}"
    fi
fi

log_info "正在为项目执行 AI-Workflow 平滑升级..."
log_info "目标项目目录: ${TARGET_DIR}"
log_info "上游模版根目录: ${TEMPLATE_ROOT}"

CONFIG_FILE="${TARGET_DIR}/workflow.config.json"
if [ ! -f "${CONFIG_FILE}" ]; then
    log_warn "未检测到 workflow.config.json，将以全新接入模式运行 setup.sh..."
    bash "${TEMPLATE_ROOT}/scripts/setup.sh" "${TARGET_DIR}"
    exit 0
fi

# 3. 解析当前项目个性化配置
PROJECT_NAME="$(basename "${TARGET_DIR}")"
MAIN_BRANCH="main"
GATE_COMMAND="make check"
MAX_FILE_LINES=500

if command -v jq >/dev/null 2>&1; then
    PROJECT_NAME="$(jq -r '.projectName // "'"${PROJECT_NAME}"'"' "${CONFIG_FILE}")"
    MAIN_BRANCH="$(jq -r '.git.mainBranch // "main"' "${CONFIG_FILE}")"
    GATE_COMMAND="$(jq -r '.gate.command // "make check"' "${CONFIG_FILE}")"
    MAX_FILE_LINES="$(jq -r '.quality.maxFileLinesWarning // 500' "${CONFIG_FILE}")"
fi

# 4. 更新通用代理体系 (.agents/)
log_info "正在升级 .agents 通用规则、Prompt 与技能..."
mkdir -p "${TARGET_DIR}/.agents/agents"
mkdir -p "${TARGET_DIR}/.agents/rules"
mkdir -p "${TARGET_DIR}/.agents/skills/pipeline-core"

cp -R "${TEMPLATE_ROOT}/.agents/agents/"* "${TARGET_DIR}/.agents/agents/"
cp -R "${TEMPLATE_ROOT}/.agents/rules/"* "${TARGET_DIR}/.agents/rules/"
cp -R "${TEMPLATE_ROOT}/.agents/skills/pipeline-core/"* "${TARGET_DIR}/.agents/skills/pipeline-core/"

# 5. 更新 RFC 设计模板
mkdir -p "${TARGET_DIR}/DOCS/TEMPLATES"
cp "${TEMPLATE_ROOT}/templates/DOCS/RFC_DESIGN_TEMPLATE.md" "${TARGET_DIR}/DOCS/TEMPLATES/"

# 6. 安全更新 AGENTS.md (保留原文件为 .bak)
if [ -f "${TARGET_DIR}/AGENTS.md" ]; then
    cp "${TARGET_DIR}/AGENTS.md" "${TARGET_DIR}/AGENTS.md.bak"
    log_info "已将旧版 AGENTS.md 备份至 AGENTS.md.bak"
fi

sed \
    -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
    -e "s/{{MAIN_BRANCH}}/${MAIN_BRANCH}/g" \
    -e "s/{{GATE_COMMAND}}/${GATE_COMMAND}/g" \
    -e "s/{{MAX_FILE_LINES}}/${MAX_FILE_LINES}/g" \
    "${TEMPLATE_ROOT}/templates/AGENTS.template.md" > "${TARGET_DIR}/AGENTS.md"

# 7. 更新元信息记录
echo "TEMPLATE_SOURCE=\"${TEMPLATE_ROOT}\"" > "${TARGET_DIR}/.agents/.meta/upstream.env"
echo "UPDATED_DATE=\"$(date)\"" >> "${TARGET_DIR}/.agents/.meta/upstream.env"

echo ""
echo "=================================================================="
log_success "🎉 AI-Workflow 模版已无损平滑升级至最新版本！"
echo "=================================================================="
echo "保护策略执行结果:"
echo "  [保护] workflow.config.json: 保持项目个性化门禁与阈值不变"
echo "  [保护] DOCS/PROGRESS.md: 保持现有任务追踪看板不变"
echo "  [保护] DOCS/ARCHITECTURE.md: 保持现有架构设计文档不变"
echo "  [保护] DOCS/PIPELINE_METRICS.md: 保持历史指标与教训台账不变"
echo "  [更新] .agents/agents/: 已更新最新专职 Coder 与 Reviewer 规范"
echo "  [更新] .agents/rules/: 已更新最新九大红线与协同法则"
echo "  [更新] .agents/skills/: 已更新最新流水线自检与度量技能"
echo "  [更新] AGENTS.md: 已根据最新模版重新生成 (旧版本已存为 AGENTS.md.bak)"
echo "=================================================================="
