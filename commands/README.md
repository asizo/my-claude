# commands/ — 슬래시 커맨드

채팅창에 `/<파일명>`을 입력해 실행하는 미리 정의된 워크플로우. Claude Code가 `~/.claude/commands/*.md`를 스캔해 **파일명(확장자 제외)을 커맨드 이름**으로 등록한다(`review.md` → `/review`).

> ⚠️ **주의**: Claude Code가 `README.md`를 커맨드 스캔에서 제외하는지는 공식 문서에 명시돼 있지 않다. 이 파일이 `/README`(또는 `/readme`)로 슬래시 메뉴에 보이면, 본 파일을 삭제하거나 repo 루트 `README.md` §4로 통합한다.

## 파일 목록

| 커맨드 | 파일 | 용도 |
|---|---|---|
| `/review` | `review.md` | 변경 코드 플로우 기반 QA 리뷰. grep 전수 추적 · 대칭 분기 검증 · Ripple Check · 실행 검증(추측 금지) |
| `/pr-desc` | `pr-desc.md` | 커밋 diff 기반 PR 제목·본문 한국어 자동 생성(추측 금지, 민감정보 비노출) |
| `/tasks-dashboard` | `tasks-dashboard.md` | 태스크 파일을 코드 실제 상태와 대조해 진행 대시보드 생성. 동기화는 항목별 사용자 승인 |
| `/worktree-agent` | `worktree-agent.md` | git worktree 격리(`isolation: 'worktree'`) 적용 판단·머지 절차 가이드. **사용자 명시 호출 시에만** |

사용 예: `/tasks-dashboard all`, `/pr-desc`, `/review`, `/worktree-agent`

## 규칙

- 파일명은 **kebab-case**(repo 구조 파일 규칙). 커맨드 이름이 그대로 노출되므로 의미 있는 이름을 쓴다.
- 커맨드 본문은 **절차·규칙·출력 형식**을 자기완결적으로 기술한다(추측 금지·민감정보 비노출 원칙 포함).
- 전역 승인 게이트(`CLAUDE.md`)는 커맨드 실행 중에도 동일 적용된다.
