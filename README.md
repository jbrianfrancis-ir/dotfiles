# Claude Code Configuration

This repository contains my Claude Code configuration synced across all devices.

## Structure

```
claude-code-config/
├── mcp/
│   ├── user-servers.json          # User-scoped MCP servers
│   └── project-servers.json.template
├── skills/                         # All skills
├── plugins/                        # Installed plugins
├── settings/
│   ├── settings.json              # Main settings (synced)
│   └── settings.local.json.template
└── sync.sh                        # Sync script
```

## Quick Start

### Initial Setup on New Device

```bash
# Clone this repo
git clone <repo-url> ~/claude-code-config

# Pull and apply configuration
~/claude-code-config/sync.sh pull
```

### Daily Usage

```bash
# Pull latest changes
~/claude-code-config/sync.sh pull

# Save local changes and push
~/claude-code-config/sync.sh push

# Bidirectional sync (pull + push)
~/claude-code-config/sync.sh sync
```

## Secrets Management

**Never commit secrets to this repo!**

Store API keys and tokens in environment variables:

```bash
# In ~/.bashrc or ~/.zshrc
export OPENAI_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."
export SUPERMEMORY_API_KEY="sm_..."
```

Reference them in MCP configs using `${VAR}` syntax.

## Machine-Specific Settings

Copy `settings/settings.local.json.template` to `~/.claude/settings.local.json` and customize for each machine.

## Project-Scoped MCP Servers

Use `.mcp.json` in project directories for project-specific servers. Don't sync these here - they belong in the project repo.

## Created

$(date)

Host: $(hostname)
OS: $(uname -s)
