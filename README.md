# flapmind-statusline

Claude Code 用のカスタムステータスライン。
ターミナル下部に **コンテキスト使用量・5時間ウィンドウ・週間ウィンドウ・コスト** などをリアルタイム表示します。

```
[Opus 4.7 (1M context)] | 📁 myproject | 🌿 main | +48/-3 | $0.789
Context: ████████░░░░░░░░░░░░ [42%]
Session: █░░░░░░░░░░░░░░░░░░░ [7%]  ↻ 3h41m · 3.5M tok
Weekly:  ███████████████░░░░░ [78%] ↻ 3d22h
```

## 表示項目

| 行 | 内容 |
|---|---|
| 1行目 | モデル名 / カレントディレクトリ / git ブランチ / 累計編集行数 / 推定コスト($) |
| Context | 現在のセッションのコンテキストウィンドウ使用率 |
| Session | 5時間制限の使用率 + リセットまでの残り時間 + 累計トークン |
| Weekly | 7日間制限の使用率 + リセットまでの残り時間 |

色は使用率に応じて変化します（〜69% 緑 / 70〜89% 黄 / 90%〜 赤）。

> 💡 **Session / Weekly について**
> Claude Pro / Max サブスクライバー向けの値です。新しいセッションで最初のメッセージを送るまでは `--` 表示になります。

## 必要なもの

- Claude Code v2.1.88 以上（公式 statusLine 仕様に対応したバージョン）
- `jq` （JSON パーサ）
  - Mac: `brew install jq`
  - Windows: `choco install jq` または `winget install jqlang.jq`
- bash 4.x 以上（macOS 標準の bash でも動作）

## インストール

### 方式A: ワンライナー（推奨）

```bash
curl -fsSL https://raw.githubusercontent.com/michaelkei/flapmind-statusline/main/install.sh | bash
```

これだけで完了。最も手軽です。

### 方式B: git clone + install.sh

リポジトリの中身を確認してから入れたい・カスタマイズしてから入れたい場合：

```bash
git clone https://github.com/michaelkei/flapmind-statusline.git
cd flapmind-statusline
bash install.sh
```

---

どちらの方式でも実行内容は同じ：

1. `~/.claude/flapmind-statusline.sh` にスクリプトを配置
2. `~/.claude/settings.json` の `statusLine` を書き換え（既存は `settings.json.bak` にバックアップ）

**新しい Claude Code セッションを開くとステータスラインが反映されます。**
（実行中のセッションは `/exit` で抜けてから `claude` で起動し直してください）

## 手動インストール

`install.sh` を使わず手動で設定したい場合：

1. `statusline.sh` を `~/.claude/flapmind-statusline.sh` にコピーして実行権限を付与
   ```bash
   cp statusline.sh ~/.claude/flapmind-statusline.sh
   chmod +x ~/.claude/flapmind-statusline.sh
   ```
2. `~/.claude/settings.json` を編集して以下を追記
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "/bin/bash ~/.claude/flapmind-statusline.sh",
       "padding": 0
     }
   }
   ```

## アンインストール

`~/.claude/settings.json` から `statusLine` セクションを削除（またはバックアップ `settings.json.bak` に戻す）してください。

## カスタマイズ

`~/.claude/flapmind-statusline.sh` を直接編集すれば、色・並び順・表示項目を自由に変更できます。
公式仕様で渡される JSON フィールド一覧：

https://code.claude.com/docs/ja/statusline

## ライセンス

MIT

## クレジット

Claude.ai 公式の statusLine 仕様（`rate_limits.five_hour` / `rate_limits.seven_day` 等）を利用しています。
プロジェクト名は FLAP MIND（ https://flapmind.com ）に由来します。
