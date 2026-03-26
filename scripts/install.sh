#!/usr/bin/env bash
# claude-code-customizations install script
# シンボリックリンクで ~/.claude/ にルールとプラグインをデプロイする
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

# 色付き出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[SKIP]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- 前提ディレクトリの作成 ---
mkdir -p "$CLAUDE_DIR/rules"
mkdir -p "$CLAUDE_DIR/plugins/local"

# --- ルールのデプロイ ---
echo ""
echo "=== ルールのデプロイ ==="
RULES_DIR="$REPO_DIR/rules"
if [ -d "$RULES_DIR" ] && ls "$RULES_DIR"/*.md &>/dev/null; then
  for rule in "$RULES_DIR"/*.md; do
    name="$(basename "$rule")"
    target="$CLAUDE_DIR/rules/$name"
    if [ -L "$target" ]; then
      # 既存のシンボリックリンクを更新
      ln -sfn "$rule" "$target"
      info "更新: rules/$name"
    elif [ -e "$target" ]; then
      warn "実ファイルが既存: rules/$name（手動で確認してください）"
    else
      ln -sfn "$rule" "$target"
      info "リンク: rules/$name"
    fi
  done
else
  warn "rules/ にルールファイルがありません"
fi

# --- プラグインのデプロイ ---
echo ""
echo "=== プラグインのデプロイ ==="
PLUGINS_DIR="$REPO_DIR/plugins"
PLUGIN_DEST="$CLAUDE_DIR/plugins/local"

if [ -d "$PLUGINS_DIR" ]; then
  for plugin_dir in "$PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    target="$PLUGIN_DEST/$name"
    if [ -L "$target" ]; then
      ln -sfn "$plugin_dir" "$target"
      info "更新: plugins/$name"
    elif [ -e "$target" ]; then
      warn "実ディレクトリが既存: plugins/$name（手動で確認してください）"
    else
      ln -sfn "$plugin_dir" "$target"
      info "リンク: plugins/$name"
    fi
  done
else
  warn "plugins/ にプラグインがありません"
fi

# --- enabledPlugins の自動登録 ---
echo ""
echo "=== enabledPlugins の登録 ==="
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# settings.json が存在しない場合は作成
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
  info "settings.json を新規作成"
fi

# jq が利用可能か確認
if command -v jq &>/dev/null; then
  BACKUP="$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS_FILE" "$BACKUP"
  info "バックアップ: $BACKUP"

  for plugin_dir in "$PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    plugin_key="directory:$PLUGIN_DEST/$name"

    # 既に登録済みか確認
    if jq -e ".enabledPlugins[\"$plugin_key\"]" "$SETTINGS_FILE" &>/dev/null; then
      info "登録済み: $plugin_key"
    else
      # enabledPlugins オブジェクトがなければ作成
      jq --arg key "$plugin_key" '.enabledPlugins //= {} | .enabledPlugins[$key] = true' \
        "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
      info "登録: $plugin_key"
    fi
  done
else
  error "jq が見つかりません。以下を手動で settings.json に追加してください:"
  for plugin_dir in "$PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    echo "  \"directory:$PLUGIN_DEST/$name\": true"
  done
  echo ""
  echo "jq のインストール: sudo apt install jq / brew install jq"
fi

# --- 完了 ---
echo ""
echo "=== セットアップ完了 ==="
echo "Claude Code を再起動すると変更が反映されます。"
echo "状態確認: ./scripts/status.sh"
