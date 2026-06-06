# my-claude — Claude Code 글로벌 설정 & 사용 매뉴얼

Claude Code 글로벌 설정 모음. `~/.claude/`에 심링크로 연결하여 여러 컴퓨터에서 동일 환경을 유지한다.

- **버전**: `v0.4.0` (2026-06-06) — 전체 변경 이력은 문서 맨 아래 [§14 변경 이력](#14-변경-이력-changelog).
- **설계 철학**: 토큰은 한정 자원 → 정확도와 직결. 매 세션 로드는 얇게(`CLAUDE.md`), 상세 규칙은 **자동 라우팅**으로 필요할 때만 로드.
- **안전장치**: 승인 게이트(상시) · 권한 가드레일 · 시크릿 차단/마스킹 · 명령 감사 로그.
- **출처**: [kon6443/claude-config](https://github.com/kon6443/claude-config) 구조를 기반으로 재구성.
- **구성 내력**: 모놀리식 단일 `CLAUDE.md`(원본 → `CLAUDE.original.md`로 보존)를 `rules/` + `templates/` 구조로 분할하고, 훅·권한·커맨드·서브에이전트 인프라를 도입한 버전.

---

## 1. 디렉토리 구조

```
my-claude/
├── CLAUDE.md                 # 상시 로드 — 핵심 원칙 + 승인 게이트 + DoD(SSOT) + 커뮤니케이션 + 자동 라우팅 표 (~115줄)
├── CLAUDE.original.md        # 분할 전 원본(26KB) 보존 — 롤백/대조용. 심링크 대상 아님.
├── CLAUDE.local.md           # 이 repo 전용 개발 지침 — 커밋, 심링크 대상 아님(전역 미적용)
├── AGENTS.md                 # ECC(Everything Claude Code) 설치 환경용 추가 규칙 (조건부)
├── settings.json             # permissions, hooks, statusline, env
├── statusline-command.sh     # 하단 상태바
├── audit-log.sh              # PreToolUse hook — Bash 명령 감사(마스킹 기록)
├── check-secrets.sh          # UserPromptSubmit hook — 시크릿 패턴 차단
├── sessionstart.sh           # SessionStart hook — 활동 요약 + 위험 명령 + 로그 회전
├── precompact.sh             # PreCompact hook — compact 직전 work_history 스냅샷 자동 저장
├── devcontainer-guide.md     # devcontainer 생성 상세 가이드 (~/.claude/로 심링크)
├── README.md
├── rules/                    # 상황별 규칙 (CLAUDE.md 자동 라우팅으로 로드)
│   ├── workflow.md           #   계획·플랜·다중 단계 작업 + Task Management
│   ├── engineering.md        #   코드 작성·수정 베스트프랙티스
│   ├── error-recovery.md     #   버그·에러·디버그·회귀
│   ├── git-hygiene.md        #   커밋·PR·머지·리베이스
│   ├── context.md            #   컨텍스트 관리
│   ├── governance.md         #   문서/세션 관리 + 디렉토리 구조 + 프로젝트 초기화
│   ├── tooling.md            #   ECC 스킬/MCP/커맨드 (설치 환경 전용)
│   └── devcontainer.md       #   devcontainer 설정
├── templates/                # 산출물 골격 (자동 라우팅 또는 직접 호출)
│   ├── plan.md               #   작업 계획서
│   ├── bugfix.md             #   버그 리포트
│   ├── sprint-contract.md    #   스프린트 범위 계약
│   ├── work-history.md       #   세션 핸드오프(/compact)
│   └── lessons.md            #   누적 교훈 로그 골격 (라이브: 프로젝트별 tasks/lessons.md)
├── commands/                 # 슬래시 커맨드
│   ├── review.md             #   /review — 플로우 기반 QA 리뷰
│   ├── pr-desc.md            #   /pr-desc — PR 제목·설명 자동 생성
│   └── tasks-dashboard.md    #   /tasks-dashboard — 태스크 진행 대시보드
└── agents/                   # 서브에이전트 (읽기 전용 조사용)
    ├── codebase-investigator.md
    ├── cross-project-researcher.md
    ├── git-history-researcher.md
    └── log-analyzer.md
```

---

## 2. 자동 라우팅 — 핵심 동작 원리

매 세션 자동 로드되는 것은 **`CLAUDE.md` 하나뿐**이다. `rules/*.md`와 `templates/*.md`는 **명시적으로 Read해야** 적용된다.

`CLAUDE.md` 안의 **Auto-Loaded Rules 표**가 트리거 단어/작업 성격을 파일에 매핑하며, AI는 작업 시작 전에 그 파일을 즉시 Read한다.

| 트리거 (요청 키워드 / 작업 성격) | 즉시 로드 |
|---|---|
| 코드 작성·수정·구현·리팩터링, API/타입/테스트 변경 | `rules/engineering.md` |
| 버그·에러·디버그·회귀·"안 됨"·"이상해" | `rules/error-recovery.md` (+ 리포트 작성 시 `templates/bugfix.md`) |
| 커밋·PR·머지·리베이스·태그·브랜치 정리 | `rules/git-hygiene.md` |
| 계획·플랜·설계·마이그레이션·3+ 단계 작업 | `rules/workflow.md` (+ `templates/plan.md`) |
| 컨텍스트 비대화·대량 검색·다중 파일 읽기 | `rules/context.md` |
| 문서 작성·산출물 저장·`/compact`·세션 재개·프로젝트 초기화 | `rules/governance.md` (+ `templates/work-history.md`) |
| 스킬·MCP·커맨드·서브에이전트 (ECC 설치 환경) | `rules/tooling.md` |
| `.devcontainer/devcontainer.json` 생성·수정 | `rules/devcontainer.md` |

- **장점**: 매 세션 자동 로드 토큰 절감(원본 26KB → 상시 7KB, 약 74%↓) + 상황별 정밀 적용.
- **면제**: 단일 한 줄 수정, 단순 정보 조회, 1회성 명령은 라우팅 면제.
- **다중 매칭**: 둘 이상 매칭되면 모두 로드 (예: 버그 수정 코드 작성 → engineering + error-recovery).
- **주의**: 신규 `rules/<name>.md` 추가 시 **반드시** `CLAUDE.md` 라우팅 표에도 행을 추가한다. 누락 시 새 규칙이 적용되지 않는다.

---

## 3. 상시 적용 규칙 (`CLAUDE.md`에 인라인)

라우팅으로 분리하지 않고 항상 적용하는 것:

| 섹션 | 내용 |
|---|---|
| Language & Response Style | 한국어 응답, 코드/경로/명령/에러는 원문 유지, 전문적·간결한 톤 |
| Operating Principles | correctness over cleverness, smallest change, prove it works 등 (비협상) |
| **Human-in-the-loop 승인 게이트** | 돈 이동·외부 메시지·데이터 삭제·**모든 DB 쓰기**·배포·법적/의료 영향 전 **사람 승인 필수** |
| Definition of Done (SSOT) | "작업 완료"의 단일 정의. 모든 rules가 이 정의를 참조 |
| Communication Guidelines | 결과 우선, 막혔을 때만 1개 질문, 검증 스토리 필수 |

> **설계 결정**: 승인 게이트는 누락 시 사고로 직결되므로 의도적으로 상시(CLAUDE.md)에 둔다. 라우팅 미적용 위험을 피한다.

---

## 4. 슬래시 커맨드 (`commands/`)

채팅창에 입력해 미리 정의된 워크플로우를 실행한다.

| 커맨드 | 용도 |
|---|---|
| `/review` | 변경 코드에 대한 플로우 기반 QA 리뷰. grep 전수 추적 · 대칭 분기 검증 · Ripple Check · 실행 검증(추측 금지) |
| `/pr-desc` | 커밋 diff 기반 PR 제목·본문 한국어 자동 생성 (추측 금지, 민감정보 비노출) |
| `/tasks-dashboard` | 태스크 파일을 코드 실제 상태와 대조해 진행 대시보드 생성. 동기화는 항목별 사용자 승인 |

사용 예: `/tasks-dashboard all`, `/pr-desc`, `/review`

---

## 5. 서브에이전트 (`agents/`)

메인 컨텍스트를 보호하기 위해 넓은 탐색·조사를 위임하고 **요약 결과만** 받는다. 모두 **읽기 전용**(파일 수정·커밋 안 함), 민감정보 마스킹.

| 에이전트 | 용도 |
|---|---|
| `codebase-investigator` | 다수 파일/모듈 걸친 로직·호출 체인 추적 → 구조화 리포트 + Red Flag |
| `cross-project-researcher` | 연관 프로젝트(프론트↔백) 코드 대조로 스펙 불일치 사전 방지 |
| `git-history-researcher` | 특정 파일/함수의 변경 이력·버그 도입 시점 역추적 |
| `log-analyzer` | 대용량 로그에서 에러 시그널 추출 · 근본 원인 가설 |

---

## 6. hooks

| 이벤트 | 스크립트 | 동작 |
|---|---|---|
| `SessionStart` | `sessionstart.sh` | 직전 활동 요약(cwd 매칭·노이즈 필터·시크릿 마스킹·24h 윈도) + 위험 명령 강조 + audit.log 일 1회 gzip 회전 + 1MB 초과 시 즉시 trim + CLAUDE.md 미존재 시 1회 안내. **stdout 출력만 — 컨텍스트 토큰 0** |
| `UserPromptSubmit` | `check-secrets.sh` | 프롬프트에 시크릿 패턴 발견 시 **모델 전송 전 차단**(exit 2) |
| `PreToolUse(Bash)` | `audit-log.sh` | 모든 Bash 명령을 `~/.claude/audit.log`에 기록. **기록 시점에 시크릿 마스킹**(디스크 평문 저장 방지) |
| `PreCompact` | `precompact.sh` | compact(수동 `/compact`·자동) 직전 `docs/YYYYMMDDHHII_work_history.md` 스냅샷 자동 저장(git 변경 파일 + 최근 명령·요청, 마스킹). **자동 compact 시에도 핸드오프 누락 방지.** 최근 3분 내 work_history 존재 시 생략(중복 방지) |
| `Notification` | (인라인) | macOS `osascript` 또는 Linux `notify-send` 알림 |

### audit.log 회전 정책

| 항목 | 값 |
|---|---|
| 회전 주기 | 일 1회 (자정 넘어 첫 SessionStart) |
| 회전 방식 | gzip 압축 → `~/.claude/backups/audit.log.YYYY-MM-DD.gz` |
| 보관 기간 | 30일 (이후 자동 삭제) |
| 안전망 | 1MB 초과 시 즉시 `tail -10000`로 trim |
| 시크릿 마스킹 | 기록 시점(audit-log.sh) + stdout 표시 시점(sessionstart.sh) 양쪽 |
| 외부 의존성 | 없음 (launchd/cron/logrotate 불필요) |

---

## 7. permissions

| 구분 | 동작 | 예시 |
|---|---|---|
| `allow` | 자동 실행 | git 읽기 명령, 패키지 매니저, 일반 유틸 (`grep`, `find`, `jq`, `gh`, `cat`/`head`/`tail`/`sed`/`awk`) |
| `ask` | 매번 확인 | `git push/commit/merge/rebase/stash/tag`, `docker`, `rm`, **`curl`/`python`/`python3`/`node`** |
| `deny` | 무조건 차단 | `rm -rf /` 변형, `git push --force/-f`, `git reset --hard`, `curl\|bash` 변형, ssh/env/credentials 읽기(다중 명령), `Edit/Write(~/.claude/**)`, `npm publish` 등 |

### 권한 설계 의도와 한계 (중요)

- **임의 실행 차단**: `curl`/`python`/`node`는 `allow`가 아니라 `ask`에 둔다 → 자동 실행되지 않고 매번 확인. 파일 유출·임의 코드 실행 경로를 차단.
- **민감파일 다중 명령 차단**: `~/.ssh/*`, `*/.env*`, `*credentials*`를 `cat/cp/scp/base64`뿐 아니라 `head/tail/sed/awk/grep`까지 deny.
- **자기 보호**: `Edit/Write(~/.claude/**)`, `Edit/Write(~/dotfiles/**)` 차단으로 글로벌 설정을 보호.
- **⚠️ 한계**: 권한 매칭은 prefix/glob 기반이라 **절대경로**(`cat /Users/me/.ssh/id_rsa`)나 경로 조작은 막지 못한다. 권한은 **"실수 방지"** 수준이며, 악의적 우회 차단이 목적이라면 컨테이너/샌드박스가 필요하다.

---

## 8. AGENTS.md (ECC) — 조건부 적용

`AGENTS.md`는 ECC(Everything Claude Code) 패키지가 **설치된 환경에서만** 적용되는 추가 규칙이다.

- 글로벌 `CLAUDE.md`와 충돌 시 **`CLAUDE.md`가 우선**.
- "80% 커버리지 / TDD 필수", "Agent-First 능동 위임"은 **기본 규칙이 아니라** 프로젝트가 명시 채택할 때만 적용하는 강화 옵션. 기본은 `rules/engineering.md`의 실용주의 테스트와 `rules/workflow.md`의 위임 절제를 따른다.

---

## 9. 환경 변수 (`settings.json` › `env`)

| 키 | 값 | 설명 |
|---|---|---|
| `CLAUDE_CODE_NO_FLICKER` | `1` | 화면 깜빡임 방지 |
| `BASH_DEFAULT_TIMEOUT_MS` | `120000` | Bash 기본 timeout (2분) |
| `BASH_MAX_TIMEOUT_MS` | `600000` | Bash 최대 timeout (10분) |
| `MAX_MCP_OUTPUT_TOKENS` | `25000` | MCP 출력 토큰 상한 |

그 외: `language: Korean`, `showTurnDuration: true`, `attribution`(commit/pr 빈 문자열 → 커밋·PR 서명 비활성).

---

## 10. 셋업 (멱등 — 재실행 안전)

`my-claude/`의 파일을 `~/.claude/`에 심링크한다. 기존 파일은 타임스탬프 백업 후 교체한다.

```bash
# 소스 경로 (현재 위치에 맞게 조정)
SRC="$HOME/Documents/source/claude-config/my-claude"

mkdir -p ~/.claude
TS=$(date +%Y%m%d_%H%M%S)
for f in CLAUDE.md AGENTS.md settings.json statusline-command.sh audit-log.sh check-secrets.sh sessionstart.sh precompact.sh devcontainer-guide.md agents commands rules templates; do
  src="$SRC/$f"
  dst="$HOME/.claude/$f"
  [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && { echo "✓ $f: skip"; continue; }
  ([ -e "$dst" ] || [ -L "$dst" ]) && mv "$dst" "$dst.bak.$TS"
  ln -s "$src" "$dst"
  echo "✓ $f: 연결됨"
done
chmod +x "$SRC"/*.sh
```

> `CLAUDE.original.md`는 보존용이므로 심링크 대상에서 제외한다.
> 셋업 후 **새 세션**을 시작해 SessionStart 훅 동작과 statusline을 확인한다.

---

## 11. 설정 변경 방법

`settings.json`의 `deny`가 `Edit/Write(~/.claude/**)`를 차단하므로, **심링크 타깃을 직접 수정할 수 없다.** 대신:

1. **소스(`my-claude/`)에서 직접 수정** — 심링크이므로 즉시 반영된다. (소스 경로는 `~/.claude/**`에 매칭되지 않아 deny 우회 아님)
2. `settings.json` 변경 시: 새 세션을 시작해 동작을 검증한다.
3. 큰 변경 전: `cp settings.json settings.json.bak.$(date +%Y%m%d-%H%M%S)`로 백업.

---

## 12. 운영 팁

### audit.log 조회
```bash
tail -50 ~/.claude/audit.log                # 최근 50개
grep "git push" ~/.claude/audit.log         # 키워드 검색
ls -lh ~/.claude/backups/audit.log.*.gz     # 회전 백업 목록
zcat ~/.claude/backups/audit.log.2026-04-28.gz | grep ...   # 과거 로그 검색
```

### 라우팅 디버그
```bash
# 라우팅 표가 모든 분할 파일을 가리키는지
grep -E 'rules/|templates/' ~/.claude/CLAUDE.md

# 신규 rules 파일 추가 후 라우팅 표 갱신 누락 확인
diff <(ls ~/.claude/rules/*.md | xargs -n1 basename) \
     <(grep -oE 'rules/[a-z-]+\.md' ~/.claude/CLAUDE.md | sort -u | xargs -n1 basename)
```

### 전수조사 스크립트 (변경 후 무결성 검증)

설정을 변경할 때마다 실행해 구성·라우팅·문법·권한·SSOT 무결성을 한 번에 확인한다.

```bash
cd "$HOME/Documents/source/claude-config/my-claude"   # 소스 경로에 맞게 조정

echo "═══ 1. 파일 존재 + 크기 ═══"
for f in CLAUDE.md AGENTS.md settings.json \
         rules/workflow.md rules/engineering.md rules/error-recovery.md rules/git-hygiene.md \
         rules/context.md rules/governance.md rules/tooling.md rules/devcontainer.md \
         templates/plan.md templates/bugfix.md templates/sprint-contract.md templates/work-history.md templates/lessons.md \
         devcontainer-guide.md sessionstart.sh precompact.sh audit-log.sh check-secrets.sh statusline-command.sh; do
  [ -e "$f" ] && printf "  OK   %-30s %5s bytes\n" "$f" "$(wc -c<"$f"|tr -d ' ')" || printf "  MISS %s\n" "$f"
done

echo "═══ 2. JSON / shell 문법 ═══"
jq empty settings.json && echo "  settings.json OK"
for f in *.sh; do sh -n "$f" && echo "  $f OK"; done

echo "═══ 3. 라우팅 표 ↔ 실제 rules 일치 ═══"
diff <(grep -oE 'rules/[a-z-]+\.md' CLAUDE.md | sed 's|rules/||' | sort -u) \
     <(ls rules/ | sort) && echo "  ✅ 완전 일치"

echo "═══ 4. DoD SSOT (정의 1곳) ═══"
grep -l "^## Definition of Done" CLAUDE.md rules/*.md 2>/dev/null

echo "═══ 5. 훅 ↔ 스크립트 매칭 ═══"
for s in sessionstart.sh precompact.sh audit-log.sh check-secrets.sh statusline-command.sh; do
  grep -q "$s" settings.json && [ -f "$s" ] && echo "  OK $s" || echo "  FAIL $s"
done

echo "═══ 6. 심링크 상태 ═══"
for f in CLAUDE.md AGENTS.md settings.json statusline-command.sh audit-log.sh check-secrets.sh sessionstart.sh precompact.sh devcontainer-guide.md agents commands rules templates; do
  link="$HOME/.claude/$f"
  if [ -L "$link" ] && [ -e "$link" ]; then echo "  OK $f"
  elif [ -L "$link" ]; then echo "  BROKEN $f"
  elif [ -e "$link" ]; then echo "  FILE $f (not a symlink)"
  else echo "  MISS $f"; fi
done
```

---

## 13. 원본 보존 / 롤백

- `CLAUDE.original.md` = 분할 전 모놀리식 원본(26KB). 내용 손실 없이 보존되어 있어, 분할 구조가 맞지 않으면 이 파일로 되돌릴 수 있다.
- 분할본과 원본의 내용 차이를 확인하려면: 각 `rules/*.md`의 `> 출처:` 헤더가 원본의 어느 섹션에서 왔는지 명시한다.

---

## 14. 변경 이력 (Changelog)

> [Keep a Changelog](https://keepachangelog.com) 형식 · [SemVer](https://semver.org). **설정·규칙·스크립트를 변경하면 이 섹션에 항목을 추가하고 상단 `버전`을 갱신한다.**
> 출처: [kon6443/claude-config](https://github.com/kon6443/claude-config) 구조를 기반으로 재구성. 구성 내력은 모놀리식 단일 `CLAUDE.md`(원본 → `CLAUDE.original.md` 보존)를 `rules/` + `templates/`로 분할하고 훅·권한·커맨드·서브에이전트 인프라를 도입한 것이다.

### v0.4.0 — 2026-06-06
- 템플릿 산출물 저장 경로 명시: `plan` → `tasks/todo.md`(라이브)/보관 시 `tasks/YYYYMMDD_todo_{요약}.md`, `bugfix` → 인라인 기본/`tasks/YYYYMMDD_bugfix_{요약}.md`, `sprint-contract` → `tasks/todo.md` 상단/`tasks/YYYYMMDD_sprint_{요약}.md`, `work-history` → `docs/YYYYMMDDHHII_work_history.md`.
- **구분자 2원칙 명문화** (governance): repo 구조 파일 = kebab-case(하이픈), 생성 산출물 = 날짜-앞·언더스코어 snake_case.
- README 버전 정보 + 변경 이력(Changelog) 섹션 도입.

### v0.3.0 — 2026-06-06
- 파일 명명 규칙을 **날짜-앞**(`YYYYMMDD_{제목}.md`)으로 전면 전환.
- `CLAUDE.local.md`(이 repo 전용 개발 지침), `devcontainer-guide.md`(devcontainer 상세 가이드), `templates/lessons.md`(누적 교훈 골격) 추가.

### v0.2.0 — 2026-06-06
- `PreCompact` 훅(`precompact.sh`) 도입 — compact(수동·자동) 직전 work_history 스냅샷 자동 저장으로 **자동 compact 핸드오프 누락 방지**.
- 출처(kon6443/claude-config) 표기.

### v0.1.0 — 2026-06-06
- 초기 구성: 모놀리식 `CLAUDE.md`를 **상시 로드 핵심 + 자동 라우팅 `rules/*` + `templates/*`** 로 분할(원본 `CLAUDE.original.md` 보존).
- 훅(SessionStart·PreToolUse 감사·UserPromptSubmit 시크릿 차단)·권한 가드레일·슬래시 커맨드·서브에이전트·README 사용 매뉴얼 도입.
