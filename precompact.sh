#!/bin/sh
# Claude Code PreCompact hook
#
# 동작: compact(수동 /compact · 자동) 직전, 세션 핸드오프 스냅샷을
#       프로젝트 docs/work_history_YYYYMMDDHHII.md 로 자동 저장한다.
#  - 자동 compact 시에도 핸드오프 누락을 방지 (governance.md work_history 규약 보강용 안전망)
#  - git 작업 트리 변경 파일 + audit.log 최근 명령(마스킹·노이즈 제외) + 최근 사용자 요청을 기계 수집
#  - 모델이 직접 작성한 핸드오프가 더 정확함 → 본 파일은 스냅샷이며 헤더에 (auto) 표시, 다음 세션에서 보강
#
# stdin: { session_id, transcript_path, cwd, hook_event_name:"PreCompact", trigger:"manual"|"auto", custom_instructions }
# 출력: stdout — 사용자 화면에만 표시. 항상 exit 0 (compact 을 차단하지 않음).
# timeout: settings.json 에서 설정

set -eu

input=$(cat 2>/dev/null || true)

cwd=""
trigger=""
transcript=""
if command -v jq >/dev/null 2>&1 && [ -n "$input" ]; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
  trigger=$(printf '%s' "$input" | jq -r '.trigger // empty' 2>/dev/null || true)
  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)
fi
[ -z "$cwd" ] && cwd="$PWD"
[ -z "$trigger" ] && trigger="unknown"

# 프로젝트 컨텍스트가 아니면(git 레포도 아니고 docs/ 도 없음) 스킵 — 임의 디렉토리 오염 방지
is_repo=0
git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1 && is_repo=1
if [ "$is_repo" -ne 1 ] && [ ! -d "$cwd/docs" ]; then
  exit 0
fi

docs="$cwd/docs"
mkdir -p "$docs" 2>/dev/null || true

# 최근 3분 내 작성된 work_history 가 있으면 모델이 직접 작성한 것으로 보고 스냅샷 생략 (중복 방지)
existing=$(find "$docs" -maxdepth 1 -name 'work_history_*.md' -mmin -3 2>/dev/null | head -1 || true)
if [ -n "$existing" ]; then
  printf 'PreCompact: 최근 work_history 존재 → 스냅샷 생략 (%s)\n' "$(basename "$existing")"
  exit 0
fi

ts=$(date +%Y%m%d%H%M)
out="$docs/work_history_${ts}.md"

# 시크릿 마스킹 (sessionstart.sh 와 동일 표현식)
mask='s/(token|password|secret|api[_-]?key|authorization|bearer)[^[:space:]]*/[REDACTED]/gI; s/(sk-[A-Za-z0-9_-]{8,}|ghp_[A-Za-z0-9]{8,}|gho_[A-Za-z0-9]{8,}|ghs_[A-Za-z0-9]{8,}|github_pat_[A-Za-z0-9_]{8,}|AKIA[0-9A-Z]{8,}|xox[baprs]-[0-9A-Za-z-]{8,})/[REDACTED]/g'

# (1) 작업 트리 변경 파일
changed=""
if [ "$is_repo" -eq 1 ]; then
  changed=$(git -C "$cwd" status --porcelain 2>/dev/null | head -50 | sed 's/^/  /' || true)
fi
[ -z "$changed" ] && changed="  (변경 없음)"

# (2) audit.log 에서 이 cwd 최근 명령 (노이즈 제외 · 마스킹 · 15건)
log="$HOME/.claude/audit.log"
cmds=""
if [ -f "$log" ]; then
  cmds=$(tail -800 "$log" 2>/dev/null \
    | grep -F "[$cwd]" 2>/dev/null \
    | grep -vE '\] git (status|diff|log|branch|show|fetch)( |$)|\] (ls|cat|head|tail|echo|pwd|date|wc|jq) ' \
    | sed -E "$mask" \
    | tail -15 | sed 's/^/  /' || true)
fi
[ -z "$cmds" ] && cmds="  (기록 없음)"

# (3) transcript 에서 최근 사용자 요청 (best-effort · 실패 시 placeholder)
goals=""
if [ -n "$transcript" ] && [ -f "$transcript" ] && command -v jq >/dev/null 2>&1; then
  goals=$(jq -r 'select(.type=="user") | .message.content as $c
      | if ($c|type)=="string" then $c else ($c[]? | select(.type=="text") | .text) end' \
      "$transcript" 2>/dev/null \
    | grep -v '^[[:space:]]*$' \
    | sed -E "$mask" \
    | tail -8 | sed 's/^/  - /' || true)
fi
[ -z "$goals" ] && goals="  - (자동 추출 실패 — 다음 세션에서 직접 확인)"

# work_history 작성 (templates/work-history.md 구조 기반, 자동 스냅샷 표기)
{
  printf '# Work History (auto-snapshot)\n\n'
  printf '> **자동 생성 스냅샷** — PreCompact 훅이 compact(trigger=%s) 직전 기계 수집한 핸드오프.\n' "$trigger"
  printf '> 모델이 직접 작성한 핸드오프가 더 정확하다. 다음 세션에서 검토 후 보강할 것.\n'
  printf '> 생성 시각: %s · cwd: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$cwd"
  printf -- '---\n\n'
  printf -- '- **Goal and background** (최근 사용자 요청 추출):\n'
  printf '%s\n' "$goals"
  printf -- '- **Completed tasks / changed files** (git 작업 트리):\n'
  printf '%s\n' "$changed"
  printf -- '- **Recent commands** (이 cwd · 마스킹 · 노이즈 제외):\n'
  printf '%s\n' "$cmds"
  printf -- '- **Work in progress:** (검토 필요)\n'
  printf -- '- **Incomplete items and reasons:** (검토 필요)\n'
  printf -- '- **Key decisions and rationale:** (검토 필요)\n'
  printf -- '- **Constraints and warnings for next agent:** (검토 필요)\n'
  printf -- '- **Recommended next actions:** (검토 필요)\n'
  printf -- '- **Pending feature list:** (검토 필요)\n'
} > "$out" 2>/dev/null || true

if [ -f "$out" ]; then
  printf 'PreCompact: 핸드오프 스냅샷 저장 → %s (trigger=%s)\n' "$out" "$trigger"
fi

exit 0
