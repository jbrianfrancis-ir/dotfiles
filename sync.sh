#!/bin/bash
# Claude Code Configuration Sync Script

set -e

REPO_DIR="$HOME/claude-code-config"
CLAUDE_DIR="$HOME/.claude"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude Code Configuration Sync${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

# Check if repo exists
if [ ! -d "$REPO_DIR/.git" ]; then
    echo -e "${YELLOW}Error: $REPO_DIR is not a git repository${NC}"
    exit 1
fi

# Pull latest changes
pull_config() {
    echo -e "\n${GREEN}📥 Pulling latest configuration...${NC}"
    cd "$REPO_DIR"
    
    if git remote | grep -q origin; then
        git pull origin main || git pull origin master
        echo -e "${GREEN}✓ Pulled latest changes${NC}"
    else
        echo -e "${YELLOW}⚠ No remote configured, skipping pull${NC}"
    fi
}

# Apply configuration
apply_config() {
    echo -e "\n${GREEN}⚙️  Applying configuration...${NC}"
    
    # Create Claude dirs if they don't exist
    mkdir -p "$CLAUDE_DIR"/{skills,plugins}
    
    # Sync MCP servers
    if [ -f "$REPO_DIR/mcp/user-servers.json" ]; then
        echo "  → Syncing MCP servers"
        [ -f ~/.claude.json ] && cp ~/.claude.json ~/.claude.json.backup
        cp "$REPO_DIR/mcp/user-servers.json" ~/.claude.json
    fi
    
    # Sync skills
    if [ -d "$REPO_DIR/skills" ] && [ "$(ls -A $REPO_DIR/skills)" ]; then
        echo "  → Syncing skills"
        if command -v rsync &> /dev/null; then
            rsync -av --delete "$REPO_DIR/skills/" "$CLAUDE_DIR/skills/"
        else
            rm -rf "$CLAUDE_DIR/skills"
            cp -r "$REPO_DIR/skills" "$CLAUDE_DIR/skills"
        fi
    fi
    
    # Sync plugins
    if [ -d "$REPO_DIR/plugins" ] && [ "$(ls -A $REPO_DIR/plugins)" ]; then
        echo "  → Syncing plugins"
        if command -v rsync &> /dev/null; then
            rsync -av --delete "$REPO_DIR/plugins/" "$CLAUDE_DIR/plugins/"
        else
            rm -rf "$CLAUDE_DIR/plugins"
            cp -r "$REPO_DIR/plugins" "$CLAUDE_DIR/plugins"
        fi
    fi
    
    # Sync settings (don't overwrite local)
    if [ -f "$REPO_DIR/settings/settings.json" ]; then
        echo "  → Syncing settings.json"
        cp "$REPO_DIR/settings/settings.json" "$CLAUDE_DIR/settings.json"
    fi
    
    echo -e "${GREEN}✓ Configuration applied${NC}"
}

# Save local changes
save_config() {
    echo -e "\n${GREEN}💾 Saving local changes...${NC}"
    
    cd "$REPO_DIR"
    
    # Export current state
    [ -f ~/.claude.json ] && cp ~/.claude.json mcp/user-servers.json && echo "  → Exported MCP servers"
    
    if [ -d "$CLAUDE_DIR/skills" ]; then
        if command -v rsync &> /dev/null; then
            rsync -av --delete "$CLAUDE_DIR/skills/" skills/
        else
            rm -rf skills
            cp -r "$CLAUDE_DIR/skills" skills
        fi
        echo "  → Exported skills"
    fi
    
    if [ -d "$CLAUDE_DIR/plugins" ]; then
        if command -v rsync &> /dev/null; then
            rsync -av --delete "$CLAUDE_DIR/plugins/" plugins/
        else
            rm -rf plugins
            cp -r "$CLAUDE_DIR/plugins" plugins
        fi
        echo "  → Exported plugins"
    fi
    
    [ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" settings/settings.json && echo "  → Exported settings"
    
    # Commit and push
    if [ -n "$(git status --porcelain)" ]; then
        git add -A
        git commit -m "Update config from $(hostname) at $(date '+%Y-%m-%d %H:%M:%S')"
        
        if git remote | grep -q origin; then
            git push origin main || git push origin master
            echo -e "${GREEN}✓ Changes pushed to remote${NC}"
        else
            echo -e "${YELLOW}⚠ No remote configured, changes committed locally only${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ No changes to commit${NC}"
    fi
}

# Main logic
case "$1" in
    pull)
        pull_config
        apply_config
        ;;
    push)
        save_config
        ;;
    sync)
        pull_config
        apply_config
        save_config
        ;;
    status)
        cd "$REPO_DIR"
        echo -e "\n${BLUE}Repository status:${NC}"
        git status
        echo -e "\n${BLUE}Recent commits:${NC}"
        git log --oneline -5
        ;;
    *)
        echo "Usage: $0 {pull|push|sync|status}"
        echo ""
        echo "Commands:"
        echo "  pull   - Pull latest config from remote and apply locally"
        echo "  push   - Save local changes and push to remote"
        echo "  sync   - Bidirectional sync (pull → apply → push)"
        echo "  status - Show git status and recent commits"
        echo ""
        echo "Tip: Add alias to ~/.bashrc:"
        echo "  alias cc-sync='~/claude-code-config/sync.sh'"
        exit 1
        ;;
esac

echo -e "\n${GREEN}✓ Done!${NC}\n"
