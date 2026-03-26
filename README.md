# claude-code-customizations

Claude Code のユーザーレベルルールとローカルプラグイン（スキル）を一元管理するリポジトリ。

## セットアップ

```bash
git clone <this-repo> ~/claude-code-customizations
cd ~/claude-code-customizations
chmod +x scripts/*.sh
./scripts/install.sh
```

`install.sh` は以下を行います：
- ルールファイルを `~/.claude/rules/` にシンボリックリンクでデプロイ
- ローカルマーケットプレイスとして `settings.json` の `extraKnownMarketplaces` に登録
- プラグインを `enabledPlugins` と `installed_plugins.json` に登録

完了後、Claude Code を再起動してください。

> **前提**: `jq` が必要です（`sudo apt install jq` / `brew install jq`）

## 含まれるもの

### ルール (`rules/`)

`~/.claude/rules/` にデプロイされるユーザーレベルルール。

### プラグイン (`plugins/`)

| プラグイン | 説明 |
|-----------|------|
| **rules-manager** | `.claude/rules/` へのルール追加、パススコープ指定、`settings.json` の編集 |

## 日常の使い方

### 設定を更新する

```bash
cd ~/claude-code-customizations
git pull
./scripts/status.sh    # 差分を確認
./scripts/install.sh   # 新しいプラグインがあれば登録
```

既存ファイルの内容変更は `git pull` だけで反映されます。

### 状態を確認する

```bash
./scripts/status.sh
```

### アンインストール

```bash
./scripts/uninstall.sh
```

## 構造

```
claude-code-customizations/
├── .claude-plugin/
│   └── marketplace.json   # ローカルマーケットプレイス定義
├── scripts/
│   ├── install.sh         # デプロイ（マーケットプレイス登録 + プラグイン有効化）
│   ├── add-plugin.sh      # skill-creator で作ったスキルをプラグインに変換
│   ├── status.sh          # 状態確認
│   └── uninstall.sh       # アンインストール
├── rules/                 # ユーザーレベルルール (.md)
├── plugins/
│   └── rules-manager/     # ルール・設定管理スキル
└── README.md
```
