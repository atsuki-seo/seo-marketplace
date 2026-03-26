#!/usr/bin/env bash
# claude-code-customizations install script
# ローカルマーケットプレイスとして ~/.claude/settings.json に登録し、
# ルールはシンボリックリンクでデプロイする
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
MARKETPLACE_NAME="claude-code-customizations"

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

# --- ルールのデプロイ ---
echo ""
echo "=== ルールのデプロイ ==="
RULES_DIR="$REPO_DIR/rules"
if [ -d "$RULES_DIR" ] && ls "$RULES_DIR"/*.md &>/dev/null; then
  for rule in "$RULES_DIR"/*.md; do
    name="$(basename "$rule")"
    target="$CLAUDE_DIR/rules/$name"
    if [ -L "$target" ]; then
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

# --- プラグインの確認 ---
echo ""
echo "=== プラグインの確認 ==="
PLUGINS_DIR="$REPO_DIR/plugins"

if [ -d "$PLUGINS_DIR" ]; then
  for plugin_dir in "$PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    name="$(basename "$plugin_dir")"
    if [ -f "$plugin_dir/.claude-plugin/plugin.json" ]; then
      info "検出: plugins/$name"
    else
      warn "plugin.json なし: plugins/$name"
    fi
  done
else
  warn "plugins/ にプラグインがありません"
fi

# --- jq の確認 ---
if ! command -v jq &>/dev/null; then
  error "jq が見つかりません。インストールしてください:"
  echo "  Ubuntu/Debian: sudo apt install jq"
  echo "  macOS: brew install jq"
  echo "  Arch: sudo pacman -S jq"
  exit 1
fi

# --- settings.json の設定 ---
echo ""
echo "=== settings.json の登録 ==="
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
  info "settings.json を新規作成"
fi

BACKUP="$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"
cp "$SETTINGS_FILE" "$BACKUP"
info "バックアップ: $BACKUP"

# extraKnownMarketplaces にローカルマーケットプレイスを登録
CURRENT_PATH=$(jq -r ".extraKnownMarketplaces.\"$MARKETPLACE_NAME\".source.path // empty" "$SETTINGS_FILE" 2>/dev/null)
if [ "$CURRENT_PATH" = "$REPO_DIR" ]; then
  info "マーケットプレイス登録済み: $MARKETPLACE_NAME"
else
  jq --arg name "$MARKETPLACE_NAME" --arg path "$REPO_DIR" \
    '.extraKnownMarketplaces //= {} | .extraKnownMarketplaces[$name] = {"source": {"source": "directory", "path": $path}}' \
    "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  info "マーケットプレイス登録: $MARKETPLACE_NAME → $REPO_DIR"
fi

# enabledPlugins にプラグインを登録
for plugin_dir in "$PLUGINS_DIR"/*/; do
  [ -d "$plugin_dir" ] || continue
  name="$(basename "$plugin_dir")"
  plugin_key="${name}@${MARKETPLACE_NAME}"

  if jq -e ".enabledPlugins[\"$plugin_key\"]" "$SETTINGS_FILE" &>/dev/null; then
    info "有効化済み: $plugin_key"
  else
    jq --arg key "$plugin_key" '.enabledPlugins //= {} | .enabledPlugins[$key] = true' \
      "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    info "有効化: $plugin_key"
  fi
done

# --- installed_plugins.json の登録 ---
echo ""
echo "=== installed_plugins.json の登録 ==="
INSTALLED_FILE="$CLAUDE_DIR/plugins/installed_plugins.json"

if [ ! -f "$INSTALLED_FILE" ]; then
  echo '{"version": 2, "plugins": {}}' > "$INSTALLED_FILE"
  info "installed_plugins.json を新規作成"
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
for plugin_dir in "$PLUGINS_DIR"/*/; do
  [ -d "$plugin_dir" ] || continue
  name="$(basename "$plugin_dir")"
  plugin_key="${name}@${MARKETPLACE_NAME}"
  install_path="$PLUGINS_DIR/$name"

  if jq -e ".plugins[\"$plugin_key\"]" "$INSTALLED_FILE" &>/dev/null; then
    # installPath を更新（リポジトリの場所が変わった場合に対応）
    jq --arg key "$plugin_key" --arg path "$install_path" --arg now "$NOW" \
      '.plugins[$key][0].installPath = $path | .plugins[$key][0].lastUpdated = $now' \
      "$INSTALLED_FILE" > "${INSTALLED_FILE}.tmp" && mv "${INSTALLED_FILE}.tmp" "$INSTALLED_FILE"
    info "更新: $plugin_key"
  else
    jq --arg key "$plugin_key" --arg path "$install_path" --arg now "$NOW" \
      '.plugins[$key] = [{"scope": "user", "installPath": $path, "version": "unknown", "installedAt": $now, "lastUpdated": $now}]' \
      "$INSTALLED_FILE" > "${INSTALLED_FILE}.tmp" && mv "${INSTALLED_FILE}.tmp" "$INSTALLED_FILE"
    info "登録: $plugin_key"
  fi
done

# --- 古い directory: 形式のエントリを削除 ---
for plugin_dir in "$PLUGINS_DIR"/*/; do
  [ -d "$plugin_dir" ] || continue
  name="$(basename "$plugin_dir")"
  old_key="directory:$PLUGINS_DIR/$name"
  if jq -e ".enabledPlugins[\"$old_key\"]" "$SETTINGS_FILE" &>/dev/null; then
    jq --arg key "$old_key" 'del(.enabledPlugins[$key])' \
      "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    info "旧形式を削除: $old_key"
  fi
done

# --- 完了 ---
echo ""
echo "=== セットアップ完了 ==="
echo "Claude Code を再起動すると変更が反映されます。"
echo "状態確認: ./scripts/status.sh"
