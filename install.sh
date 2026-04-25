#!/bin/bash
# flapmind-statusline インストーラ
#
# 使い方:
#   方式A（curl ワンライナー）: curl -fsSL https://raw.githubusercontent.com/michaelkei/flapmind-statusline/main/install.sh | bash
#   方式B（git clone後）       : bash install.sh
#
# 動作: スクリプトを ~/.claude/flapmind-statusline.sh にコピーし、
#       ~/.claude/settings.json の statusLine を書き換える。
#       既存設定はバックアップ（settings.json.bak）に保存。

set -e

REPO_RAW="https://raw.githubusercontent.com/michaelkei/flapmind-statusline/main"
CLAUDE_DIR="$HOME/.claude"
SCRIPT_DST="$CLAUDE_DIR/flapmind-statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

# 起動方法を判定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
LOCAL_SRC="$SCRIPT_DIR/statusline.sh"

mkdir -p "$CLAUDE_DIR"

# スクリプト本体を取得
if [ -f "$LOCAL_SRC" ]; then
    # ローカル（git clone後）モード
    cp "$LOCAL_SRC" "$SCRIPT_DST"
    echo "✅ ローカルから配置: $SCRIPT_DST"
else
    # リモート（curl | bash）モード
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_RAW/statusline.sh" -o "$SCRIPT_DST"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$SCRIPT_DST" "$REPO_RAW/statusline.sh"
    else
        echo "エラー: curl も wget も見つかりません。インストールできません。"
        exit 1
    fi
    echo "✅ GitHubからダウンロード→配置: $SCRIPT_DST"
fi
chmod +x "$SCRIPT_DST"

# jq の確認
if ! command -v jq >/dev/null 2>&1; then
    echo ""
    echo "⚠️  jq が見つかりません。先にインストールしてください:"
    echo "    Mac:     brew install jq"
    echo "    Windows: choco install jq  または  winget install jqlang.jq"
    echo ""
    echo "（ステータスラインの動作に jq が必須です）"
fi

# settings.json の更新
if [ -f "$SETTINGS" ]; then
    cp "$SETTINGS" "$SETTINGS.bak"
    echo "📦 既存設定をバックアップ: $SETTINGS.bak"
fi

if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
    # jqで安全に statusLine を上書き
    tmp=$(mktemp)
    jq --arg cmd "/bin/bash $SCRIPT_DST" \
       '.statusLine = {"type":"command","command":$cmd,"padding":0}' \
       "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "✅ settings.json の statusLine を更新しました"
elif [ ! -f "$SETTINGS" ]; then
    cat > "$SETTINGS" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "/bin/bash $SCRIPT_DST",
    "padding": 0
  }
}
EOF
    echo "✅ settings.json を新規作成しました"
else
    echo ""
    echo "⚠️  jq が無いため settings.json を自動更新できません。"
    echo "    jq を入れてからもう一度このコマンドを実行するか、"
    echo "    以下を手動で settings.json に追記してください:"
    echo ""
    echo '  "statusLine": {'
    echo '    "type": "command",'
    echo "    \"command\": \"/bin/bash $SCRIPT_DST\","
    echo '    "padding": 0'
    echo '  }'
fi

echo ""
echo "🎉 インストール完了！"
echo "新しい Claude Code セッションを開くとステータスラインが反映されます。"
echo "（Claude Code を一度 /exit で終了して、もう一度 claude で起動）"
