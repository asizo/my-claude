# templates/ — 산출물 골격

작업 산출물의 **골격(skeleton)**. 이 디렉토리 파일은 전역 골격일 뿐 **라이브 상태가 아니다** — 실제 산출물은 프로젝트별 `tasks/`·`docs/`에 생성된다. 자동 라우팅 표에서 트리거되거나 사용자가 직접 요청할 때 사용한다.

> Claude Code는 이 디렉토리를 자동 스캔하지 않으므로 이 `README.md`는 런타임에 영향이 없다(문서 전용).

## 파일 목록

| 파일 | 용도 | 실제 산출물 경로 |
|---|---|---|
| `plan.md` | 작업 계획서 | 라이브: `tasks/todo.md` / 보관: `tasks/YYYYMMDD_todo_{요약}.md` |
| `bugfix.md` | 버그 리포트 | 기본 인라인 / 보관: `tasks/YYYYMMDD_bugfix_{요약}.md` |
| `sprint-contract.md` | 스프린트 범위 계약 | `tasks/todo.md` 상단 / 보관: `tasks/YYYYMMDD_sprint_{요약}.md` |
| `work-history.md` | 세션 핸드오프(`/compact`) | `docs/YYYYMMDDHHII_work_history.md` (불변) |
| `lessons.md` | 누적 교훈 로그 골격 | 라이브: 프로젝트별 `tasks/lessons.md` |

## 명명 규칙 (구분자 2원칙)

- **repo 구조 파일**(이 디렉토리): **kebab-case** (`work-history.md`, `sprint-contract.md`).
- **생성 산출물**(`docs/`·`tasks/`): **날짜-앞·언더스코어 snake_case** — `YYYYMMDD_{영문_제목}.md`, work_history는 `YYYYMMDDHHII_work_history.md`. 하이픈 미사용.

## 참고

- 라이브 상태 파일(`tasks/todo.md`·`tasks/lessons.md`)은 per-project이며, `templates/`의 동명 파일은 전역 골격일 뿐이다.
- 절차·규칙은 `rules/governance.md`(문서/세션)와 `rules/workflow.md`(Task Management) 참조.
