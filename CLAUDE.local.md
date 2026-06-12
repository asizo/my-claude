# CLAUDE.local.md — my-claude repo 전용 개발 지침

> 이 파일은 **이 repo(my-claude)에서 작업할 때만** 적용된다. `~/.claude/`로 심링크하지 않으며(전역 미적용), git에 커밋한다.
> 전역 규칙은 `CLAUDE.md`(→ `~/.claude/CLAUDE.md`로 심링크)와 `rules/*.md`를 따른다. 본 파일은 그 위에 **이 repo 고유의 작업 규칙**만 더한다.

---

## 이 repo의 정체성

- `my-claude/`는 **Claude Code 전역 설정의 소스(SoT)**다. 셋업 스크립트가 이 안의 파일을 `~/.claude/`로 **심링크**한다.
- 따라서 `~/.claude/CLAUDE.md`, `~/.claude/rules/*` 등을 편집한다는 것은 **이 repo의 원본을 편집**하는 것과 같다.
- `settings.json`의 `deny`가 `Edit/Write(~/.claude/**)`를 차단한다. **항상 이 repo의 소스 경로에서 직접 편집**한다(`~/.claude/**` 경로로 편집 금지 — deny에 걸린다).
- 심링크 대상이 **아닌** 파일: `CLAUDE.original.md`(원본 보존), `CLAUDE.local.md`(본 파일), `README.md`.

---

## 참고 매뉴얼 (repo 문서)

Claude Code 환경 구성·운영 매뉴얼은 repo 루트에 있다(README §15 색인). 관련 작업 시 참조:
- `claude-code-plugin-setup-guide.md` — 플러그인(ECC·claude-hud) 설치
- `claude-code-permission-modes.md` — 권한(승인) 모드
- `serena-claude-code-manual.md` — Serena 연동
- `devcontainer-guide.md` — devcontainer + Claude Code 통합 (유일하게 `~/.claude/`로 심링크, `rules/devcontainer.md`가 참조)

---

## 편집 시 불변 규칙

1. **파일 명명 — 구분자 2원칙**:
   - **repo 구조 파일**(`rules/`·`templates/`·`commands/`·`agents/`·`*.sh`): **kebab-case(하이픈)**. 예: `error-recovery.md`, `audit-log.sh`.
   - **생성 산출물**(`docs/`·`tasks/` 날짜 스탬프 문서): **날짜-앞·언더스코어 snake_case** — `YYYYMMDD_{영문_스네이크케이스_제목}.md` (예: `20250416_api_design.md`), work_history는 `YYYYMMDDHHII_work_history.md`. 하이픈 미사용.
2. **신규 `rules/<name>.md` 추가 시**: 반드시 `CLAUDE.md`의 **Auto-Loaded Rules 라우팅 표**에도 행을 추가한다(누락 시 새 규칙이 로드되지 않음).
3. **신규 루트 파일이 전역에 필요하면**: `README.md`의 **셋업 심링크 루프**와 **전수조사(무결성) 스크립트** 목록 양쪽에 파일명을 추가한다. 전역 미적용 파일(`CLAUDE.local.md` 등)은 추가하지 않는다.
4. **신규 훅 스크립트 추가 시**: `settings.json` 훅 등록 + `README.md` hooks 표 + 무결성 스크립트의 "훅↔스크립트 매칭" 목록에 반영한다.
5. **시크릿 금지**: 코드·로그·문서·`tasks/`에 토큰/키/비밀번호를 넣지 않는다. 훅 스크립트는 기록·출력 시 마스킹 sed를 적용한다.
6. **라이브 상태 파일은 프로젝트별**: `tasks/todo.md`, `tasks/lessons.md`는 per-project. `templates/`의 동명 파일은 전역 골격일 뿐 라이브 상태가 아니다.
7. **변경 이력 갱신**: 설정·규칙·스크립트를 바꾸면 `README.md` §14 변경 이력(Changelog)에 항목을 추가하고 상단 `버전`(SemVer)을 갱신한다.

---

## 변경 후 검증 (필수)

설정·규칙·스크립트를 바꾼 뒤 **반드시** `README.md` §12의 전수조사 스크립트를 실행한다. 최소 항목:

```bash
cd "$HOME/Documents/source/my-claude"   # 실제 소스 경로에 맞게 조정
jq empty settings.json && echo "settings.json OK"     # JSON 문법
for f in *.sh; do sh -n "$f" && echo "$f OK"; done    # shell 문법
# 라우팅 표 ↔ 실제 rules 일치 (문서용 README.md 제외)
diff <(grep -oE 'rules/[a-z-]+\.md' CLAUDE.md | sed 's|rules/||' | sort -u) <(ls rules/ | grep -v '^README\.md$' | sort) && echo "라우팅 일치"
# 마스킹 패턴 3중 동기화 (audit-log/sessionstart/precompact — 드리프트 시 시크릿 누출)
[ "$(for f in audit-log.sh sessionstart.sh precompact.sh; do grep '^mask=' "$f" | cksum; done | sort -u | wc -l | tr -d ' ')" = 1 ] && echo "mask 동기화 OK"
```

- 훅 스크립트는 **임시 디렉토리에서 샌드박스 실행**으로 동작·마스킹을 검증한 뒤 의존한다(프로덕션 경로 오염 금지).
- `settings.json` 변경은 **새 세션**을 시작해야 적용·검증된다.

---

## 커밋 규칙

- `rules/git-hygiene.md`(+ ECC 설치 시 `git-workflow` 스킬)의 Conventional Commits를 따른다(`feat`/`fix`/`docs`/`chore` 등).
- 커밋은 **사용자 명시 요청 시에만** 수행한다(전역 승인 게이트 적용).
- 포맷-only 변경과 동작 변경을 한 커밋에 섞지 않는다.
