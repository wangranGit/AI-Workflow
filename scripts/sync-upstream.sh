#!/usr/bin/env bash
# ==============================================================================
# AI-Workflow 安全反哺上游模版脚本 (Sync-Upstream Script - v1.1.0)
# 功能：
# 1. 安全提炼：仅提取通用的 .agents/ 规则与 Prompt，严格阻断业务私有配置外泄
# 2. 零标识拦截：自动执行敏感业务词与第三方商业商标扫描，违规即一票否决
# 3. 分支隔离：在模版仓库自动创建独立贡献分支 (contrib/<project>-<timestamp>)
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

# 1. 确定来源项目目录 (当前工程)
SOURCE_DIR="${1:-$(pwd)}"
SOURCE_DIR="$(cd "${SOURCE_DIR}" && pwd)"

# 2. 确定目标模版仓库目录
UPSTREAM_META="${SOURCE_DIR}/.agents/.meta/upstream.env"
TEMPLATE_ROOT=""

if [ -f "${UPSTREAM_META}" ]; then
    # shellcheck disable=SC1090
    source "${UPSTREAM_META}"
    if [ -n "${TEMPLATE_SOURCE:-}" ] && [ -d "${TEMPLATE_SOURCE}" ]; then
        TEMPLATE_ROOT="${TEMPLATE_SOURCE}"
    fi
fi

if [ -z "${TEMPLATE_ROOT}" ] || [ ! -d "${TEMPLATE_ROOT}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

log_info "源工程目录 (贡献方): ${SOURCE_DIR}"
log_info "上游模版根目录: ${TEMPLATE_ROOT}"

if [ "${SOURCE_DIR}" = "${TEMPLATE_ROOT}" ]; then
    log_warn "当前已位于模版根目录，无需执行反向同步。"
    exit 0
fi

if [ ! -d "${SOURCE_DIR}/.agents" ]; then
    log_error "当前工程未检测到 .agents/ 目录，无法反哺工作流！"
    exit 1
fi

PROJECT_NAME="$(basename "${SOURCE_DIR}")"
if [ -f "${SOURCE_DIR}/workflow.config.json" ] && command -v jq >/dev/null 2>&1; then
    PROJECT_NAME="$(jq -r '.projectName // "'"${PROJECT_NAME}"'"' "${SOURCE_DIR}/workflow.config.json")"
fi

# 3. 严格合规审查：零商业标识与侵权词拦截 (Zero-Leak Check)
log_info "正在对拟反哺的 .agents 通用规则执行合规拦截扫描..."
FORBIDDEN_WORDS=(
    "WhatsApp"
    "Telegram"
    "WeChat"
    "${PROJECT_NAME}"
)

VIOLATIONS_FOUND=0
for word in "${FORBIDDEN_WORDS[@]}"; do
    MATCHES=$(grep -rn "${word}" "${SOURCE_DIR}/.agents" \
        --exclude-dir=".meta" || true)
    if [ -n "${MATCHES}" ]; then
        log_error "【合规拦截】在 .agents 中检测到可能包含的项目专属标识或敏感词: '${word}'"
        echo "${MATCHES}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    fi
done

if [ ${VIOLATIONS_FOUND} -gt 0 ]; then
    echo ""
    log_error "❌ 发现 ${VIOLATIONS_FOUND} 处商业标识残留！"
    log_error "安全红线：反哺上游模版的规则必须 100% 通用化与去标识化，禁止携带任何业务专属或商标名词！"
    log_error "请在当前工程的 .agents/ 中清理后再尝试执行本脚本。"
    exit 1
fi
log_success "✅ 合规检查通过：待反哺内容 100% 纯净中立，无商业标识泄露！"

# 4. 检查模版仓库 Git 状态
if [ ! -d "${TEMPLATE_ROOT}/.git" ]; then
    log_error "上游模版根目录不是合法的 Git 仓库: ${TEMPLATE_ROOT}"
    exit 1
fi

# 5. 分支隔离：在模版仓库创建独立的贡献分支，不直接污染 main
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
CONTRIB_BRANCH="contrib/${PROJECT_NAME}_${TIMESTAMP}"

log_info "正在上游模版仓库创建独立贡献分支: ${CONTRIB_BRANCH} ..."
(
    cd "${TEMPLATE_ROOT}"
    # 确保基于最新的 main 分支切出贡献分支
    git checkout -q main
    git checkout -b "${CONTRIB_BRANCH}"

    # 6. 安全白名单同步 (仅同步通用 Prompt 与规则，绝对不复制业务文件)
    mkdir -p "${TEMPLATE_ROOT}/.agents/agents"
    mkdir -p "${TEMPLATE_ROOT}/.agents/rules"
    mkdir -p "${TEMPLATE_ROOT}/.agents/skills/pipeline-core"

    cp -R "${SOURCE_DIR}/.agents/agents/"* "${TEMPLATE_ROOT}/.agents/agents/"
    cp -R "${SOURCE_DIR}/.agents/rules/"* "${TEMPLATE_ROOT}/.agents/rules/"
    cp -R "${SOURCE_DIR}/.agents/skills/pipeline-core/"* "${TEMPLATE_ROOT}/.agents/skills/pipeline-core/"

    # 7. 提交至贡献分支
    if git status --porcelain | grep -q ".agents"; then
        git add .agents/
        git commit -m "contrib(${PROJECT_NAME}): update workflow prompt and rules from ${PROJECT_NAME} at ${TIMESTAMP}"
        echo ""
        echo -e "${BOLD}${GREEN}==================================================================${RESET}"
        log_success "🎉 成功将工程 [${PROJECT_NAME}] 的通用规则反哺提交至模版仓库！"
        echo -e "${BOLD}${GREEN}==================================================================${RESET}"
        echo "已在模版仓库创建隔离贡献分支: ${CONTRIB_BRANCH}"
        echo "下一步操作建议 (由模版 Maintainer 审阅合入):"
        echo "  cd ${TEMPLATE_ROOT}"
        echo "  git diff main...${CONTRIB_BRANCH}   # 审阅改动"
        echo "  bash scripts/verify_workflow.sh     # 运行多工程沙盒矩阵自检"
        echo "  git checkout main && git merge --squash ${CONTRIB_BRANCH} # 确认合入"
        echo -e "${GREEN}==================================================================${RESET}"
    else
        log_info "经对比，当前工程的 .agents 与上游模版无实质差异，无需重复反哺。"
        git checkout -q main
        git branch -D "${CONTRIB_BRANCH}" >/dev/null 2>&1 || true
    fi
)
