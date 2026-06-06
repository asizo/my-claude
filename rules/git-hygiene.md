# Git and Change Hygiene

> 자동 라우팅: "커밋 / PR / 머지 / 리베이스 / 태그 / 브랜치 정리 / git 이력 작업" 시 즉시 로드.
> 출처: 원본 CLAUDE.md의 `Git and Change Hygiene` 섹션.

---

- Keep commits atomic and describable; avoid "misc fixes" bundles.
- Don't rewrite history unless explicitly requested.
- Don't mix formatting-only changes with behavioral changes unless the repo standard requires it.
- Treat generated files carefully:
  - only commit them if the project expects it.

### Verification

- 상세는 `~/.claude/CLAUDE.md`의 **Definition of Done** 섹션 참조 (SSOT).
- 커밋·PR 작업도 DoD를 따른다 — 검증 스토리 1~2줄 필수.
