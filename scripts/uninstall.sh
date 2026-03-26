#!/usr/bin/env bash
# プラグイン登録を解除してアンインストール
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
MARKETPLACE_NAME="claude-code-customizations"

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

# --- enabledPlugins から削除 ---
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
PLUGINS_DIR="$REPO_DIR/plugins"

if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  for plugin_dir in "$PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    plugin_key="${name}@${MARKETPLACE_NAME}"
    if jq -e ".enabledPlugins[\"$plugin_key\"]" "$SETTINGS_FILE" &>/dev/null; then
      jq --arg key "$plugin_key" 'del(.enabledPlugins[$key])' \
        "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
      info "無効化: $plugin_key"
    fi
  done

  # マーケットプレイスの登録を解除
  if jq -e ".extraKnownMarketplaces.\"$MARKETPLACE_NAME\"" "$SETTINGS_FILE" &>/dev/null; then
    jq --arg name "$MARKETPLACE_NAME" 'del(.extraKnownMarketplaces[$name])' \
      "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    info "マーケットプレイス登録解除: $MARKETPLACE_NAME"
  fi
fi

# --- installed_plugins.json から削除 ---
INSTALLED_FILE="$CLAUDE_DIR/plugins/installed_plugins.json"
if [ -f "$INSTALLED_FILE" ] && command -v jq &>/dev/null; then
  for plugin_dir in "$PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    plugin_key="${name}@${MARKETPLACE_NAME}"
    if jq -e ".plugins[\"$plugin_key\"]" "$INSTALLED_FILE" &>/dev/null; then
      jq --arg key "$plugin_key" 'del(.plugins[$key])' \
        "$INSTALLED_FILE" > "${INSTALLED_FILE}.tmp" && mv "${INSTALLED_FILE}.tmp" "$INSTALLED_FILE"
      info "インストール情報削除: $plugin_key"
    fi
  done
fi

echo ""
echo "アンインストール完了。Claude Code を再起動してください。"
