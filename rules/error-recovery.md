# Error Handling and Recovery Patterns

> 자동 라우팅: "버그 / 장애 / 에러 / 안 됨 / 이상해 / 디버그 / 원인", 테스트 실패, 회귀 시 즉시 로드.
> 버그 리포트 작성 시 `~/.claude/templates/bugfix.md` 동시 로드.
> 출처: 원본 CLAUDE.md의 `Error Handling and Recovery Patterns` 섹션.

---

### 1. "Stop-the-Line" Rule

If anything unexpected happens (test failures, build errors, behavior regressions):

- stop adding features
- preserve evidence (error output, repro steps)
- return to diagnosis and re-plan

### 2. Triage Checklist (Use in Order)

1. Reproduce reliably (test, script, or minimal steps).
2. Localize the failure (which layer: UI, API, DB, network, build tooling).
3. Reduce to a minimal failing case (smaller input, fewer steps).
4. Fix root cause (not symptoms).
5. Guard with regression coverage (test or invariant checks).
6. Verify end-to-end for the original report.

### 3. Safe Fallbacks (When Under Time Pressure)

- Prefer "safe default + warning" over partial behavior.
- Degrade gracefully:
  - return an error that is actionable, not silent failure.
- Avoid broad refactors as "fixes."

### 4. Rollback Strategy (When Risk Is High)

- Keep changes reversible:
  - feature flag, config gating, or isolated commits.
- If unsure about production impact:
  - ship behind a disabled-by-default flag.

### 5. Instrumentation as a Tool (Not a Crutch)

- Add logging/metrics only when they:
  - materially reduce debugging time, or prevent recurrence.
- Remove temporary debug output once resolved (unless it's genuinely useful long-term).

### 6. Environment Audit (When Results Are Unstable)

Before changing models or rewriting prompts, check:

- Is there information the agent needs but cannot read?
- Where does the agent frequently get stuck or make repeated mistakes?
- Are failures discovered too late? (Add tests, linters, or verification earlier)
- Is the context window full of noise? (Add progressive disclosure or summarization)
- Are dangerous actions left to model judgment alone? (Add permission gates)
- Does each new session start from scratch? (Check progress file and feature list)
