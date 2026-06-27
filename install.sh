#!/usr/bin/env bash
# OpenCode VPN Web Search Skill - macOS/Linux Installer
# Requires: OpenCode, curl, a running proxy client

set -e

echo ""
echo "============================================"
echo " OpenCode VPN Web Search Skill - Installer "
echo "============================================"
echo ""

# Check if OpenCode is installed
if ! command -v opencode &> /dev/null; then
    echo "[!] OpenCode not found in PATH."
    echo "    Please install OpenCode first: https://opencode.ai/download"
    exit 1
fi
echo "[+] OpenCode found at: $(which opencode)"

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "[!] curl not found. Please install curl first."
    exit 1
fi
echo "[+] curl found at: $(which curl)"

# Ask for proxy port
echo ""
read -p "Enter your local proxy address [http://127.0.0.1:7890]: " proxy_input
PROXY_ADDRESS="${proxy_input:-http://127.0.0.1:7890}"
echo "[+] Proxy address set to: $PROXY_ADDRESS"

# Determine shell config file
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    SHELL_CONFIG="$HOME/.profile"
fi

# Set environment variable persistently
echo ""
echo "Setting OPENCODE_VPN_PROXY environment variable in $SHELL_CONFIG..."

# Remove existing OPENCODE_VPN_PROXY line if present
if [ -f "$SHELL_CONFIG" ]; then
    if grep -q "OPENCODE_VPN_PROXY" "$SHELL_CONFIG"; then
        # macOS sed needs an empty backup extension
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/OPENCODE_VPN_PROXY/d' "$SHELL_CONFIG"
        else
            sed -i '/OPENCODE_VPN_PROXY/d' "$SHELL_CONFIG"
        fi
    fi
fi

echo "export OPENCODE_VPN_PROXY=\"$PROXY_ADDRESS\"" >> "$SHELL_CONFIG"
export OPENCODE_VPN_PROXY="$PROXY_ADDRESS"
echo "[+] Environment variable OPENCODE_VPN_PROXY set successfully."

# Determine target directory
SKILL_DIR="$HOME/.config/opencode/skills/vpn-web-search"
echo ""
echo "Installing Skill to: $SKILL_DIR"

# Create directory
mkdir -p "$SKILL_DIR"

# Copy SKILL.md
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILL="$SCRIPT_DIR/skills/vpn-web-search/SKILL.md"
if [ -f "$SOURCE_SKILL" ]; then
    cp "$SOURCE_SKILL" "$SKILL_DIR/SKILL.md"
    echo "[+] SKILL.md copied successfully."
else
    echo "[!] SKILL.md not found at: $SOURCE_SKILL"
    echo "    Make sure you are running this script from the repository root."
    exit 1
fi

# Check if we're in a project with opencode.json
PROJECT_CONFIG="$(pwd)/opencode.json"
if [ -f "$PROJECT_CONFIG" ]; then
    echo ""
    echo "Found project opencode.json, merging webfetch deny permission..."
    if command -v python3 &> /dev/null; then
        python3 -c "
import json, sys
try:
    with open('$PROJECT_CONFIG', 'r') as f:
        config = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    config = {}
if 'permission' not in config:
    config['permission'] = {}
config['permission']['webfetch'] = 'deny'
with open('$PROJECT_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
print('[+] webfetch: deny added to opencode.json')
" 2>/dev/null || {
            echo "[!] python3 not found, cannot auto-update opencode.json"
            echo "    Add manually: { \"permission\": { \"webfetch\": \"deny\" } }"
        }
    else
        echo "[!] python3 not found, cannot auto-update opencode.json"
        echo "    Add manually: { \"permission\": { \"webfetch\": \"deny\" } }"
    fi
else
    echo ""
    echo "No project opencode.json found. You can add webfetch deny manually:"
    echo '  Add to opencode.json: { "permission": { "webfetch": "deny" } }'
fi

# Done
echo ""
echo "============================================"
echo " Installation Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source $SHELL_CONFIG"
echo "  2. Restart OpenCode"
echo "  3. Verify the skill appears: type /skills in OpenCode"
echo "  4. Test: ask OpenCode to fetch a page through VPN"
echo ""
echo "Proxy: $PROXY_ADDRESS"
echo ""

# Verify proxy connectivity
echo "Testing proxy connectivity..."
HTTP_CODE=$(curl --proxy "$PROXY_ADDRESS" -sL -o /dev/null -w "%{http_code}" "https://raw.githubusercontent.com" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "[+] Proxy test PASSED - raw.githubusercontent.com is reachable"
else
    echo "[!] Proxy test returned HTTP $HTTP_CODE"
    echo "    Check if your proxy client is running and the port is correct."
fi

echo ""
