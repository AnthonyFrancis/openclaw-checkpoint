#!/bin/bash
# install-openclaw-checkpoint.sh - One-liner install for openclaw-checkpoint skill
# Run with: curl -fsSL https://raw.githubusercontent.com/AnthonyFrancis/openclaw-checkpoint/main/scripts/install-openclaw-checkpoint.sh | bash

set -e

SKILL_NAME="openclaw-checkpoint"
REPO_URL="https://github.com/AnthonyFrancis/openclaw-checkpoint.git"
INSTALL_DIR="${HOME}/.openclaw/skills/${SKILL_NAME}"
TOOLS_DIR="${HOME}/.openclaw/workspace/tools"

echo "🚀 Installing OpenClaw Checkpoint Skill..."
echo ""

# Check for git
if ! command -v git &> /dev/null; then
    echo "❌ git is required but not installed"
    exit 1
fi

# Create directories
echo "📁 Creating directories..."
mkdir -p "${HOME}/.openclaw/skills"
mkdir -p "${TOOLS_DIR}"

# Clone or update skill repo
echo "⬇️  Downloading skill..."
if [ -d "${INSTALL_DIR}/.git" ]; then
    # Already installed, pull updates
    git -C "${INSTALL_DIR}" pull --quiet || {
        echo "⚠️  Could not update, using existing version"
    }
else
    # Fresh install
    rm -rf "${INSTALL_DIR}"
    git clone --quiet "${REPO_URL}" "${INSTALL_DIR}" || {
        echo "❌ Failed to download skill"
        exit 1
    }
fi

# Copy scripts to tools directory (for easy PATH access)
echo "🧰 Installing commands..."
cp "${INSTALL_DIR}/scripts/checkpoint"* "${TOOLS_DIR}/"
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
echo "   checkpoint          - Show all commands"
echo "   checkpoint-setup    - Interactive setup wizard"
echo "   checkpoint-backup   - Backup now"
echo "   checkpoint-restore   - Restore from remote"
echo "   checkpoint-status   - Check backup health"
echo "   checkpoint-schedule - Set auto-backup frequency"
echo "   checkpoint-stop     - Stop automatic backups"
echo "   checkpoint-reset   - Reset for fresh setup"
echo ""
echo "🚀 Next step: Run the setup wizard"
echo "   checkpoint-setup"
echo ""

# Ask to run setup now
read -p "Run setup wizard now? [Y/n]: " RUN_SETUP
RUN_SETUP=${RUN_SETUP:-Y}

if [[ "${RUN_SETUP}" =~ ^[Yy]$ ]]; then
    echo ""
    checkpoint-setup
fi

# Reload shell so PATH changes take effect immediately
# This replaces the current process with a fresh login shell
# so the user doesn't need to manually run 'source ~/.zshrc'
echo ""
echo "🔄 Reloading shell to apply PATH changes..."
exec "$SHELL" -l
