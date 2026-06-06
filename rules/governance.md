# Document & Session Governance

> 자동 라우팅: "문서 작성 / 산출물 저장 / 외부 참고자료 / `/compact` / 세션 재개 / 프로젝트 초기화" 시 즉시 로드.
> 출처: 원본 CLAUDE.md의 `Directory & File Structure` + `Project Initialization` + `Document & Session Management` 섹션.

---

## Directory & File Structure

```
{project_root}/
├── CLAUDE.md                           # Project-level rules (overrides global rules)
├── tasks/
│   ├── todo.md                         # Active task checklist + Working Notes (live state)
│   └── lessons.md                      # Accumulated mistakes and lessons
├── docs/
│   ├── project_overview_YYYYMMDD.md    # Project structure summary (created on init)
│   ├── work_history_YYYYMMDDHHII.md    # Session handoff file (created on /compact, immutable)
│   ├── {document_title}_YYYYMMDD.md    # Agent-generated documents
│   ├── references/                     # Externally received documents (PRDs, API specs, etc. — permanent)
│   └── archive/
│       └── YYYY-MM/
│           ├── work_history_*.md       # work_history files older than 30 days
│           └── lessons_YYYYMMDD.md     # Archived lessons (created on periodic review)
├── agents/                             # Subagent definition files
├── skills/                             # Project-level reusable skills
└── .devcontainer/
    └── devcontainer.json               # Dev container configuration

~/.claude/
├── CLAUDE.md                           # Global rules (applied to all projects)
├── devcontainer-guide.md               # devcontainer generation guide
└── skills/                             # Global reusable skills
```

**Path rules:**
- **Priority:** `{project_root}/CLAUDE.md` > `~/.claude/CLAUDE.md`. Project rules win on conflict.
- `document_root` is the directory containing `{project_root}/CLAUDE.md`. If no project CLAUDE.md exists, `document_root` is undefined and only global rules apply.
- **Skill lookup order:** `{project_root}/skills/` → `~/.claude/skills/`. Project skill wins on name conflict.
- `/skill-create` saves to `~/.claude/skills/` by default. Specify `{project_root}/skills/` explicitly for project-scoped skills.
- All agent-generated documents go into `docs/`. All externally received documents go into `docs/references/`. Never mix the two.
- Documents derived from external references (edited, expanded, or summarized by the agent) are saved as new files in `docs/` with `> derived from: references/{original_filename}` at the top.
- `docs/references/` is excluded from archiving (external originals are preserved permanently).
- Archive rules apply to `work_history_*.md` and `lessons_YYYYMMDD.md` only. All other `docs/` files are retained in place permanently.
- `tasks/` is for task tracking only. Never record secrets or API keys here.
- File naming convention: `{title_in_english_snake_case}_YYYYMMDD.md`

---

## Project Initialization

> 1회성 — 새 프로젝트 시작 시점에만 수행. 매 세션 반복하지 않는다.

When starting a new project, before any other work:

1. Verify `docs/` and `tasks/` directories exist; create them if missing.
2. Create `tasks/todo.md` and `tasks/lessons.md` if they do not exist.
3. Scan the project structure and write `docs/project_overview_YYYYMMDD.md` summarizing:
   - purpose, tech stack, directory layout, and any known constraints.
4. Check for existing `docs/work_history_*.md` files and load context before proceeding.

---

## Document Storage

- `document_root` is the project root (the directory where `CLAUDE.md` is located).
- All documents are stored under `{document_root}/docs/`.
- File naming convention: `{document_title_in_english_snake_case}_YYYYMMDD.md`
  - e.g. `api_design_20250416.md`, `refactor_plan_20250416.md`

### External Reference Documents

- Documents received from outside (PRDs, API specs, design docs, etc.) go into `docs/references/`.
- Agent-generated documents go into `docs/` root. Never mix the two.
- Documents derived from external references are saved as new files in `docs/` with `> derived from: references/{original_filename}` at the top.

### Document Versioning

- When updating an existing document, create a new file with the current date (do not overwrite).
- Do not delete older versions — retain them for history.
- If a new document supersedes an older one, add at the top of the new file:
  - `> supersedes: previous_document_name_YYYYMMDD.md`

### Security in Documents

- Never record environment variables, API keys, passwords, or any secret material in `docs/` or `tasks/`.
- Replace any sensitive values with `[REDACTED]` if they must be referenced.
- This rule applies equally to work_history files.

---

## Work History (`/compact`)

> **Important:** 모델이 작성하는 풍부한 work_history 는 자동이 아니다. `/compact` 시 아래 절차를 먼저 수행한다.
>
> **안전망(PreCompact 훅):** compact(수동·자동) 직전 `precompact.sh` 가 git 변경 파일·최근 명령·최근 사용자 요청을 모아 `docs/work_history_*.md` **스냅샷**을 자동 저장한다(`# Work History (auto-snapshot)` 헤더로 식별). 이는 **자동 compact 시 핸드오프 누락을 막는 기계적 안전망**이며, 모델이 작성한 핸드오프를 대체하지 않는다. 모델이 최근 3분 내 work_history 를 이미 작성했다면 스냅샷은 생략된다. auto-snapshot 파일을 발견하면 다음 세션에서 내용을 검토·보강한다.

Procedure (order is mandatory):

1. Write `docs/work_history_YYYYMMDDHHII.md`.
2. Confirm the file was saved successfully.
3. Only then proceed with context compression.

File path: `docs/work_history_YYYYMMDDHHII.md`
(e.g. `docs/work_history_202504161430.md`)

- The file must be complete enough for the next agent to resume without any additional context.
- Once created, the file is immutable. If an update is needed, create a new file.
- When compacting context, the following must always be preserved in full (never summarized away):
  - Accepted decisions and their rationale
  - Security and permission constraints
  - User-confirmed preferences and requirements
  - Known failure modes and lessons learned
- **Required sections:** Follow the Work History Template in `~/.claude/templates/work-history.md` exactly.

### Work History Archiving

- Work history files older than 30 days (based on the date in the filename) are moved to `docs/archive/YYYY-MM/`.
  - e.g. `docs/work_history_202503161430.md` → `docs/archive/2025-03/work_history_202503161430.md`
- `lessons_YYYYMMDD.md` files are archived to `docs/archive/YYYY-MM/` on periodic review.
- Never delete archived files.
- `docs/references/` is excluded from archiving.

---

## Starting a New Session

1. Read all `docs/work_history_*.md` files in chronological order (oldest first, within the 30-day window).
   - Reading only the latest file is insufficient — full decision history and change context must be understood.
2. Review `tasks/todo.md` and `tasks/lessons.md`.
3. If a setup script (`setup.sh`, `Makefile`, etc.) exists in the project root, run it first.
4. Run a smoke test (build, lint, or minimal test suite) to confirm clean state.
   - If the smoke test fails, fix the environment before any feature work.
   - If no setup script exists and the smoke test fails, install dependencies following project conventions and retry.
5. Identify any `in_progress` item from the Pending feature list in the latest work_history.
   - If none, select one `not_started` item from the Pending feature list.
6. Work on exactly one item at a time until it passes verification, then update `tasks/todo.md` and proceed.

**Notes:**
- `tasks/todo.md` is the live state of the active task. No obligation to update it after session end.
- `docs/work_history_*.md` is an immutable snapshot taken at session end. If the two conflict, work_history is the source of truth (SoT).
- If the previous session ended without `/compact` (no work_history created), treat `tasks/todo.md` as the source of truth for that session.
- If no Pending feature list exists (first session or no work_history), wait for user instructions.
- Archived files in `docs/archive/` are for reference only and are not part of the mandatory read sequence.
- If no work history exists, start a fresh session from step 3.
