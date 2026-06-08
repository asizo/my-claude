# DevContainer + Claude Code 통합 가이드

> `~/.claude/devcontainer-guide.md` 로 심링크되는 상세 레퍼런스. `rules/devcontainer.md` 가 devcontainer 설정 생성 전 이 파일을 읽도록 지시한다.
> 요약 규칙은 `rules/devcontainer.md`, 전체 절차·예시·트러블슈팅은 이 문서를 따른다.
> 목적: VS Code Dev Container 안에서 Claude Code CLI 를 사용하기 위한 일반화된 적용 패턴(호스트 인증·이력 공유, 컨테이너 안 `claude` 명령 활성화, 다중 프로젝트 세션 격리, 부가 패키지).

**핵심 3원칙**
1. **Claude Code 상태 보존**: 호스트 `~/.claude` 를 컨테이너에 bind mount → 대화 이력·인증·세션이 재빌드 후에도 보존.
2. **프로젝트별 격리**: `workspaceFolder` 를 프로젝트마다 고유하게 → `~/.claude/projects/` 세션 충돌 방지.
3. **경로 일관성**: `workspaceFolder` = docker-compose `working_dir` = volume target = (있다면) nginx root 까지 동일.

---

## 1. 통합 기능 3가지

| 기능 | 어디에 | 효과 |
|---|---|---|
| **호스트 `~/.claude` bind mount** | `devcontainer.json` `mounts` | 호스트의 Claude Code 인증·대화 이력·세션이 컨테이너에 자동 공유. 재빌드 후에도 보존 |
| **`@anthropic-ai/claude-code` npm 글로벌 설치** | `Dockerfile` (Node.js 18 필요) | 컨테이너 안에서 `claude` 명령으로 CLI 사용 가능 |
| **프로젝트별 고유 `workspaceFolder`** | `devcontainer.json` + compose volume 일치 | `~/.claude/projects/` 가 컨테이너 cwd 기반이라, 프로젝트별 분리로 다중 세션 충돌 방지 |

---

## 2. `devcontainer.json` 적용

```jsonc
{
    "name": "<project> dev container",
    "dockerComposeFile": "docker-compose.yml",
    "service": "<service-name>",

    // 프로젝트별 고유 경로 — ~/.claude/projects/ 충돌 방지 (절대 /app·/workspace 단독 금지)
    "workspaceFolder": "/workspace/<project>",
    "remoteUser": "root",

    // 호스트 ↔ 컨테이너 mount
    "mounts": [
        // Claude Code 상태/대화내역 호스트 공유 (재빌드 시 보존) — 쓰기 가능 필요
        "source=${localEnv:HOME}/.claude,target=/root/.claude,type=bind,consistency=cached",
        // SSH 키 공유 (선택 — git push/private repo clone 시). 키 변조 방지를 위해 readonly 권장
        "source=${localEnv:HOME}/.ssh,target=/root/.ssh,type=bind,readonly,consistency=cached"
    ],

    "postCreateCommand": "claude --version || true"
}
```

### 핵심 포인트
- `workspaceFolder`: `/workspace/<project>` 형태로 프로젝트마다 다른 경로.
- `remoteUser: "root"` → `/root/.claude` 가정. non-root 사용자면 target 도 `/home/<user>/.claude` 로 맞춤.
- `~/.claude` 는 **rw**(이력 저장), `~/.ssh` 는 **readonly**(키 유출·변조 방지) 권장.
- `consistency=cached`: macOS Docker Desktop 성능 권장값(Linux 호스트는 무시).
- 단일 컨테이너(compose 미사용) 구성이면 `dockerComposeFile`/`service` 대신 `image` 또는 `build` + `workspaceMount` 를 쓰고, target 을 `workspaceFolder` 와 일치시킨다.

---

## 3. `Dockerfile` 적용 — Node.js 18 + Claude Code CLI

```dockerfile
# ─────────────────────────────────────────────────────────────
# Node.js 18 (via nvm) — Claude Code CLI 요구사항
# ─────────────────────────────────────────────────────────────
ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=18

RUN bash -lc 'set -ex; \
    mkdir -p "$NVM_DIR"; \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; \
    . "$NVM_DIR/nvm.sh"; \
    nvm install "$NODE_VERSION"; \
    nvm use "$NODE_VERSION"; \
    nvm alias default "$NODE_VERSION"; \
    NODE_FULL="$(nvm version "$NODE_VERSION")"; \
    echo "$NODE_FULL" > "$NVM_DIR/current_version"; \
    ln -sf "$NVM_DIR/versions/node/$NODE_FULL/bin/node" /usr/local/bin/node; \
    ln -sf "$NVM_DIR/versions/node/$NODE_FULL/bin/npm"  /usr/local/bin/npm; \
    ln -sf "$NVM_DIR/versions/node/$NODE_FULL/bin/npx"  /usr/local/bin/npx'

# ─────────────────────────────────────────────────────────────
# Claude Code CLI 글로벌 설치
# ─────────────────────────────────────────────────────────────
RUN bash -lc 'set -ex; \
    NODE_FULL="$(cat "$NVM_DIR/current_version")"; \
    npm install -g @anthropic-ai/claude-code; \
    ln -sf "$NVM_DIR/versions/node/$NODE_FULL/bin/claude" /usr/local/bin/claude'
```

### 핵심 포인트
- **Node.js 18 이상 필수** — Claude Code CLI 최소 요구 버전.
- **nvm 사용 이유**: 베이스 이미지의 Node 버전과 무관하게 18 고정, 다른 npm 도구와 충돌 회피.
- **`current_version` 파일**: 다음 RUN 에서 `nvm version` 재호출 비용 회피.
- **symlink**: `/usr/local/bin/{node,npm,npx,claude}` — PATH 어디서나 직접 호출.
- **레이어 분리**: Node 설치와 claude 설치를 별도 RUN 으로 → Dockerfile 수정 시 캐시 활용도 ↑.

### Node 가 이미 설치된 경우
베이스 이미지(`node:18`)나 다른 RUN 에서 Node 가 설치돼 있으면 claude 설치만:

```dockerfile
RUN npm install -g @anthropic-ai/claude-code \
 && ln -sf "$(npm root -g)/@anthropic-ai/claude-code/cli.js" /usr/local/bin/claude || true
```

---

## 4. Claude Code 작업 환경 부가 패키지

CLI 자체는 §3 에서 설치된다. 아래는 컨테이너 안 효율 작업을 위한 권장 패키지.

### 4.1 필수 시스템 패키지 (Debian/Ubuntu 계열)

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl wget unzip ca-certificates \
        procps iproute2 net-tools \
        less vim \
        locales tzdata \
    && rm -rf /var/lib/apt/lists/*
```

| 패키지 | 용도 |
|---|---|
| `git` | Claude 가 git 명령(log/diff/blame/status 등) 다수 사용 |
| `curl`, `wget` | 외부 리소스 다운로드, HTTP 헬스체크 |
| `unzip` | 압축 파일 처리 |
| `ca-certificates` | TLS 인증서 (HTTPS, npm registry, github 등) |
| `procps` | `ps`, `top`, `kill` 등 프로세스 진단 |
| `iproute2`, `net-tools` | `ss`, `ip`, `netstat` 등 네트워크 진단 |
| `less`, `vim` | 파일 뷰어/에디터 (Claude 가 호출 가능) |
| `locales`, `tzdata` | 로케일·타임존 (한글 작업 시 필수) |

Alpine 계열은 `apk add` 로 패키지명만 동일하게 대체.

### 4.2 로케일 설정 (한글 작업 환경)

한글 파일을 Claude 가 읽거나 출력할 때 로케일 미설정이면 깨질 수 있다(한국어 환경 필수에 가까움).

```dockerfile
RUN sed -i -e 's/^# *ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' \
           -e 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
 && locale-gen \
 && update-locale LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8

ENV LANG=ko_KR.UTF-8 \
    LC_ALL=ko_KR.UTF-8 \
    TZ=Asia/Seoul

# 타임존 시스템 적용 (date, log 시각 등)
RUN ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
 && echo "Asia/Seoul" > /etc/timezone
```

### 4.3 vim 인코딩 설정 (선택)

```dockerfile
RUN { \
        echo 'set encoding=utf-8'; \
        echo 'set termencoding=utf-8'; \
        echo 'set fileencodings=utf-8,euc-kr,cp949'; \
        echo 'set fileformats=unix,dos'; \
    } >> /root/.vimrc
```

### 4.4 권장 추가 도구 (선택)

| 도구 | 용도 | 설치 |
|---|---|---|
| `ripgrep` (rg) | 빠른 grep, 대용량 코드베이스 검색 | `apt-get install -y ripgrep` |
| `jq` | JSON 처리, API 응답·gh 출력 파싱 | `apt-get install -y jq` |
| `tree` | 디렉터리 구조 시각화 | `apt-get install -y tree` |
| `fzf` | 인터랙티브 fuzzy finder | `apt-get install -y fzf` |
| `bash-completion` | 명령·옵션 자동완성 | `apt-get install -y bash-completion` |
| `gh` (GitHub CLI) | PR / 이슈 / actions 조작 (Claude 가 자주 호출) | 공식 설치 스크립트 (apt repo 추가) |

GitHub CLI 설치 예시:

```dockerfile
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*
```

### 4.5 npm 글로벌 도구 (선택, 프로젝트별)

```dockerfile
RUN bash -lc 'NODE_FULL="$(cat "$NVM_DIR/current_version")"; \
    npm install -g <패키지1> <패키지2>; \
    ln -sf "$NVM_DIR/versions/node/$NODE_FULL/bin/<bin1>" /usr/local/bin/<bin1>; \
    ln -sf "$NVM_DIR/versions/node/$NODE_FULL/bin/<bin2>" /usr/local/bin/<bin2>'
```

자주 추가되는 패키지 예: `typescript`/`ts-node`, `prettier`/`eslint`, `pnpm`/`yarn`, `serve`/`http-server`.

### 4.6 편의 alias

```dockerfile
RUN { \
        echo "alias ll='ls -alF --color=auto'"; \
        echo "alias la='ls -A --color=auto'"; \
        echo "alias ..='cd ..'"; \
    } >> /etc/bash.bashrc
```

---

## 5. `docker-compose.yml` 적용

```yaml
services:
  <service-name>:
    build:
      context: ./<dockerfile-dir>
      dockerfile: Dockerfile
    working_dir: /workspace/<project>
    volumes:
      - ../:/workspace/<project>:rw
    # 다른 설정...
```

### 핵심 포인트
- **`working_dir`** = `devcontainer.json` 의 `workspaceFolder`.
- **volume target** 도 같은 경로(`/workspace/<project>`) — 일관성 필수.
- **소스 마운트(rw)**: 컨테이너 변경이 호스트에 즉시 반영.

---

## 6. (조건부) 웹 서버(nginx 등) 경로 일치

PHP-FPM + nginx 같은 구성이면 nginx root / FastCGI 경로도 동일 경로로 통일.

```nginx
server {
    root  /workspace/<project>;

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME   /workspace/<project>$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT     /workspace/<project>;
        fastcgi_pass <php-service>:9000;
    }
}
```

```yaml
# docker-compose.yml — nginx 서비스에도 같은 volume 마운트
services:
  <nginx-service>:
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ../:/workspace/<project>:ro
```

---

## 7. 검증 명령

```bash
# 컨테이너 진입
docker compose exec <service-name> bash

# Claude Code CLI 동작
claude --version
claude -p "현재 디렉토리 구조 요약"

# Node 버전 (v18.x)
node --version

# 호스트 mount 확인
ls -la /root/.claude
ls -la /root/.ssh    # SSH mount 한 경우

# workspaceFolder 동작
pwd    # → /workspace/<project>

# 로케일·타임존
locale
date

# 부가 도구
git --version
rg --version    # 설치 시
jq --version    # 설치 시
gh --version    # 설치 시
```

`/root/.claude` 가 비어 있으면 → 호스트에서 한 번이라도 `claude` 를 실행해 디렉터리가 생성됐는지 확인.

---

## 8. 다중 프로젝트 세션 격리 원리

Claude Code 는 호스트 `~/.claude/projects/` 아래에 **컨테이너 cwd 기반 디렉터리**로 세션을 저장한다.

```
~/.claude/
└── projects/
    ├── -workspace-projectA/    ← workspaceFolder=/workspace/projectA
    ├── -workspace-projectB/    ← workspaceFolder=/workspace/projectB
    └── -var-www-app/           ← workspaceFolder=/var/www/app  ← 충돌 위험
```

여러 프로젝트가 동일 `workspaceFolder`(예: `/var/www/app`, `/app`, `/workspace`)를 쓰면 세션·대화이력이 같은 폴더에 섞인다.

- ✅ **권장**: 프로젝트마다 `/workspace/<프로젝트명>` 으로 분리.
- ❌ **회피**: 모든 프로젝트가 동일한 `/var/www/app`, `/app`, `/workspace`.

---

## 9. 보안 고려 사항

| 항목 | 위험 | 완화 |
|---|---|---|
| `~/.claude` mount | Claude API 인증 토큰 포함. 격리 약화 | 신뢰 가능한 base image 만 사용. third-party 이미지에 mount 금지 |
| `~/.ssh` mount | SSH private key 노출 | `readonly` 마운트. 필요 없으면 제거 |
| `remoteUser: root` | mount 된 호스트 파일에 root 권한 접근 | non-root 전환 가능(단 `/home/<user>/.claude` target 변경) |
| `npm install -g` | supply chain 위험 | `@anthropic-ai/claude-code` 는 공식 패키지. 다른 패키지 추가 시 출처 확인 |

---

## 10. 트러블슈팅

### `claude: command not found`
```bash
ls -la /usr/local/bin/claude          # 1) symlink 확인
npm root -g                            # 2) npm 글로벌 경로
ls "$(npm root -g)/@anthropic-ai/claude-code/"
NODE_FULL=$(node -v)                   # 3) 다시 symlink
ln -sf "$NVM_DIR/versions/node/$NODE_FULL/bin/claude" /usr/local/bin/claude
```

### `~/.claude` 가 비어 있음
호스트에서 Claude Code 를 한 번도 실행하지 않은 상태. 호스트에서 `claude` 실행 후 컨테이너 재기동.

### 다른 프로젝트 세션이 보임
`workspaceFolder` 가 다른 프로젝트와 동일. `/workspace/<프로젝트명>` 으로 고유화 후 재빌드.

### 한글이 `?`/`□` 로 표시됨
§4.2 로케일 누락. `locale` 로 `LANG=ko_KR.UTF-8` 확인 후 locale-gen 블록 적용·재빌드.

### `npm install` 권한 오류
nvm 안 실행이면 보통 문제 없음. 본 가이드 RUN 블록 사용 권장. 다른 방식이면 `NPM_CONFIG_UNSAFE_PERM=1` 또는 `npm install -g --unsafe-perm`.

### Node.js 16 이하 베이스 이미지
`@anthropic-ai/claude-code` 설치 실패 → nvm 으로 Node 18 강제 설치 후 진행.

### `gh auth status` 실패
`~/.config/gh` 미마운트. `mounts` 에 추가:
```jsonc
"source=${localEnv:HOME}/.config/gh,target=/root/.config/gh,type=bind,consistency=cached"
```

---

## 11. 다른 프로젝트 적용 체크리스트

**필수**
- [ ] `workspaceFolder` 를 `/workspace/<프로젝트명>` 으로 고유화
- [ ] `mounts` 에 `~/.claude`(rw) 추가, `~/.ssh`(readonly) 선택
- [ ] `Dockerfile` 에 Node 18 + `@anthropic-ai/claude-code` 설치 블록
- [ ] compose `working_dir` + volume target 을 `workspaceFolder` 와 일치

**권장**
- [ ] §4.1 필수 시스템 패키지 (git, curl, less, vim, locales 등)
- [ ] §4.2 로케일 설정 (한국어 환경)
- [ ] §4.4 추가 도구 (ripgrep, jq, gh)

**조건부**
- [ ] nginx 등 동일 소스 컨테이너의 root / FastCGI 경로도 통일
- [ ] `~/.ssh` mount — 컨테이너 안 git/ssh 필요 시
- [ ] `~/.config/gh` mount — gh CLI 인증 필요 시

**검증**
- [ ] `postCreateCommand` 에 `claude --version`
- [ ] 호스트에서 `claude` 한 번 실행해 `~/.claude/` 사전 생성

---

## 12. 참고 링크

- Claude Code CLI npm 패키지: `@anthropic-ai/claude-code`
- VS Code Dev Containers: https://code.visualstudio.com/docs/devcontainers/containers
- nvm: https://github.com/nvm-sh/nvm
- Devcontainer Spec mounts: https://containers.dev/implementors/json_reference/#mounts
- GitHub CLI 설치: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
