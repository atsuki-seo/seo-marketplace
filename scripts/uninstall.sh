#!/usr/bin/env bash
# シンボリックリンクを削除してアンインストール
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[SKIP]${NC} $1"; }

echo "=== アンインストール ==="

# --- ルールのリンク削除 ---
if [ -d "$REPO_DIR/rules" ]; then
  for rule in "$REPO_DIR/rules"/*.md; do
    [ -f "$rule" ] || continue
    name="$(basename "$rule")"
    target="$CLAUDE_DIR/rules/$name"
    if [ -L "$target" ]; then
      rm "$target"
      info "削除: rules/$name"
    else
      warn "リンクではない: rules/$name"
    fi
  done
fi

# --- プラグインのリンク削除 ---
PLUGIN_DEST="$CLAUDE_DIR/plugins/local"
if [ -d "$REPO_DIR/plugins" ]; then
  for plugin_dir in "$REPO_DIR/plugins"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    target="$PLUGIN_DEST/$name"
    if [ -L "$target" ]; then
      rm "$target"
      info "削除: plugins/$name"
    else
      warn "リンクではない: plugins/$name"
    fi
  done
fi

# --- enabledPlugins から削除 ---
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  for plugin_dir in "$REPO_DIR/plugins"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    plugin_key="directory:$PLUGIN_DEST/$name"
    if jq -e ".enabledPlugins[\"$plugin_key\"]" "$SETTINGS_FILE" &>/dev/null; then
      jq --arg key "$plugin_key" 'del(.enabledPlugins[$key])' \
        "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
      info "登録解除: $plugin_key"
    fi
  done
fi

echo ""
echo "アンインストール完了。Claude Code を再起動してください。"
