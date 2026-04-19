# seo-marketplace

自分用の Claude Code ローカルマーケットプレイス。

## 同梱プラグイン

- `grill-me` — [mattpocock/skills](https://github.com/mattpocock/skills) の [grill-me](https://github.com/mattpocock/skills/tree/main/grill-me) を取り込んだもの（MIT License, © Matt Pocock）。

## インストール方法

### 方法 1: コマンドで手動追加（個人利用向け）

Claude Code 内で以下を実行する。

```bash
/plugin marketplace add atsuki-seo/seo-marketplace
```

自分の端末で試したいだけ、または単発で導入したい場合はこちらが手軽。

### 方法 2: プロジェクトで自動登録（チーム共有向け）

プロジェクトの `.claude/settings.json` に `extraKnownMarketplaces` を追記してリポジトリにコミットする。プロジェクトを開いたメンバーがフォルダを信頼するタイミングでマーケットプレイスのインストールが提案される。

```json
{
  "extraKnownMarketplaces": {
    "seo-marketplace": {
      "source": {
        "source": "github",
        "repo": "atsuki-seo/seo-marketplace"
      }
    }
  }
}
```

- キー（`"seo-marketplace"`）は任意の表示名。
- 各メンバーは `/plugin marketplace add` を打つ必要なし。

### 使い分け

| 状況 | 推奨 |
| --- | --- |
| チーム・複数端末で共有したい | 方法 2（`extraKnownMarketplaces`） |
| 自分の端末だけで試したい | 方法 1（`/plugin marketplace add`） |
