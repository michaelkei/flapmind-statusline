#!/bin/bash
# flapmind-statusline — Claude Code 用カスタムステータスライン
# https://github.com/michaelkei/flapmind-statusline
# Model / Dir / Git / Cost / Context / Session(5h) / Weekly(7d) を表示

input=$(cat)

C_RESET='\033[0m'
C_BOLD='\033[1m'
C_HEAD='\033[1;38;5;208m'
C_LBL='\033[1;38;5;31m'
C_DIR='\033[38;5;31m'
C_GREEN='\033[38;5;28m'
C_YELLOW='\033[38;5;220m'
C_RED='\033[38;5;196m'
C_GRAY='\033[38;5;244m'
C_GIT_ADD='\033[38;5;34m'
C_GIT_DEL='\033[38;5;160m'
C_COST='\033[38;5;213m'

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
CW_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

TOK_IN=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
TOK_OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

MODEL_DISP="$MODEL"
if [ "$CW_SIZE" = "1000000" ] && [[ "$MODEL" != *"1M"* ]]; then
    MODEL_DISP="$MODEL (1M)"
fi

DIR_NAME=$(basename "$DIR")

BRANCH=""
if git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
fi

make_bar() {
    local pct=$1
    local width=${2:-20}
    local filled=$(awk "BEGIN{printf \"%d\", $pct * $width / 100}")
    [ "$filled" -gt "$width" ] && filled=$width
    [ "$filled" -lt 0 ] && filled=0
    local empty=$((width - filled))
    local color
    local pct_int=$(printf '%.0f' "$pct")
    if [ "$pct_int" -ge 90 ]; then color="$C_RED"
    elif [ "$pct_int" -ge 70 ]; then color="$C_YELLOW"
    else color="$C_GREEN"; fi
    local bar=""
    if [ "$filled" -gt 0 ]; then
        printf -v F "%${filled}s"
        bar="${color}${F// /█}${C_RESET}"
    fi
    if [ "$empty" -gt 0 ]; then
        printf -v E "%${empty}s"
        bar="${bar}${C_GRAY}${E// /░}${C_RESET}"
    fi
    printf '%b' "$bar"
}

format_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        awk "BEGIN{printf \"%.1fM\", $n/1000000}"
    elif [ "$n" -ge 1000 ]; then
        awk "BEGIN{printf \"%.1fK\", $n/1000}"
    else
        echo "$n"
    fi
}

format_reset() {
    local epoch=$1
    [ -z "$epoch" ] && return
    local now=$(date +%s)
    local diff=$((epoch - now))
    [ "$diff" -le 0 ] && echo "now" && return
    local d=$((diff / 86400))
    local h=$(((diff % 86400) / 3600))
    local m=$(((diff % 3600) / 60))
    if [ "$d" -gt 0 ]; then echo "${d}d${h}h"
    elif [ "$h" -gt 0 ]; then echo "${h}h${m}m"
    else echo "${m}m"; fi
}

# 行1: ヘッダ
LINE1="${C_HEAD}[${MODEL_DISP}]${C_RESET} | ${C_DIR}📁 ${DIR_NAME}${C_RESET}"
[ -n "$BRANCH" ] && LINE1="${LINE1} | 🌿 ${C_BOLD}${BRANCH}${C_RESET}"
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
    LINE1="${LINE1} | ${C_GIT_ADD}+${LINES_ADD}${C_RESET}/${C_GIT_DEL}-${LINES_DEL}${C_RESET}"
fi
COST_FMT=$(printf '%.3f' "$COST")
LINE1="${LINE1} | ${C_COST}\$${COST_FMT}${C_RESET}"
printf '%b\n' "$LINE1"

# 行2: Context
CTX_INT=$(printf '%.0f' "$CTX_PCT")
printf '%b\n' "${C_LBL}Context:${C_RESET} $(make_bar "$CTX_PCT" 20) ${C_BOLD}[${CTX_INT}%]${C_RESET}"

# 行3: Session（5h）
TOK_TOTAL=$((TOK_IN + TOK_OUT))
TOK_STR=$(format_tokens "$TOK_TOTAL")
if [ -n "$FIVE_H" ]; then
    FIVE_INT=$(printf '%.0f' "$FIVE_H")
    RESET_STR=$(format_reset "$FIVE_RESET")
    printf '%b\n' "${C_LBL}Session:${C_RESET} $(make_bar "$FIVE_H" 20) ${C_BOLD}[${FIVE_INT}%]${C_RESET} ${C_GRAY}↻ ${RESET_STR} · ${TOK_STR} tok${C_RESET}"
else
    printf '%b\n' "${C_LBL}Session:${C_RESET} ${C_GRAY}-- ${TOK_STR} tok${C_RESET}"
fi

# 行4: Weekly（7d）
if [ -n "$WEEK" ]; then
    WEEK_INT=$(printf '%.0f' "$WEEK")
    RESET_STR=$(format_reset "$WEEK_RESET")
    printf '%b\n' "${C_LBL}Weekly: ${C_RESET} $(make_bar "$WEEK" 20) ${C_BOLD}[${WEEK_INT}%]${C_RESET} ${C_GRAY}↻ ${RESET_STR}${C_RESET}"
else
    printf '%b\n' "${C_LBL}Weekly: ${C_RESET} ${C_GRAY}-- (使用量取得待ち)${C_RESET}"
fi
