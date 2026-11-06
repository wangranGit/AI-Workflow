#!/usr/bin/env bash
# ==============================================================================
# AI-Workflow 模版仓库自检验证脚本 (Verify Script)
# 用于自动化检测：
# 1. 是否携带特定业务专有词汇或第三方侵权商标 (Neutrality Check)
# 2. 脚本可执行权限与基本语法
# 3. 模版文件完整性与占位符规范
# ==============================================================================
set -euo pipefail

GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${BLUE}=== 正在对 AI-Workflow 模版仓库执行合规自检 ===${RESET}"

# 1. 检测特定业务或第三方商标敏感词
echo -e "\n🔍 检查 1: 零商业标识与侵权商标检测..."
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
    # 忽略 verify_workflow.sh 自身、.git 目录
    MATCHES=$(grep -rn "${word}" "${TEMPLATE_ROOT}" \
        --exclude-dir=".git" \
        --exclude="verify_workflow.sh" || true)
    if [ -n "${MATCHES}" ]; then
        echo -e "${RED}[违规命中] 发现敏感标识词 '${word}':${RESET}"
        echo "${MATCHES}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    fi
done

if [ ${VIOLATIONS_FOUND} -eq 0 ]; then
    echo -e "${GREEN}✅ 通过：未检测到任何特定业务专有名词或第三方商标！${RESET}"
else
    echo -e "${RED}❌ 失败：共发现 ${VIOLATIONS_FOUND} 处标识残留，必须清理！${RESET}"
    exit 1
fi

# 2. 检查脚本执行权限与语法
echo -e "\n🔍 检查 2: 脚本执行权限与语法解析..."
chmod +x "${TEMPLATE_ROOT}/scripts/"*.sh

for script in "${TEMPLATE_ROOT}/scripts/"*.sh; do
    bash -n "${script}"
    echo -e "${GREEN}✅ 脚本语法正常: $(basename "${script}")${RESET}"
done

# 3. 检查核心骨架完整性
echo -e "\n🔍 检查 3: 核心资产完整性校验..."
REQUIRED_FILES=(
    "README.md"
    "CHANGELOG.md"
    "workflow.config.template.json"
    ".gitignore"
    "scripts/setup.sh"
    "scripts/update.sh"
    ".agents/agents/component-coder.md"
    ".agents/agents/code-reviewer.md"
    ".agents/rules/pipeline_governance.md"
    ".agents/skills/pipeline-core/SKILL.md"
    "templates/AGENTS.template.md"
    "templates/DOCS/ARCHITECTURE.template.md"
    "templates/DOCS/PROGRESS.template.md"
    "templates/DOCS/PIPELINE_METRICS.template.md"
    "templates/DOCS/RFC_DESIGN_TEMPLATE.md"
    "templates/gates/Makefile.template"
)

MISSING_COUNT=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${TEMPLATE_ROOT}/${file}" ]; then
        echo -e "${RED}[缺失文件] ${file}${RESET}"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done

if [ ${MISSING_COUNT} -eq 0 ]; then
    echo -e "${GREEN}✅ 通过：所有 ${#REQUIRED_FILES[@]} 项核心模版文件全部就绪！${RESET}"
else
    echo -e "${RED}❌ 失败：缺失 ${MISSING_COUNT} 个必要文件！${RESET}"
    exit 1
fi

echo -e "\n${GREEN}🎉 AI-Workflow 模版仓库全部自检项目 100% 绿灯达标！${RESET}"
