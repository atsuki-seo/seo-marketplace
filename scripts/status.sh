#!/usr/bin/env bash
# 現在のリンク状態を表示する
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

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

# --- プラグインの状態 ---
echo "--- プラグイン ---"
PLUGIN_DEST="$CLAUDE_DIR/plugins/local"
if [ -d "$REPO_DIR/plugins" ]; then
  for plugin_dir in "$REPO_DIR/plugins"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    target="$PLUGIN_DEST/$name"
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$plugin_dir")" ]; then
      echo -e "  ${GREEN}[linked]${NC}  $name"
    elif [ -L "$target" ]; then
      echo -e "  ${YELLOW}[stale]${NC}   $name → $(readlink "$target")"
    elif [ -e "$target" ]; then
      echo -e "  ${YELLOW}[exists]${NC}  $name（実ディレクトリ、リンクではない）"
    else
      echo -e "  ${RED}[missing]${NC} $name"
    fi
  done
else
  echo "  （プラグインなし）"
fi

echo ""

# --- enabledPlugins の状態 ---
echo "--- enabledPlugins ---"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  for plugin_dir in "$REPO_DIR/plugins"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    plugin_key="directory:$PLUGIN_DEST/$name"
    if jq -e ".enabledPlugins[\"$plugin_key\"]" "$SETTINGS_FILE" &>/dev/null; then
      echo -e "  ${GREEN}[registered]${NC} $plugin_key"
    else
      echo -e "  ${RED}[missing]${NC}    $plugin_key"
    fi
  done
else
  echo "  （jq 未インストールまたは settings.json なし）"
fi
