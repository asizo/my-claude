# Lessons Template

> 누적된 실수와 교훈 로그(`tasks/lessons.md`)의 골격. **라이브 파일은 프로젝트별 `tasks/lessons.md`** 이며, 새 프로젝트에서 이 골격으로 시작한다(templates/ 는 전역 골격, tasks/ 는 per-project 라이브).
> 절차: 사용자 교정·발견된 실수·사후 분석 직후 항목을 **추가(append)** 한다. 세션 시작 시와 주요 리팩터링 전 검토한다. 자세한 규칙은 `~/.claude/rules/workflow.md`의 `Self-Improvement Loop` 참조.
> 정기 검토 시 더 이상 유효하지 않은 항목은 `docs/archive/YYYY-MM/YYYYMMDD_lessons.md` 로 옮긴다(삭제 금지).

---

## YYYY-MM-DD — {간단한 제목}

- **실패 양상(Failure mode):** 무엇이 어떻게 잘못되었는가.
- **탐지 신호(Detection signal):** 무엇을 보고 알아챘는가(에러 메시지·테스트 실패·리뷰 지적 등).
- **근본 원인(Root cause):** 표면 증상이 아닌 실제 원인.
- **예방 규칙(Prevention rule):** 재발을 막기 위해 앞으로 무엇을 다르게 할 것인가(구체적·실행 가능하게).

<!-- 새 항목은 위에 최신순으로 추가한다. -->
