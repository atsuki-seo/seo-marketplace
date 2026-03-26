#!/usr/bin/env bash
# skill-creator で作成したスキルをプラグインとしてリポジトリに統合する
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGINS_DIR="$REPO_DIR/plugins"
MARKETPLACE_FILE="$REPO_DIR/.claude-plugin/marketplace.json"

# 色付き出力
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# --- 使い方 ---
usage() {
  echo "Usage: $0 <skill-directory>"
  echo ""
  echo "skill-creator で作成したスキルディレクトリを指定してください。"
  echo "SKILL.md が含まれているディレクトリが必要です。"
  echo ""
  echo "例: $0 ~/my-skill"
  exit 1
}

# --- 引数チェック ---
[ $# -ge 1 ] || usage
SKILL_DIR="$(cd "$1" 2>/dev/null && pwd)" || { error "ディレクトリが見つかりません: $1"; exit 1; }
SKILL_MD="$SKILL_DIR/SKILL.md"

[ -f "$SKILL_MD" ] || { error "SKILL.md が見つかりません: $SKILL_DIR/"; exit 1; }

# --- jq の確認 ---
command -v jq &>/dev/null || { error "jq が必要です (sudo apt install jq / brew install jq)"; exit 1; }

# --- SKILL.md からメタデータを抽出 ---
# フロントマターの --- ... --- の間から name と description を取得
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_MD" | sed '1d;$d')

NAME=$(echo "$FRONTMATTER" | grep -E '^name:' | sed 's/^name:[[:space:]]*//')
if [ -z "$NAME" ]; then
  error "SKILL.md に name フィールドがありません"
  exit 1
fi

# description を取得（複数行対応: >- 形式も処理）
DESCRIPTION=$(echo "$FRONTMATTER" | sed -n '/^description:/,/^[a-z]/{/^description:/s/^description:[[:space:]]*>*-*[[:space:]]*//p;/^  /s/^[[:space:]]*//p}' | tr '\n' ' ' | sed 's/[[:space:]]*$//')
if [ -z "$DESCRIPTION" ]; then
  DESCRIPTION="$NAME プラグイン"
fi

echo "=== スキルの統合 ==="
echo "名前: $NAME"
echo "説明: $DESCRIPTION"
echo "ソース: $SKILL_DIR"
echo ""

# --- 重複チェック ---
if [ -d "$PLUGINS_DIR/$NAME" ]; then
  error "プラグインが既に存在します: plugins/$NAME/"
  exit 1
fi

# --- プラグイン構造の作成 ---
PLUGIN_DIR="$PLUGINS_DIR/$NAME"
SKILL_DEST="$PLUGIN_DIR/skills/$NAME"

mkdir -p "$PLUGIN_DIR/.claude-plugin"
mkdir -p "$SKILL_DEST"

# skill-creator の出力をコピー
cp -r "$SKILL_DIR"/* "$SKILL_DEST/"
info "スキルをコピー: plugins/$NAME/skills/$NAME/"

# --- plugin.json の生成 ---
AUTHOR=$(git config user.name 2>/dev/null || echo "unknown")
jq -n --arg name "$NAME" --arg desc "$DESCRIPTION" --arg author "$AUTHOR" \
  '{name: $name, description: $desc, version: "1.0.0", author: {name: $author}}' \
  > "$PLUGIN_DIR/.claude-plugin/plugin.json"
info "plugin.json を作成"

# --- marketplace.json にエントリを追加 ---
if [ -f "$MARKETPLACE_FILE" ]; then
  if jq -e ".plugins[] | select(.name == \"$NAME\")" "$MARKETPLACE_FILE" &>/dev/null; then
    info "marketplace.json に既にエントリがあります"
  else
    jq --arg name "$NAME" --arg desc "$DESCRIPTION" \
      '.plugins += [{"name": $name, "description": $desc, "source": ("./plugins/" + $name)}]' \
      "$MARKETPLACE_FILE" > "${MARKETPLACE_FILE}.tmp" && mv "${MARKETPLACE_FILE}.tmp" "$MARKETPLACE_FILE"
    info "marketplace.json にエントリを追加"
  fi
else
  error "marketplace.json が見つかりません: $MARKETPLACE_FILE"
  exit 1
fi

# --- 完了 ---
echo ""
echo "=== 完了 ==="
echo "プラグインを追加しました: plugins/$NAME/"
echo ""
echo "次のステップ:"
echo "  1. ./scripts/install.sh を実行して登録"
echo "  2. Claude Code を再起動"
