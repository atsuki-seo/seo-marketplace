#!/usr/bin/env bash
# 現在のリンク状態を表示する
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
MARKETPLACE_NAME="claude-code-customizations"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Claude Code Customizations ステータス ==="
echo "リポジトリ: $REPO_DIR"
echo ""

# --- ルールの状態 ---
echo "--- ルール ---"
if [ -d "$REPO_DIR/rules" ] && ls "$REPO_DIR/rules"/*.md &>/dev/null; then
  for rule in "$REPO_DIR/rules"/*.md; do
    name="$(basename "$rule")"
    target="$CLAUDE_DIR/rules/$name"
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$rule")" ]; then
      echo -e "  ${GREEN}[linked]${NC}  $name"
    elif [ -L "$target" ]; then
      echo -e "  ${YELLOW}[stale]${NC}   $name → $(readlink "$target")"
    elif [ -e "$target" ]; then
      echo -e "  ${YELLOW}[exists]${NC}  $name（実ファイル、リンクではない）"
    else
      echo -e "  ${RED}[missing]${NC} $name"
    fi
  done
else
  echo "  （ルールファイルなし）"
fi

echo ""

# --- マーケットプレイスの状態 ---
echo "--- マーケットプレイス ---"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  CURRENT_PATH=$(jq -r ".extraKnownMarketplaces.\"$MARKETPLACE_NAME\".source.path // empty" "$SETTINGS_FILE" 2>/dev/null)
  if [ "$CURRENT_PATH" = "$REPO_DIR" ]; then
    echo -e "  ${GREEN}[registered]${NC} $MARKETPLACE_NAME → $REPO_DIR"
  elif [ -n "$CURRENT_PATH" ]; then
    echo -e "  ${YELLOW}[stale]${NC}      $MARKETPLACE_NAME → $CURRENT_PATH（期待値: $REPO_DIR）"
  else
    echo -e "  ${RED}[missing]${NC}    $MARKETPLACE_NAME"
  fi
else
  echo "  （jq 未インストールまたは settings.json なし）"
fi

echo ""

# --- プラグインの状態 ---
echo "--- プラグイン ---"
PLUGINS_DIR="$REPO_DIR/plugins"
INSTALLED_FILE="$CLAUDE_DIR/plugins/installed_plugins.json"

if [ -d "$PLUGINS_DIR" ]; then
  for plugin_dir in "$PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    plugin_key="${name}@${MARKETPLACE_NAME}"

    # plugin.json の存在確認
    if [ ! -f "$plugin_dir/.claude-plugin/plugin.json" ]; then
      echo -e "  ${RED}[invalid]${NC}      $name（plugin.json なし）"
      continue
    fi

    # enabledPlugins の確認
    enabled="no"
    if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
      if jq -e ".enabledPlugins[\"$plugin_key\"]" "$SETTINGS_FILE" &>/dev/null; then
        enabled="yes"
      fi
    fi

    # installed_plugins.json の確認
    installed="no"
    if [ -f "$INSTALLED_FILE" ] && command -v jq &>/dev/null; then
      if jq -e ".plugins[\"$plugin_key\"]" "$INSTALLED_FILE" &>/dev/null; then
        installed="yes"
      fi
    fi

    if [ "$enabled" = "yes" ] && [ "$installed" = "yes" ]; then
      echo -e "  ${GREEN}[ok]${NC}           $plugin_key"
    elif [ "$enabled" = "yes" ]; then
      echo -e "  ${YELLOW}[not installed]${NC} $plugin_key（install.sh を実行してください）"
    elif [ "$installed" = "yes" ]; then
      echo -e "  ${YELLOW}[disabled]${NC}     $plugin_key（enabledPlugins に未登録）"
    else
      echo -e "  ${RED}[missing]${NC}      $plugin_key（install.sh を実行してください）"
    fi
  done
else
  echo "  （プラグインなし）"
fi
