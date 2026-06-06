# Tooling Integration (Everything Claude Code)

> 자동 라우팅: "스킬 / MCP / 슬래시 커맨드 / 서브에이전트 활용" 트리거 시 로드.
> **적용 조건:** 이 규칙은 ECC(Everything Claude Code) 패키지가 **설치된 환경에서만** 적용된다. ECC 미설치 프로젝트에서는 무시한다.
> 출처: 원본 CLAUDE.md의 `Tooling Integration (Everything Claude Code)` 섹션.

The slash commands and subagents in this section are provided by the ECC package and can be customized per project.

---

### Priority: Skills Before MCP

- Always prefer skills over MCP when both can achieve the same goal.
- Skills are project-validated workflows with higher reliability.
- Use MCP only for external integrations (APIs, services) that skills cannot handle.
- Before introducing a new MCP, confirm that no existing skill covers the need.

### Slash Commands

- Before any non-trivial task → run `/plan` first.
- When implementing new features → follow the `/tdd` workflow.
- Before PR → run `/code-review`.
- On build errors → call `/build-fix`.
- To extract session patterns → run `/learn`.
- To convert a recurring workflow into a reusable skill → use `/skill-create`.

### Subagents

- Actively use specialized subagents in `agents/` (planner, code-reviewer, tdd-guide, etc.).
- Always pass the relevant skill's conventions into each subagent's prompt.
- Synthesize subagent outputs into a short, actionable summary before writing code.

### Skills

- Before working on any file, check `{project_root}/skills/` first, then `~/.claude/skills/` (project skill takes priority).
- `/skill-create` saves to `~/.claude/skills/` by default. Specify `{project_root}/skills/` explicitly for project-scoped skills.
- Refer to the Skills table in the project `CLAUDE.md` for file-to-skill mappings.
- Convert frequently used patterns into skills via `/skill-create` to maximize reuse.

---

> **충돌 주의 (CLAUDE.md ↔ AGENTS.md):** ECC의 AGENTS.md는 "80% 커버리지·TDD 필수", "Agent-First 능동 위임"을 권한다. 이는 글로벌 기본(`rules/engineering.md`의 실용주의 테스트, `rules/workflow.md`의 위임 절제)을 **대체하지 않고**, ECC 환경에서 해당 프로젝트가 명시적으로 채택할 때만 강화 규칙으로 적용한다. 기본 철학이 우선이다.
