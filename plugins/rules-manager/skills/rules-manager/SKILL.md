---
name: rules-manager
description: >-
  Claude Code のルールや設定を追加・管理するスキル。
  .claude/rules/ へのルールファイル作成、パススコープ付きルール、settings.json の編集に対応。
  「ルールを追加」「コーディング規約を設定」「settings.json を編集」「権限を追加」
  「サンドボックス設定」「パス指定のルールを作りたい」「プロジェクトにルールを追加」
  などのリクエスト時に使用する。ルール、規約、設定、権限、サンドボックスに関する
  あらゆるリクエストでこのスキルを発動すること。
tools: Read, Write, Edit, Glob, Grep, Bash
user-invocable: true
---

# Rules Manager

Claude Code のルールファイルを作成・管理し、`settings.json` を編集するスキル。

## リポジトリパスの取得

ユーザーレベルルールは `claude-code-customizations` リポジトリの `rules/` に保存して git で同期する。
リポジトリのパスは以下で取得する：

```bash
jq -r '.extraKnownMarketplaces."claude-code-customizations".source.path // empty' ~/.claude/settings.json
```

取得できない場合はユーザーにリポジトリのパスを確認する。

## 基本原則

1. **必ずスコープを確認する** — 作業を始める前に、ユーザーに以下を聞く。迷ったら「ユーザー（同期）」を推奨する。
   確認なしにファイルを作成してはいけない。

2. **既存ルールを確認してから作成する** — 重複を防ぐため、作成前に既存ルールを一覧する。

3. **変更前にプレビューを見せる** — settings.json の編集は特に、変更内容を提示して承認を得てから適用する。

---

## ワークフロー 1: ルールファイルの作成

### Step 1: スコープの確認

ユーザーに以下の選択肢を提示する：

| スコープ | パス | 共有範囲 | 備考 |
|---------|------|---------|------|
| プロジェクト | `.claude/rules/` | チーム全員（git コミット） | |
| ユーザー（同期）**推奨** | `<リポジトリ>/rules/` | 自分だけ・全プロジェクト共通 | git で同期される。`install.sh` でシンボリックリンク作成が必要 |
| ユーザー（ローカル） | `~/.claude/rules/` | 自分だけ・全プロジェクト共通 | 同期されない |

### Step 2: 既存ルールの確認

```bash
# プロジェクトレベル
ls .claude/rules/*.md 2>/dev/null

# ユーザーレベル（リポジトリ内 — 同期対象）
REPO=$(jq -r '.extraKnownMarketplaces."claude-code-customizations".source.path // empty' ~/.claude/settings.json)
[ -n "$REPO" ] && ls "$REPO"/rules/*.md 2>/dev/null

# ユーザーレベル（ローカル）
ls ~/.claude/rules/*.md 2>/dev/null
```

既存ルールがあれば一覧を見せて、新規作成か既存の更新かを確認する。

### Step 3: ルールファイルの作成

**ファイル名**: ルールの内容を端的に表す英語のケバブケース（例: `api-conventions.md`, `test-patterns.md`）

**基本形式**（パススコープなし）:

```markdown
# ルールのタイトル

- 具体的な指示1
- 具体的な指示2
```

**パススコープ付き形式**（特定のファイルにのみ適用）:

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/api/**/*.tsx"
---

# API 開発ルール

- すべてのエンドポイントでエラーハンドリングを実装する
- レスポンス型を明示的に定義する
```

### パススコープの書き方

`paths` フィールドはグロブパターンの配列。ルールはマッチするファイルを Claude が操作するときだけ適用される。

| パターン | 意味 |
|---------|------|
| `"src/**/*.ts"` | src 以下の全 TypeScript ファイル |
| `"*.py"` | ルート直下の Python ファイル |
| `"tests/**"` | tests ディレクトリ以下すべて |
| `"src/api/**/*.{ts,tsx}"` | src/api 以下の TS/TSX ファイル |

ユーザーがパスの指定に迷っている場合は、プロジェクト構造を調べて適切なパターンを提案する。

### Step 4: 作成内容の確認

ファイルを作成する前に、以下を提示して確認を取る：
- ファイルパス
- ファイル内容（フロントマター含む）
- パススコープの適用範囲（該当する場合）

### Step 5: 作成後の案内（ユーザー（同期）スコープの場合）

リポジトリの `rules/` に新規ファイルを作成した場合、シンボリックリンクの作成が必要。以下を案内する：

```bash
cd <リポジトリのパス>
./scripts/install.sh
```

既存ファイルの編集の場合はシンボリックリンクが既にあるため不要。

---

## ワークフロー 2: settings.json の編集

### Step 1: スコープの確認

| スコープ | パス | 影響範囲 |
|---------|------|---------|
| ユーザー | `~/.claude/settings.json` | 全プロジェクト共通 |
| プロジェクト（共有） | `.claude/settings.json` | チーム全員 |
| プロジェクト（ローカル） | `.claude/settings.local.json` | 自分だけ（このプロジェクト内） |

### Step 2: 現在の設定を読み込む

対象の settings.json を読み込んで現在の状態を把握する。

### Step 3: 変更内容をプレビュー

変更前と変更後を diff 形式で提示する：

```diff
 {
   "permissions": {
     "allow": [
-      "Bash(grep:*)"
+      "Bash(grep:*)",
+      "Bash(npm test)"
     ]
   }
 }
```

### Step 4: 承認後に適用

ユーザーの承認を得てから Edit ツールで適用する。

### 主な設定カテゴリ

設定の詳細は [references/settings-reference.md](references/settings-reference.md) を参照。

**よく編集される設定:**
- `permissions.allow` / `permissions.deny` — 権限ルール
- `sandbox.*` — サンドボックス設定
- `env` — 環境変数
- `hooks` — ライフサイクルフック
- `model` — デフォルトモデル
- `language` — 応答言語

---

## ルール作成のベストプラクティス

- **具体的に書く**: 「コードを適切にフォーマットする」ではなく「2スペースインデントを使用する」
- **簡潔に保つ**: 1ファイルあたり主題を1つに絞る
- **実行可能な指示にする**: Claude が判断に迷わない明確な表現を使う
- **パススコープを活用する**: 全体に適用する必要のないルールはスコープを絞る
- **英語のケバブケースでファイル名をつける**: `api-conventions.md`, `test-patterns.md` など
