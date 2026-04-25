#!/bin/bash
# flapmind-statusline インストーラ
# 使い方: bash install.sh
#
# 動作: スクリプトを ~/.claude/flapmind-statusline.sh にコピーし、
#       ~/.claude/settings.json の statusLine を書き換える。
#       既存の statusLine 設定はバックアップ（settings.json.bak）に保存。

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_SRC="$(cd "$(dirname "$0")" && pwd)/statusline.sh"
SCRIPT_DST="$CLAUDE_DIR/flapmind-statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

if [ ! -f "$SCRIPT_SRC" ]; then
    echo "エラー: statusline.sh が見つかりません: $SCRIPT_SRC"
    exit 1
fi

mkdir -p "$CLAUDE_DIR"

# スクリプトをコピー
cp "$SCRIPT_SRC" "$SCRIPT_DST"
chmod +x "$SCRIPT_DST"
echo "✅ スクリプトを配置しました: $SCRIPT_DST"

# jq の確認
if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️  jq が見つかりません。インストールしてください:"
    echo "    Mac:     brew install jq"
    echo "    Windows: choco install jq  または  winget install jqlang.jq"
fi

# settings.json の更新
if [ -f "$SETTINGS" ]; then
    cp "$SETTINGS" "$SETTINGS.bak"
    echo "📦 既存設定をバックアップしました: $SETTINGS.bak"
fi

if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
    # jqで安全に statusLine を上書き
    tmp=$(mktemp)
    jq --arg cmd "/bin/bash $SCRIPT_DST" \
       '.statusLine = {"type":"command","command":$cmd,"padding":0}' \
       "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "✅ settings.json の statusLine を更新しました"
else
    # settings.json が無い場合は新規作成
    if [ ! -f "$SETTINGS" ]; then
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
        echo "⚠️  jq が無いため settings.json を自動更新できません。"
        echo "    以下を手動で settings.json に追記してください:"
        echo ""
        echo '  "statusLine": {'
        echo '    "type": "command",'
        echo "    \"command\": \"/bin/bash $SCRIPT_DST\","
        echo '    "padding": 0'
        echo '  }'
    fi
fi

echo ""
echo "🎉 インストール完了！"
echo "新しい Claude Code セッションを開くとステータスラインが反映されます。"
