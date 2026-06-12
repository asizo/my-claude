# rules/ — 자동 라우팅 규칙

상황별 상세 규칙. 매 세션 자동 로드되는 건 `CLAUDE.md` 하나뿐이고, 이 디렉토리의 규칙은 **명시적으로 `Read`해야** 적용된다. `CLAUDE.md`의 **Auto-Loaded Rules 라우팅 표**가 트리거 단어/작업 성격을 각 파일에 매핑하며, 작업 시작 전 해당 파일을 즉시 로드한다.

> Claude Code는 이 디렉토리를 자동 스캔하지 않는다(명령/에이전트와 달리 `Read` 도구로만 로드). 따라서 이 `README.md`는 런타임에 영향이 없다. 단, 무결성 스크립트의 `라우팅 표 ↔ 실제 rules 일치` diff는 `README.md`를 제외하도록 처리돼 있다(README §12).

## 파일 목록

| 파일 | 트리거 | 출처(원본 CLAUDE.md 섹션) |
|---|---|---|
| `engineering.md` | 코드 작성·수정·구현·리팩터링, API/타입/테스트 변경 | Engineering Best Practices |
| `error-recovery.md` | 버그·에러·디버그·회귀·테스트 실패 | Error Handling and Recovery Patterns |
| `git-hygiene.md` | 커밋·PR·머지·리베이스·태그·브랜치 정리 | Git and Change Hygiene |
| `workflow.md` | 계획·설계·마이그레이션·3+ 단계 작업·다중 파일 변경 | Workflow Orchestration + Task Management |
| `context.md` | 컨텍스트 비대화·대량 검색·다중 파일 읽기 | Context Management Strategies |
| `governance.md` | 문서 작성·산출물 저장·`/compact`·세션 재개·초기화 | Directory & File Structure + Project Initialization + Document & Session Management |
| `tooling.md` | 스킬·MCP·커맨드·서브에이전트 (ECC 설치 환경 전용) | Tooling Integration (Everything Claude Code) |
| `devcontainer.md` | `.devcontainer/devcontainer.json` 생성·수정 | DevContainer Setup |

## 불변 규칙

1. **신규 `rules/<name>.md` 추가 시 반드시 `CLAUDE.md`의 라우팅 표에도 행을 추가**한다 — 누락 시 새 규칙이 로드되지 않는다.
2. 파일명은 **kebab-case**.
3. 각 파일 상단에 `> 자동 라우팅:`(트리거)과 `> 출처:`(원본 섹션) 헤더를 둔다.
4. **SSOT 중복 금지**: DoD(Definition of Done) 등 단일 정의는 `CLAUDE.md`만 보유하고, rules는 참조만 한다.
