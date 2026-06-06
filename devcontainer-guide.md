# DevContainer Generation Guide

> `~/.claude/devcontainer-guide.md` 로 심링크되는 상세 레퍼런스. `rules/devcontainer.md` 가 devcontainer 설정 생성 전 이 파일을 읽도록 지시한다.
> 요약 규칙은 `rules/devcontainer.md`, 전체 절차·예시는 이 문서를 따른다.

---

## 핵심 원칙

1. **Claude Code 상태 보존**: `~/.claude` 를 컨테이너에 마운트해 대화 이력·설정·스킬을 공유한다.
2. **프로젝트별 격리**: `workspaceFolder` 를 프로젝트마다 고유하게 둔다. 공유 시 대화 이력이 프로젝트 간 충돌한다.
3. **경로 일관성**: `workspaceMount`, `workspaceFolder`, `postCreateCommand`, `remoteEnv` 가 모두 같은 경로를 가리켜야 한다.

---

## 필수 마운트 (항상 포함)

| 호스트 | 컨테이너 | 옵션 | 이유 |
|---|---|---|---|
| `~/.claude` | `/root/.claude` | (rw) | Claude Code 상태·대화 이력·스킬 |
| `~/.ssh` | `/root/.ssh` | `readonly` | Git SSH 인증 |

> `~/.claude` 는 쓰기 가능해야 한다(대화 이력 저장). `~/.ssh` 는 readonly 로 키 유출·변조를 막는다.

---

## workspaceFolder 규칙

- 프로젝트마다 고유 경로를 쓴다: 예 `/workspace/my-project`.
- **`/app` 을 쓰지 않는다** — 여러 프로젝트가 동일 경로를 쓰면 대화 이력이 충돌한다.
- 경로를 바꾸면 `workspaceMount` 의 `dst`, `postCreateCommand` 의 작업 디렉토리, `remoteEnv` 경로를 함께 갱신한다.

---

## devcontainer.json 예시

```jsonc
{
  "name": "my-project",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",

  // 프로젝트별 고유 경로 (절대 /app 사용 금지)
  "workspaceFolder": "/workspace/my-project",
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace/my-project,type=bind",

  "mounts": [
    // Claude Code 상태/대화 이력 (rw)
    "source=${localEnv:HOME}/.claude,target=/root/.claude,type=bind",
    // Git SSH 인증 (readonly)
    "source=${localEnv:HOME}/.ssh,target=/root/.ssh,type=bind,readonly"
  ],

  "remoteEnv": {
    "WORKSPACE": "/workspace/my-project"
  },

  // 의존성 설치 등 (프로젝트 컨벤션에 맞게 조정)
  "postCreateCommand": "cd /workspace/my-project && (test -f package.json && npm ci || true)"
}
```

> `mcr.microsoft.com/devcontainers/base:ubuntu` 는 기본 예시다. 프로젝트 런타임(Node/Python/Go 등)에 맞는 이미지나 `features` 로 교체한다.

---

## 생성 후 검증 체크리스트

- [ ] `~/.claude` 와 `~/.ssh` 마운트가 모두 포함되었는가
- [ ] `~/.ssh` 가 `readonly` 인가
- [ ] `workspaceFolder` 가 프로젝트 고유 경로인가 (`/app` 아님)
- [ ] `workspaceMount` target == `workspaceFolder` 인가
- [ ] `postCreateCommand` 와 `remoteEnv` 경로가 `workspaceFolder` 와 일치하는가
- [ ] 컨테이너 재빌드 후 Claude Code 대화 이력이 보존되는가
