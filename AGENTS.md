# AGENTS.md — flapmind-statusline

Claude Code 用のカスタム `statusLine` 実装を配布するリポジトリ。
公式 `statusLine` 仕様（stdin で JSON を受け取り、stdout に描画するシェルスクリプト）に準拠。

## 技術スタック
- Bash（macOS 標準の bash 3.2 以上 / zsh 環境でも動作）
- `jq`（JSON パーサ・実行時必須依存）
- curl または wget（リモート取得時）

## ファイル構成
- `statusline.sh` — 本体。Claude Code から stdin 経由で受け取る JSON を解釈し、4行のステータスラインを描画
- `install.sh` — インストーラ。curl ワンライナーと git clone の両方に対応
- `README.md` — 利用者向けドキュメント
- `LICENSE` — MIT

## 利用する JSON フィールド（公式仕様）
- `model.display_name` / `context_window.context_window_size` / `context_window.used_percentage`
- `context_window.total_input_tokens` / `context_window.total_output_tokens`
- `cost.total_cost_usd` / `cost.total_lines_added` / `cost.total_lines_removed`
- `rate_limits.five_hour.used_percentage` / `rate_limits.five_hour.resets_at`
- `rate_limits.seven_day.used_percentage` / `rate_limits.seven_day.resets_at`
- `workspace.current_dir`

> 公式仕様: https://code.claude.com/docs/ja/statusline

## 表示内容
```
[Opus 4.7 (1M context)] | 📁 dir | 🌿 branch | +N/-N | $cost
Context: ████████░░░░░░░░░░░░ [N%]
Session: █░░░░░░░░░░░░░░░░░░░ [N%]  ↻ Xh Xm · N.NM tok
Weekly:  ███████████████░░░░░ [N%]  ↻ Xd Xh
```
色分け: 0-69% 緑 / 70-89% 黄 / 90%- 赤

## ビルド・テスト
- ビルド不要（シェルスクリプト）
- 手動テスト:
  ```bash
  echo '{"model":{"display_name":"Opus 4.7"},"workspace":{"current_dir":"/tmp"},"context_window":{"context_window_size":200000,"used_percentage":42}}' | bash statusline.sh
  ```
- jq が未インストールの環境では `install.sh` が警告を出す

## 配布先
- GitHub: https://github.com/michaelkei/flapmind-statusline （public / MIT）

## コーディング規約
- シェルスクリプトは POSIX 互換性より bash 依存を許容（macOS / Linux 前提）
- ユーザーに見えるメッセージは日本語を基本とする
- `set -e` で失敗時即停止

## 禁止事項
- `.env` 系ファイルのコミット禁止
- Secret（API キー・トークン等）のハードコード禁止
- Claude Code の `settings.json` を差分以外の形で破壊しない（必ず `.bak` にバックアップ）

## 作業フロー
- 変更は `main` ブランチに直接コミット可（個人プロジェクト）
- push 前に簡易手動テストで動作確認
