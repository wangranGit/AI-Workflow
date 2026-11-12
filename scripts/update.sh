#!/usr/bin/env bash
# ==============================================================================
# AI-Workflow 增量无损平滑更新脚本 (Update Script - v1.2.1)
# 功能：
# 1. 自动检测上游 Git 仓库状态，拉取最新模版代码 (git pull / 远端拉取)
# 2. 差异对比与变更摘要看板 (Workflow Diff Summary)
# 3. 严格保护项目级配置与业务文档，无损更新通用规则与 Prompt
# ==============================================================================
set -euo pipefail

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
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

# 1. 确定目标项目目录 (默认为当前工作目录，或通过第1参数指定)
TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

# 2. 确定模版来源
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
TEMPLATE_ROOT=""

UPSTREAM_META="${TARGET_DIR}/.agents/.meta/upstream.env"
if [ -f "${UPSTREAM_META}" ]; then
    # shellcheck disable=SC1090
    source "${UPSTREAM_META}"
    if [ -n "${LOCAL_TEMPLATE_PATH:-}" ] && [ -d "${LOCAL_TEMPLATE_PATH}/.agents" ]; then
        TEMPLATE_ROOT="${LOCAL_TEMPLATE_PATH}"
    elif [ -n "${TEMPLATE_SOURCE:-}" ] && [ -d "${TEMPLATE_SOURCE}/.agents" ]; then
        TEMPLATE_ROOT="${TEMPLATE_SOURCE}"
    fi
fi

if [ -z "${TEMPLATE_ROOT}" ] && [ -n "${SCRIPT_DIR}" ] && [ -d "${SCRIPT_DIR}/../.agents" ]; then
    TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

# 若本地路径仍为空，直接浅克隆远端模版
if [ -z "${TEMPLATE_ROOT}" ] || [ ! -d "${TEMPLATE_ROOT}/.agents" ]; then
    log_info "正在从远端 Git 仓库拉取最新 AI-Workflow 模版..."
    CLEANUP_TEMP_DIR="$(mktemp -d)"
    git clone --depth 1 "${DEFAULT_REMOTE_REPO}" "${CLEANUP_TEMP_DIR}" >/dev/null 2>&1
    TEMPLATE_ROOT="${CLEANUP_TEMP_DIR}"
fi

log_info "目标项目目录: ${TARGET_DIR}"
log_info "上游模版根目录: ${TEMPLATE_ROOT}"

# 3. 如果本地模版目录是一个 Git 仓库，尝试 git pull 更新
if [ -d "${TEMPLATE_ROOT}/.git" ] && [ -z "${CLEANUP_TEMP_DIR}" ]; then
    log_info "检测到本地模版仓库具备 Git 管理，正在检查上游更新..."
    (
        cd "${TEMPLATE_ROOT}"
        if git remote -v | grep -q "origin"; then
            log_info "正在执行 git pull origin main 拉取最新模版变更..."
            git pull --ff-only origin main || log_warn "拉取远程失败或无网络，使用本地当前版本继续。"
        fi
    )
fi

CONFIG_FILE="${TARGET_DIR}/workflow.config.json"
if [ ! -f "${CONFIG_FILE}" ]; then
    log_warn "未检测到 workflow.config.json，将以全新接入模式运行 setup.sh..."
    bash "${TEMPLATE_ROOT}/scripts/setup.sh" "${TARGET_DIR}"
    exit 0
fi

# 4. 解析当前项目个性化配置
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

# 5. 生成拟更新的临时 AGENTS.md 并打印差异看板
TEMP_NEW_AGENTS="$(mktemp)"
sed \
    -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
    -e "s/{{MAIN_BRANCH}}/${MAIN_BRANCH}/g" \
    -e "s/{{GATE_COMMAND}}/${GATE_COMMAND}/g" \
    -e "s/{{MAX_FILE_LINES}}/${MAX_FILE_LINES}/g" \
    "${TEMPLATE_ROOT}/templates/AGENTS.template.md" > "${TEMP_NEW_AGENTS}"

echo ""
echo -e "${BOLD}${CYAN}==================================================================${RESET}"
echo -e "${BOLD}${CYAN}               📋 下游规则变更差异看板 (Workflow Diff)             ${RESET}"
echo -e "${BOLD}${CYAN}==================================================================${RESET}"

DIFF_LINES=0
if [ -f "${TARGET_DIR}/AGENTS.md" ]; then
    DIFF_OUTPUT="$(diff -u "${TARGET_DIR}/AGENTS.md" "${TEMP_NEW_AGENTS}" || true)"
    if [ -n "${DIFF_OUTPUT}" ]; then
        echo -e "${YELLOW}检测到项目级 AGENTS.md 规范与上游模版存在差异：${RESET}"
        echo "${DIFF_OUTPUT}" | head -n 25 || true
        DIFF_LINES=$(echo "${DIFF_OUTPUT}" | wc -l)
        if [ "${DIFF_LINES}" -gt 25 ]; then
            echo -e "${YELLOW}... (差异内容较长，已省略显示剩余 $((DIFF_LINES - 25)) 行) ...${RESET}"
        fi
    else
        echo -e "${GREEN}✅ 当前项目的 AGENTS.md 与上游模版保持一致，无新增规则漂移。${RESET}"
    fi
else
    echo -e "${BLUE}当前项目无 AGENTS.md，将直接初始化生成。${RESET}"
fi
echo -e "${CYAN}==================================================================${RESET}\n"

# 6. 安全更新 AGENTS.md (保留原文件为 .bak)
if [ -f "${TARGET_DIR}/AGENTS.md" ]; then
    cp "${TARGET_DIR}/AGENTS.md" "${TARGET_DIR}/AGENTS.md.bak"
    log_info "已将旧版规范备份至 AGENTS.md.bak"
fi
mv "${TEMP_NEW_AGENTS}" "${TARGET_DIR}/AGENTS.md"

# 7. 更新通用代理体系 (.agents/)
log_info "正在无损同步 .agents 通用规则、Prompt 与技能..."
mkdir -p "${TARGET_DIR}/.agents/agents"
mkdir -p "${TARGET_DIR}/.agents/rules"
mkdir -p "${TARGET_DIR}/.agents/skills/pipeline-core"

cp -R "${TEMPLATE_ROOT}/.agents/agents/"* "${TARGET_DIR}/.agents/agents/"
cp -R "${TEMPLATE_ROOT}/.agents/rules/"* "${TARGET_DIR}/.agents/rules/"
cp -R "${TEMPLATE_ROOT}/.agents/skills/pipeline-core/"* "${TARGET_DIR}/.agents/skills/pipeline-core/"

# 8. 更新 RFC 设计模板
mkdir -p "${TARGET_DIR}/DOCS/TEMPLATES"
cp "${TEMPLATE_ROOT}/templates/DOCS/RFC_DESIGN_TEMPLATE.md" "${TARGET_DIR}/DOCS/TEMPLATES/"

# 9. 更新元信息记录与配套脚本
mkdir -p "${TARGET_DIR}/scripts"
cp "${TEMPLATE_ROOT}/scripts/update.sh" "${TARGET_DIR}/scripts/"
cp "${TEMPLATE_ROOT}/scripts/sync-upstream.sh" "${TARGET_DIR}/scripts/"
chmod +x "${TARGET_DIR}/scripts/"*.sh

echo "TEMPLATE_SOURCE=\"${DEFAULT_REMOTE_REPO}\"" > "${TARGET_DIR}/.agents/.meta/upstream.env"
echo "UPDATED_DATE=\"$(date)\"" >> "${TARGET_DIR}/.agents/.meta/upstream.env"

echo ""
echo -e "${BOLD}${GREEN}==================================================================${RESET}"
log_success "🎉 AI-Workflow 模版已无损平滑升级至最新版本！"
echo -e "${BOLD}${GREEN}==================================================================${RESET}"
echo "🛡️  保护策略执行结果:"
echo "  [保护] workflow.config.json: 保持项目个性化门禁与阈值不变"
echo "  [保护] DOCS/PROGRESS.md: 保持现有任务追踪看板不变"
echo "  [保护] DOCS/ARCHITECTURE.md: 保持现有架构设计文档不变"
echo "  [保护] DOCS/PIPELINE_METRICS.md: 保持历史指标与教训台账不变"
echo "  [更新] .agents/agents/: 已更新最新 5 角色 (Coder/Tester/Reviewer/DocArchitect) 规范"
echo "  [更新] .agents/rules/: 已更新最新九大红线与五角色协同法则"
echo "  [更新] .agents/skills/: 已更新最新流水线自检与度量技能"
echo "  [更新] AGENTS.md: 已根据最新模版更新 (原文件已备份为 AGENTS.md.bak)"
echo -e "${GREEN}==================================================================${RESET}"
