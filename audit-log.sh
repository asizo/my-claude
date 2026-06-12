#!/bin/sh
# Bash 명령어 감사 로그 — Claude Code PreToolUse hook 전용
# 입력: hook payload (JSON, stdin)
# 출력: ~/.claude/audit.log 에 1줄 추가
#
# 형식: [YYYY-MM-DD HH:MM:SS] [cwd] command
#
# 개선: 기록 시점에 시크릿 패턴을 마스킹한다 (디스크 평문 저장 방지).
#       sessionstart.sh의 stdout 마스킹과 동일 패턴을 사용해 일관성 유지.
input=$(cat)

ts=$(date '+%Y-%m-%d %H:%M:%S')
cwd=$(printf '%s' "$input" | jq -r '.cwd // "?"' 2>/dev/null)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

[ -z "$cmd" ] && exit 0

# 시크릿 마스킹 (토큰·키·인라인 자격증명이 평문으로 적히는 것을 방지)
mask='s#://[^:@/[:space:]]+:[^@/[:space:]]+@#://[REDACTED]@#g; s/(authorization[[:space:]]*:[[:space:]]*)(bearer[[:space:]]+|basic[[:space:]]+|token[[:space:]]+)?[A-Za-z0-9._~+\/=-]{8,}/\1\2[REDACTED]/gI; s/(bearer[[:space:]]+)[A-Za-z0-9._~+\/=-]{8,}/\1[REDACTED]/gI; s/(token|password|passwd|secret|api[_-]?key)[^[:space:]]*/[REDACTED]/gI; s/(sk-[A-Za-z0-9_-]{8,}|sk_(live|test)_[A-Za-z0-9]{8,}|ghp_[A-Za-z0-9]{8,}|gho_[A-Za-z0-9]{8,}|ghs_[A-Za-z0-9]{8,}|github_pat_[A-Za-z0-9_]{8,}|AKIA[0-9A-Z]{8,}|AIza[0-9A-Za-z_-]{20,}|xox[baprs]-[0-9A-Za-z-]{8,}|eyJ[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{4,})/[REDACTED]/g'
cmd=$(printf '%s' "$cmd" | sed -E "$mask" 2>/dev/null || printf '%s' "$cmd")

umask 077
echo "[$ts] [$cwd] $cmd" >> "$HOME/.claude/audit.log"
chmod 600 "$HOME/.claude/audit.log" 2>/dev/null || true

# hook은 항상 정상 종료 (실패해도 본 작업 막지 않음)
exit 0
