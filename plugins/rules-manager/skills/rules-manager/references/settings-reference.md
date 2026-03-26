# settings.json リファレンス

settings.json の編集時に参照する主要な設定キーの一覧。

## 設定ファイルの場所

| スコープ | パス | 優先度 |
|---------|------|--------|
| Managed | システムレベル | 最高（オーバーライド不可） |
| ローカル | `.claude/settings.local.json` | 高 |
| プロジェクト | `.claude/settings.json` | 中 |
| ユーザー | `~/.claude/settings.json` | 低 |

配列設定（`permissions.allow` 等）はスコープ間でマージ（連結・重複排除）される。

---

## 権限設定

```json
{
  "permissions": {
    "allow": ["Tool(specifier)"],
    "ask": ["Tool(specifier)"],
    "deny": ["Tool(specifier)"],
    "defaultMode": "default",
    "additionalDirectories": ["/path/to/dir"]
  }
}
```

**権限ルール構文**: `Tool` または `Tool(specifier)` 形式

| 例 | 意味 |
|----|------|
| `"Bash(npm test)"` | `npm test` コマンドを許可 |
| `"Bash(grep:*)"` | grep で始まるコマンドを許可 |
| `"Read(./.env)"` | .env ファイルの読み取り（deny に使う場合は拒否） |
| `"Edit"` | すべてのファイル編集 |

**評価順序**: deny → ask → allow

---

## サンドボックス設定

```json
{
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": false,
    "autoAllowBashIfSandboxed": false,
    "excludedCommands": ["docker"],
    "filesystem": {
      "allowWrite": ["/tmp"],
      "denyWrite": ["/etc"],
      "allowRead": [],
      "denyRead": ["/etc/shadow"]
    },
    "network": {
      "allowedDomains": ["api.example.com"],
      "allowLocalBinding": false
    }
  }
}
```

**パスプレフィックス**:
- `/` — 絶対パス
- `~/` — ホームディレクトリ相対
- `./` またはプレフィックスなし — プロジェクト相対

---

## 環境変数

```json
{
  "env": {
    "NODE_ENV": "development",
    "DEBUG": "true"
  }
}
```

---

## フック設定

```json
{
  "hooks": {
    "preToolUse": [
      {
        "matcher": "Bash",
        "command": "echo 'Bash tool used'"
      }
    ],
    "postToolUse": [],
    "onNotification": []
  }
}
```

---

## その他の主要設定

| キー | 型 | 説明 |
|------|-----|------|
| `model` | string | デフォルトモデル |
| `language` | string | 応答言語 |
| `effortLevel` | "low" / "medium" / "high" | 努力レベル |
| `outputStyle` | string | 出力スタイル |
| `includeGitInstructions` | boolean | git ワークフロー命令の有無 |
| `autoMemoryEnabled` | boolean | 自動メモリの有効/無効 |
| `autoMemoryDirectory` | string | メモリ保存先カスタムパス |
| `attribution.commit` | string | コミットの属性表記（空で無効化） |
| `attribution.pr` | string | PRの属性表記（空で無効化） |
| `voiceEnabled` | boolean | 音声入力 |
| `alwaysThinkingEnabled` | boolean | 拡張思考のデフォルト有効化 |

---

## Worktree 設定

| キー | 説明 |
|------|------|
| `worktree.symlinkDirectories` | シンボリックリンクするディレクトリ |
| `worktree.sparsePaths` | sparse-checkout でチェックアウトするパス |
