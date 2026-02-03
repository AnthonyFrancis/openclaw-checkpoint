#!/bin/bash
# install-openclaw-checkpoint.sh - One-liner install for openclaw-checkpoint skill

set -e

SKILL_NAME="openclaw-checkpoint"
SKILL_URL="https://raw.githubusercontent.com/openclaw/openclaw/main/skills/openclaw-checkpoint.skill"
INSTALL_DIR="${HOME}/.openclaw/skills/${SKILL_NAME}"
TOOLS_DIR="${HOME}/.openclaw/workspace/tools"

echo "🚀 Installing OpenClaw Checkpoint Skill..."
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p "${INSTALL_DIR}"
mkdir -p "${TOOLS_DIR}"

# Download skill
echo "⬇️  Downloading skill..."
if command -v curl &> /dev/null; then
    curl -fsSL "${SKILL_URL}" -o "/tmp/${SKILL_NAME}.skill" || {
        echo "❌ Failed to download skill"
        exit 1
    }
elif command -v wget &> /dev/null; then
    wget -q "${SKILL_URL}" -O "/tmp/${SKILL_NAME}.skill" || {
        echo "❌ Failed to download skill"
        exit 1
    }
else
    echo "❌ curl or wget required"
    exit 1
fi

# Extract skill
echo "📦 Extracting skill..."
unzip -q -o "/tmp/${SKILL_NAME}.skill" -d "${INSTALL_DIR}"
rm "/tmp/${SKILL_NAME}.skill"

# Copy scripts to tools directory (for easy PATH access)
echo "🧰 Installing commands..."
cp "${INSTALL_DIR}/scripts/"* "${TOOLS_DIR}/"
chmod +x "${TOOLS_DIR}/"checkpoint*

# Detect shell and add to PATH
echo "🔧 Configuring PATH..."
SHELL_NAME=$(basename "${SHELL}")
PATH_EXPORT='export PATH="${HOME}/.openclaw/workspace/tools:${PATH}"'

add_to_shell_config() {
    local config_file="$1"
    if [ -f "${config_file}" ]; then
        if ! grep -q "openclaw/workspace/tools" "${config_file}"; then
            echo "" >> "${config_file}"
            echo "# OpenClaw Checkpoint tools" >> "${config_file}"
            echo "${PATH_EXPORT}" >> "${config_file}"
            echo "✅ Added to ${config_file}"
            return 0
        else
            echo "✅ Already in ${config_file}"
            return 0
        fi
    fi
    return 1
}

# Try to add to appropriate shell config
case "${SHELL_NAME}" in
    zsh)
        add_to_shell_config "${HOME}/.zshrc" || add_to_shell_config "${HOME}/.zprofile"
        ;;
    bash)
        add_to_shell_config "${HOME}/.bashrc" || add_to_shell_config "${HOME}/.bash_profile"
        ;;
    *)
        # Try common files
        add_to_shell_config "${HOME}/.profile" || \
        add_to_shell_config "${HOME}/.bashrc" || \
        add_to_shell_config "${HOME}/.zshrc"
        ;;
esac

# Also add to current session
eval "${PATH_EXPORT}"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Installed commands:"
echo "   checkpoint-setup    - Interactive setup wizard"
echo "   checkpoint          - Backup now"
echo "   checkpoint-resume   - Restore from remote"
echo "   checkpoint-schedule - Set auto-backup frequency"
echo "   checkpoint-status   - Check backup health"
echo ""
echo "🚀 Next step: Run the setup wizard"
echo "   checkpoint-setup"
echo ""
echo "Note: Open a new terminal or run 'source ~/.zshrc' (or ~/.bashrc)"
echo "      to use commands without full path in current session."
echo ""

# Ask to run setup now
read -p "Run setup wizard now? [Y/n]: " RUN_SETUP
RUN_SETUP=${RUN_SETUP:-Y}

if [[ "${RUN_SETUP}" =~ ^[Yy]$ ]]; then
    echo ""
    checkpoint-setup
fi
