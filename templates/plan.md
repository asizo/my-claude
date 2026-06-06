# Plan Template

> 작업 계획서 골격. 자동 라우팅: "계획 / 플랜 / 설계 / 마이그레이션 / 3+ 단계 작업" 시 `rules/workflow.md`와 함께 로드.
> 산출물: 라이브 작업 체크리스트는 `tasks/todo.md`. 계획서를 별도 산출물로 보관할 때는 `tasks/YYYYMMDD_todo_{요약}.md` (날짜-앞·언더스코어 규칙).
> 출처: 원본 CLAUDE.md의 `Plan Template`.

---

- [ ] Restate goal + acceptance criteria
- [ ] Identify approval gates (if any: deployment, data deletion, financial transaction, external comms)
- [ ] Locate existing implementation / patterns
- [ ] Design: minimal approach + key decisions
- [ ] Implement smallest safe slice
- [ ] Add/adjust tests
- [ ] Run verification (lint/tests/build/manual repro)
- [ ] Summarize changes + verification story
- [ ] Record lessons (if any)

---

> Definition of Done: `~/.claude/CLAUDE.md`의 DoD 섹션 (SSOT) 참조.
