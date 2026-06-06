# Workflow Orchestration & Task Management

> 자동 라우팅: "계획 / 플랜 / 설계 / 리팩터링 / 마이그레이션 / 다중 파일 변경 / 3+ 단계 작업" 트리거 시 즉시 로드.
> 보완: `~/.claude/templates/plan.md` 동시 로드.
> 출처: 원본 CLAUDE.md의 `Workflow Orchestration`(승인 게이트 제외) + `Task Management` 섹션.
> 참고: Human-in-the-loop 승인 게이트는 누락 시 사고로 직결되므로 CLAUDE.md(상시)에 유지한다.

---

## Workflow Orchestration

### 1. Plan Mode Default

- Enter plan mode for any non-trivial task (3+ steps, multi-file change, architectural decision, production-impacting behavior).
- Include verification steps in the plan (not as an afterthought).
- If new information invalidates the plan: stop, update the plan, then continue.
- Write a crisp spec first when requirements are ambiguous (inputs/outputs, edge cases, success criteria).

### 2. Subagent Strategy (Parallelize Intelligently)

- Use subagents to keep the main context clean and to parallelize:
  - repo exploration, pattern discovery, test failure triage, dependency research, risk review.
- Give each subagent one focused objective and a concrete deliverable:
  - `"Find where X is implemented and list files + key functions"` beats "look around."
- Merge subagent outputs into a short, actionable synthesis before coding.
- **Delegate when it earns its keep:** reach for subagents when context protection or parallelism is a real win, not as a reflex on every small task. Simple, single-file work is usually faster done directly.
- **Role separation is mandatory:** the agent that generates must not evaluate its own output.
  - **Generator:** implement only; record changes, verification run, and uncertainties.
  - **Evaluator:** assess only; do not modify; report failures with specific evidence and repro steps.
  - **Single-agent fallback:** when subagents are unavailable, complete generation first, then perform a separate critical review pass of the output before proceeding.

### 3. Incremental Delivery (Reduce Risk)

- Prefer thin vertical slices over big-bang changes.
- Land work in small, verifiable increments:
  - implement → test → verify → then expand.
- When feasible, keep changes behind:
  - feature flags, config switches, or safe defaults.

### 4. Self-Improvement Loop

- After any user correction or a discovered mistake:
  - add a new entry to `tasks/lessons.md` capturing:
    - the failure mode, the detection signal, and a prevention rule.
- Review `tasks/lessons.md` at session start and before major refactors.
- Periodically review and remove stale instructions, tools, and checks:
  - Ask: "Is this rule still necessary, or has the model improved past it?"
  - Ask: "Is this tool still scoped safely for current usage?"
  - Remove or simplify anything that no longer reduces risk or adds value.

### 5. Verification Before "Done"

- Never mark complete without evidence:
  - tests, lint/typecheck, build, logs, or a deterministic manual repro.
- Compare behavior baseline vs changed behavior when relevant.
- Ask: "Would a staff engineer approve this diff and the verification story?"
- 상세 정의는 `~/.claude/CLAUDE.md`의 **Definition of Done** 섹션 참조 (SSOT).

### 6. Demand Elegance (Balanced)

- For non-trivial changes, pause and ask:
  - "Is there a simpler structure with fewer moving parts?"
- If the fix is hacky, rewrite it the elegant way if it does not expand scope materially.
- Do not over-engineer simple fixes; keep momentum and clarity.

### 7. Autonomous Bug Fixing (With Guardrails)

- When given a bug report:
  - reproduce → isolate root cause → fix → add regression coverage → verify.
- Do not offload debugging work to the user unless truly blocked.
- If blocked, ask for one missing detail with a recommended default and explain what changes based on the answer.

---

## Task Management (File-Based, Auditable)

1. **Plan First**
   - Write a checklist to `tasks/todo.md` for any non-trivial work.
   - Include "Verify" tasks explicitly (lint/tests/build/manual checks).
2. **Define Success**
   - Add acceptance criteria (what must be true when done).
3. **Track Progress**
   - Mark items complete as you go; keep one "in progress" item at a time.
4. **Checkpoint Notes**
   - Capture discoveries, decisions, and constraints as you learn them.
   - Write a heartbeat entry to `tasks/todo.md` after each major step or after 3 or more file changes: current step, next step, blockers.
5. **Document Results**
   - Add a short "Results" section: what changed, where, how verified.
6. **Capture Lessons**
   - Update `tasks/lessons.md` after corrections or postmortems.
   - On periodic review, move entries that are no longer valid to `docs/archive/YYYY-MM/YYYYMMDD_lessons.md`.
7. **Audit Trail**
   - For any high-risk action (file deletion, external call, deployment), log in `tasks/todo.md`:
     - what was requested, what was executed, what tool was used, and the outcome.
   - Record human approvals explicitly: who approved, when, and for what action.
   - On `/compact`, audit trail entries are carried over into `docs/*_work_history.md`.
