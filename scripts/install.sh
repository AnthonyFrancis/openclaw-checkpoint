#!/bin/bash
# Quick install for openclaw-checkpoint
# Run with: curl -fsSL https://thisweek.is/checkpoint-install.sh | bash

set -e

echo "🚀 Installing OpenClaw Checkpoint..."

# Create dirs
mkdir -p ~/.openclaw/skills ~/.openclaw/workspace/tools

# Download and extract
curl -fsSL "https://thisweek.is/openclaw-checkpoint.skill" -o /tmp/oc-checkpoint.skill 2>/dev/null || {
    echo "⚠️  Download failed, using local copy..."
    # Fallback: use files from workspace if available
}

# If we have the skill file, extract it
if [ -f "/tmp/oc-checkpoint.skill" ]; then
    unzip -q -o /tmp/oc-checkpoint.skill -d ~/.openclaw/skills/openclaw-checkpoint/
    rm /tmp/oc-checkpoint.skill
fi

# Remove old checkpoint scripts first (handles renames like checkpoint-resume → checkpoint-restore)
rm -f ~/.openclaw/workspace/tools/checkpoint*

# Copy scripts to tools
cp ~/.openclaw/skills/openclaw-checkpoint/scripts/checkpoint* ~/.openclaw/workspace/tools/ 2>/dev/null || {
    echo "❌ Skill not found. Please download openclaw-checkpoint.skill first."
    exit 1
}

chmod +x ~/.openclaw/workspace/tools/checkpoint*

# Add to PATH in shell config
SHELL_CONFIG=""
[ -f ~/.zshrc ] && SHELL_CONFIG="~/.zshrc"
[ -f ~/.bashrc ] && SHELL_CONFIG="~/.bashrc"

if [ -n "$SHELL_CONFIG" ]; then
    if ! grep -q ".openclaw/workspace/tools" "${SHELL_CONFIG/#\~/$HOME}" 2>/dev/null; then
        echo "" >> "${SHELL_CONFIG/#\~/$HOME}"
        echo 'export PATH="${HOME}/.openclaw/workspace/tools:${PATH}"' >> "${SHELL_CONFIG/#\~/$HOME}"
        echo "✅ Added to $SHELL_CONFIG"
    fi
fi

# Export for current session
export PATH="${HOME}/.openclaw/workspace/tools:${PATH}"

echo ""
echo "✅ Installed! Available commands:"
echo "   checkpoint-setup - Run setup wizard"
echo ""
read -p "Run setup now? [Y/n]: " RUN
if [[ "${RUN:-Y}" =~ ^[Yy]$ ]]; then
    checkpoint-setup
fi

# Reload shell so PATH changes take effect immediately
echo ""
echo "🔄 Reloading shell to apply PATH changes..."
exec "$SHELL" -l
