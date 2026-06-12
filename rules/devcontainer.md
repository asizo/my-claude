# DevContainer Setup

> 자동 라우팅: "`.devcontainer/devcontainer.json` 생성 / 수정 / dev container 설정" 작업 시 로드.
> 출처: 원본 CLAUDE.md의 `DevContainer Setup` 섹션.

---

When creating or modifying a `.devcontainer/devcontainer.json` file:

- Always read `~/.claude/devcontainer-guide.md` before generating any devcontainer configuration.
- **Required mounts** (must always be included):
  - `~/.claude` → `/root/.claude` (Claude Code state and conversation history)
  - `~/.ssh` → `/root/.ssh` (Git SSH authentication, readonly)
    - ⚠️ 컨테이너 안에서도 `settings.json`의 `deny Read(~/.ssh/**)`가 Claude의 직접 키 읽기를 차단한다(`~/.claude` 마운트로 deny가 함께 적용될 때). 단, `--dangerously-skip-permissions` 모드에서는 deny가 무시되어 마운트된 키가 노출될 수 있으므로, 권한 스킵 모드는 신뢰 가능한 작업에만 사용한다.
- Always set a unique `workspaceFolder` per project (e.g. `/workspace/my-project`) to prevent conversation history from being shared across projects.
- Never use `/app` as `workspaceFolder` when multiple projects exist — it causes conversation history collision.
- Verify that `workspaceMount`, `workspaceFolder`, `postCreateCommand`, and `remoteEnv` paths are all consistent after any workspace path change.
