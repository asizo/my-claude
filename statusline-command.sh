#!/bin/sh
# =============================================================================
# Claude Code status line — 미니멀 이모지 스타일
# -----------------------------------------------------------------------------
# 역할:
#   settings.json의 `statusLine.command`에 등록되어, Claude Code가 화면 하단
#   상태줄을 그릴 때마다 호출하는 스크립트. 한 줄짜리 상태 텍스트를 stdout으로
#   출력하면 그 문자열이 그대로 상태줄에 표시된다.
#
# 입력 (stdin):
#   Claude Code가 세션 상태를 담은 JSON 한 덩어리를 표준입력으로 넘긴다.
#   주요 필드 (버전에 따라 일부는 없을 수 있어 jq `// empty`로 방어):
#     .workspace.current_dir / .cwd        현재 작업 디렉터리
#     .model.display_name                  모델 표시 이름
#     .context_window.remaining_percentage 컨텍스트 잔여 비율(%)
#     .rate_limits.five_hour.*             5시간 롤링 사용량/리셋 시각(Pro/Max)
#     .cost.total_lines_added / removed    세션 누적 추가/삭제 라인 수
#
# 출력 (stdout):
#   "📂 dir · ⎇ branch · 🧠 model · ⏳ ctx% · 🔋 session% · ⏱ reset · 📊 +/-"
#   각 세그먼트는 해당 데이터가 있을 때만 ' · '로 이어 붙인다.
#
# 의존성: jq, git, date (POSIX sh). 빠르게 끝나야 하므로 무거운 호출 금지.
# 주의: 이 파일은 저장소 원본이며 ~/.claude/statusline-command.sh로 배포된다.
# =============================================================================
input=$(cat)

# --- 입력 JSON 파싱 (필드가 없으면 빈 문자열로 안전 처리) ---
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
# 개선: 백분율이 소수(float)로 와도 POSIX 산술이 깨지지 않도록 jq에서 floor 적용
remaining=$(printf '%s' "$input" | jq -r '((.context_window.remaining_percentage // (.context_window.used_percentage | if . then (100 - .) else null end)) // empty) | if type == "number" then floor else . end')
rate_5h_used=$(printf '%s' "$input" | jq -r 'if .rate_limits.five_hour.used_percentage != null then (.rate_limits.five_hour.used_percentage | floor) else empty end')
resets_at=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

lines_added=$(printf '%s' "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(printf '%s' "$input" | jq -r '.cost.total_lines_removed // empty')

dir=$(basename "$cwd")

# Git branch
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# 5h session reset countdown (resets_at은 unix epoch seconds)
# 방어: epoch가 아닌 형식(ISO 8601 등)이 오면 산술 에러로 상태줄 전체가 깨지므로 숫자만 허용
case "$resets_at" in ''|*[!0-9]*) resets_at="" ;; esac
session_left=""
if [ -n "$resets_at" ]; then
  now=$(date +%s)
  diff=$((resets_at - now))
  if [ "$diff" -gt 0 ]; then
    hr=$((diff / 3600))
    min=$(((diff % 3600) / 60))
    if [ "$hr" -gt 0 ]; then
      session_left="${hr}h${min}m"
    else
      session_left="${min}m"
    fi
  fi
fi


# Format lines changed
lines=""
if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
  added="${lines_added:-0}"
  removed="${lines_removed:-0}"
  lines="+${added}/-${removed}"
fi

# --- 출력 조립 ---
# 이모지 범례: 📂 디렉터리 · ⎇ git 브랜치 · 🧠 모델 · ⏳ 컨텍스트 잔여 ·
#             🔋 5h 세션 잔여 · ⏱ 세션 리셋까지 남은 시간 · 📊 변경 라인 수
# 항상 표시되는 기준 세그먼트(디렉터리)로 시작하고, 이후 값이 있는 것만 덧붙인다.
parts="📂 ${dir}"

if [ -n "$git_branch" ]; then
  parts="${parts} · ⎇ ${git_branch}"
fi

if [ -n "$model" ]; then
  parts="${parts} · 🧠 ${model}"
fi

# Context window remaining
if [ -n "$remaining" ]; then
  parts="${parts} · ⏳ ${remaining}%"
else
  parts="${parts} · ⏳ --%"
fi

# Session rate limit (5h rolling) - Pro/Max only
if [ -n "$rate_5h_used" ]; then
  rate_5h_remain=$((100 - rate_5h_used))
  parts="${parts} · 🔋 session ${rate_5h_remain}%"
fi


# 5h session reset countdown
if [ -n "$session_left" ]; then
  parts="${parts} · ⏱ ${session_left}"
fi

if [ -n "$lines" ]; then
  parts="${parts} · 📊 ${lines}"
fi

printf "%s" "$parts"
