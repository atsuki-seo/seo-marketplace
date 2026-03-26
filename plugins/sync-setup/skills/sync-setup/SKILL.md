---
name: sync-setup
description: >-
  claude-code-customizations リポジトリの初期セットアップ、設定同期、状態確認を行うスキル。
  「セットアップ」「同期」「設定を反映」「install」「新しいマシンで設定」
  「ルールとプラグインをデプロイ」「リンク状態を確認」「カスタム設定を別のマシンに移す」
  などのリクエスト時に使用する。dotclaude リポジトリ、dotfiles 同期、
  Claude Code の環境セットアップに関するあらゆるリクエストで発動すること。
tools: Read, Bash, Glob, Grep
user-invocable: true
---

# Sync Setup

`claude-code-customizations` リポジトリからユーザーの `~/.claude/` 環境へルールとプラグインをデプロイ・同期するスキル。

## リポジトリ構造

このスキルが想定するリポジトリ構造:

```
claude-code-customizations/
├── scripts/
│   ├── install.sh      # デプロイ（シンボリックリンク作成 + enabledPlugins 登録）
│   ├── status.sh       # 状態確認
│   └── uninstall.sh    # アンインストール
├── rules/              # ユーザーレベルルール (.md)
├── plugins/            # ローカルプラグイン群
└── README.md
```

## ワークフロー

ユーザーのリクエストに応じて、以下の3つのワークフローから適切なものを選ぶ。
判断に迷ったら、まず **状態確認** を実行して現状を把握してから提案する。

---

### 1. 初期セットアップ（新しいマシン）

ユーザーが「新しいマシンでセットアップしたい」「初期設定」と言ったとき。

#### Step 1: リポジトリの場所を確認

ユーザーにリポジトリのパスを確認する。一般的な場所:
- `~/claude-code-customizations`
- `~/dotfiles/claude-code-customizations`
- `~/repos/claude-code-customizations`

まだ clone していない場合は、clone のコマンドを提示する。

#### Step 2: 前提条件チェック

```bash
# jq が入っているか（enabledPlugins の自動登録に必要）
command -v jq && echo "OK" || echo "jq がありません"

# ~/.claude/ が存在するか
ls -la ~/.claude/ 2>/dev/null || echo "~/.claude/ がありません（Claude Code の初回起動が必要）"
```

jq がなければインストール方法を案内:
- **Ubuntu/Debian**: `sudo apt install jq`
- **macOS**: `brew install jq`
- **Arch**: `sudo pacman -S jq`

#### Step 3: install.sh の実行

```bash
cd <リポジトリのパス>
chmod +x scripts/install.sh scripts/status.sh scripts/uninstall.sh
./scripts/install.sh
```

実行結果を確認し、エラーがあれば対処する。

#### Step 4: 動作確認

```bash
./scripts/status.sh
```

すべて `[linked]` / `[registered]` になっていれば成功。
Claude Code の再起動を促す。

---

### 2. 同期（既存マシンの更新）

ユーザーが「同期」「最新の設定を反映」「pull して反映」と言ったとき。

#### Step 1: git pull

```bash
cd <リポジトリのパス>
git pull
```

#### Step 2: 新しいルール/プラグインの検出

```bash
./scripts/status.sh
```

`[missing]` のエントリがあれば、新しく追加されたルールやプラグイン。

#### Step 3: install.sh の再実行

新しいエントリがあれば:
```bash
./scripts/install.sh
```

シンボリックリンク方式のため、既存のリンク先ファイルの内容変更は `git pull` だけで反映される。
`install.sh` の再実行が必要なのは、新しいファイル/ディレクトリが追加された場合のみ。

---

### 3. 状態確認

ユーザーが「状態を確認」「リンクの状況」と言ったとき。

```bash
cd <リポジトリのパス>
./scripts/status.sh
```

出力の見方:
- `[linked]` — 正常にリンク済み
- `[stale]` — リンク先が古い（install.sh を再実行で修正）
- `[exists]` — 実ファイルが存在（手動でバックアップ後にリンクに置換が必要）
- `[missing]` — リンクされていない（install.sh で作成）
- `[registered]` — settings.json に登録済み

---

## トラブルシューティング

| 症状 | 原因 | 対処 |
|------|------|------|
| スキルが認識されない | enabledPlugins 未登録 | `install.sh` 再実行 or 手動で settings.json に追加 |
| `[exists]` が表示される | 元のファイルが実ファイル | バックアップ後 `rm` してから `install.sh` |
| jq がない | 未インストール | パッケージマネージャでインストール |
| `~/.claude/` がない | Claude Code 未起動 | 一度 `claude` コマンドを実行 |
| install.sh 権限エラー | 実行権限なし | `chmod +x scripts/*.sh` |

## アンインストール

```bash
cd <リポジトリのパス>
./scripts/uninstall.sh
```

シンボリックリンクの削除と enabledPlugins の登録解除のみ行う。
リポジトリ自体やルール/プラグインの実ファイルは削除しない。
