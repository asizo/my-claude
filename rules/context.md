# Context Management Strategies (Don't Drown the Session)

> 자동 라우팅: "컨텍스트 비대화 우려, 대량 검색 · 다중 파일 읽기 시작" 시 즉시 로드.
> 출처: 원본 CLAUDE.md의 `Context Management Strategies` 섹션.

세션 컨텍스트는 한정 자원이다. 토큰 낭비는 정확도 저하로 직결된다.

---

### 1. Read Before Write

- Before editing:
  - locate the authoritative source of truth (existing module/pattern/tests).
- Prefer small, local reads (targeted files) over scanning the whole repo.

### 2. Keep a Working Memory

- Maintain a short running "Working Notes" section in `tasks/todo.md`:
  - key constraints, invariants, decisions, and discovered pitfalls.
- When context gets large:
  - compress into a brief summary and discard raw noise.

### 3. Memory Ownership

- **Agent context:** holds only what is immediately needed for the current step.
- **External memory (files):** all state that must survive across steps or sessions — progress, decisions, constraints, failure history — is written to files, not held in context alone.
- **On session resume:** always read from external memory first before taking any action; never rely on what "feels like" the current state.

### 4. Minimize Cognitive Load in Code

- Prefer explicit names and direct control flow.
- Avoid clever meta-programming unless the project already uses it.
- Leave code easier to read than you found it.

### 5. Control Scope Creep

- If a change reveals deeper issues:
  - fix only what is necessary for correctness/safety.
  - log follow-ups as TODOs/issues rather than expanding the current task.

### 6. Cost and Latency Awareness

- Before starting a repetitive loop or large-scale task, estimate expected token usage and set an upper bound; stop and re-plan if the bound is exceeded.
- Monitor token usage per task; avoid unnecessary large context loads.
- Use `/cost` (Claude Code built-in) to track spending during sessions.
- Prefer lighter models for routine, low-reasoning tasks; escalate to a higher-reasoning model only when the task genuinely needs deeper analysis. (Pick the tier by task complexity rather than naming a fixed model — model lineups change.)
- If a task is consuming excessive tokens without progress, stop, compact, and re-plan.
