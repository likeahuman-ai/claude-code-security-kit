#!/bin/bash
# Claude Code Security Kit — Auto Installer
# https://github.com/likeahuman-ai/claude-code-security-kit

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}Claude Code Security Kit${NC} — installer"
echo ""

# Determine script directory (works whether called from repo or via curl)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check required files exist
if [[ ! -f "$SCRIPT_DIR/repo-security-auditor.md" ]] || [[ ! -f "$SCRIPT_DIR/check-repo-before-install.sh" ]]; then
  echo -e "${RED}Error:${NC} Required files not found. Run this from the cloned repo directory."
  exit 1
fi

# Check jq is available (needed by the hook at runtime)
if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}Warning:${NC} jq is not installed. The hook requires jq to work."
  echo "  Install it: brew install jq (macOS) / sudo apt install jq (Linux)"
  echo ""
fi

# Step 1: Copy agent
echo -e "  ${BLUE}[1/3]${NC} Installing agent..."
mkdir -p ~/.claude/agents
cp "$SCRIPT_DIR/repo-security-auditor.md" ~/.claude/agents/
echo -e "        ${GREEN}~/.claude/agents/repo-security-auditor.md${NC}"

# Step 2: Copy hook
echo -e "  ${BLUE}[2/3]${NC} Installing hook..."
mkdir -p ~/.claude/hooks
cp "$SCRIPT_DIR/check-repo-before-install.sh" ~/.claude/hooks/
chmod +x ~/.claude/hooks/check-repo-before-install.sh
echo -e "        ${GREEN}~/.claude/hooks/check-repo-before-install.sh${NC}"

# Step 3: Register hook in settings.json
echo -e "  ${BLUE}[3/3]${NC} Registering hook in settings.json..."

SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_COMMAND="~/.claude/hooks/check-repo-before-install.sh"

# The hook entry we want to add
HOOK_ENTRY='{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/check-repo-before-install.sh"
    }
  ]
}'

if [[ ! -f "$SETTINGS_FILE" ]]; then
  # No settings.json — create one with the hook
  cat > "$SETTINGS_FILE" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/check-repo-before-install.sh"
          }
        ]
      }
    ]
  }
}
EOF
  echo -e "        ${GREEN}Created ~/.claude/settings.json with hook${NC}"

elif ! command -v jq &> /dev/null; then
  # jq not available — can't safely merge
  echo -e "        ${YELLOW}Skipped:${NC} jq is required to auto-register the hook."
  echo -e "        Add this manually to ~/.claude/settings.json (see INSTALL.md)"

else
  # Check if hook is already registered
  ALREADY_REGISTERED=$(jq -r '
    .hooks.PreToolUse // [] |
    map(select(.hooks[]?.command == "~/.claude/hooks/check-repo-before-install.sh")) |
    length
  ' "$SETTINGS_FILE" 2>/dev/null || echo "0")

  if [[ "$ALREADY_REGISTERED" -gt 0 ]]; then
    echo -e "        ${GREEN}Already registered${NC} — skipping"
  else
    # Merge the hook into existing settings.json
    TEMP_FILE=$(mktemp)
    jq --argjson hook "$HOOK_ENTRY" '
      .hooks //= {} |
      .hooks.PreToolUse //= [] |
      .hooks.PreToolUse += [$hook]
    ' "$SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SETTINGS_FILE"
    echo -e "        ${GREEN}Registered in ~/.claude/settings.json${NC}"
  fi
fi

echo ""
echo -e "${GREEN}Done.${NC} The security kit is active."
echo ""
echo "Next time you (or Claude) run git clone, the hook will:"
echo "  1. Block the clone"
echo "  2. Clone to /tmp/ for inspection"
echo "  3. Run a full security audit (14 categories)"
echo "  4. Ask for your approval before installing"
echo ""
