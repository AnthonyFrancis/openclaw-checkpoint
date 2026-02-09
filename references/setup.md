# Detailed Setup Guide

## Prerequisites

- Git installed
- GitHub account
- OpenClaw installed and configured

## Step-by-Step Setup

### 1. Initialize on Primary Machine

```bash
# Run the init command
checkpoint-init

# Output:
# 🚀 Initializing OpenClaw checkpoint system...
# 📦 Initializing git repository...
# 📝 Creating .gitignore...
# 💾 Creating initial checkpoint...
# ✅ Workspace initialized for checkpoint/restore
```

### 2. Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `openclaw-state` (or your preference)
3. Visibility: **Private** (important!)
4. Do NOT initialize with README, .gitignore, or license
5. Click "Create repository"
6. On the next page: **Ignore GitHub's "Quick setup" commands.** Do not run any of the commands GitHub shows (they would create a README and break the backup). Just return to your terminal and continue with the setup.

### 3. Connect and Push

```bash
cd ~/.openclaw/workspace

# Add remote
git remote add origin https://github.com/YOURGITHUBUSERNAME/openclaw-state.git

# Verify
 git remote -v
# origin  https://github.com/YOURUSERNAME/openclaw-state.git (fetch)
# origin  https://github.com/YOURUSERNAME/openclaw-state.git (push)

# Push initial checkpoint
checkpoint-backup

# Output:
# 💾 Saving checkpoint...
# ☁️  Pushing to origin/main...
# ✅ Checkpoint saved successfully
#    Time: 2026-02-02 14:30:15
#    Commit: a1b2c3d
```

### 4. Set Up Automated Backups (Optional but Recommended)

```bash
# Edit crontab
crontab -e

# Add this line for hourly backups:
0 * * * * /Users/$(whoami)/.openclaw/workspace/skills/openclaw-checkpoint/scripts/checkpoint-backup >> /tmp/openclaw-backup.log 2>&1

# Or use launchd on macOS (more reliable when sleeping)
# Create ~/Library/LaunchAgents/com.openclaw.checkpoint.plist
```

### 5. Test Restore Process

Before relying on this, test restoring:

```bash
# Create a test memory
echo "Test: I love testing backups" >> ~/.openclaw/workspace/MEMORY.md

# Checkpoint
checkpoint-backup

# Clone to temporary location to simulate new machine
git clone https://github.com/YOURUSERNAME/openclaw-state.git /tmp/openclaw-test

# Verify test memory is there
grep "love testing" /tmp/openclaw-test/MEMORY.md
# Should output: Test: I love testing backups

# Cleanup
rm -rf /tmp/openclaw-test
```

## Setting Up Second Machine

### Scenario: New Laptop

```bash
# 1. Install OpenClaw
brew install openclaw

# 2. Clone your state
git clone https://github.com/YOURUSERNAME/openclaw-state.git ~/.openclaw/workspace

# 3. Install the skill
cd ~/.openclaw/workspace
# The skill is already in the repo!

# 4. Restore secrets from 1Password
# Create .env.thisweek
cat > ~/.openclaw/workspace/.env.thisweek << 'EOF'
THISWEEK_API_KEY=your_key_from_1password
EOF

# Create .env.stripe
cat > ~/.openclaw/workspace/.env.stripe << 'EOF'
STRIPE_API_KEY=your_key_from_1password
EOF

# 5. Start OpenClaw
openclaw gateway start

# 6. Verify
# Ask: "What were we working on?"
# Should know everything up to last checkpoint
```

## Authentication Methods

### HTTPS with Personal Access Token (Recommended)

```bash
# Generate token at https://github.com/settings/tokens
# Scopes needed: repo (full control of private repositories)

# When pushing, use token as password
# Username: your-github-username
# Password: ghp_xxxxxxxxxxxx (your token)

# Or use GitHub CLI:
gh auth login
# Select HTTPS, then login via browser
```

### SSH (More Secure)

```bash
# Generate key
ssh-keygen -t ed25519 -C "openclaw-backup"

# Add to GitHub: https://github.com/settings/keys
# Copy public key:
cat ~/.ssh/id_ed25519.pub

# Use SSH URL instead:
git remote set-url origin git@github.com:YOURUSERNAME/openclaw-state.git
```

## Recovery Scenarios

### Laptop Stolen

1. Revoke GitHub token (if using HTTPS with PAT)
2. Generate new token
3. Buy/rent new laptop
4. Clone repo: `git clone https://github.com/... ~/.openclaw/workspace`
5. Restore secrets from 1Password
6. Done

### House Burns Down

Same as laptop stolen — your data is safe on GitHub's servers.

### Accidentally Deleted Files

```bash
# See what was lost
git status

# Restore from last checkpoint
checkpoint-resume

# Or restore specific file from history
git checkout HEAD -- MEMORY.md
```

### Corrupted Workspace

```bash
# Nuclear option: wipe and restore
rm -rf ~/.openclaw/workspace

# Restore from GitHub
git clone https://github.com/YOURUSERNAME/openclaw-state.git ~/.openclaw/workspace

# Restore secrets
# (copy from 1Password)
```

## Monitoring

Check backup status:

```bash
# See last backup time
cd ~/.openclaw/workspace
git log -1 --format="%cd" --date=relative

# See if behind remote
git fetch origin
git status

# Count commits not pushed
git rev-list HEAD...origin/main --count
```

## Security Checklist

- [ ] Repository is private (not public)
- [ ] 2FA enabled on GitHub account
- [ ] .env.* files are in .gitignore (never committed)
- [ ] API keys stored in password manager (1Password, etc.)
- [ ] Personal Access Token has minimal scopes (just repo)
- [ ] Regularly rotate GitHub token (every 90 days)
