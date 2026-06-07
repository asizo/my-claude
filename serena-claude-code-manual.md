# Serena + Claude Code 설치·사용 매뉴얼

> Serena를 Claude Code에 붙여서, AI 코딩 도구가 코드베이스를 더 똑똑하게 이해하고 프로젝트 맥락을 기억하게 만드는 방법을 정리한 문서입니다.

---

## 1. Serena가 뭔가요?

Claude Code 같은 AI 코딩 도구는 **새 대화를 시작할 때마다 기억상실에 걸린 신입 개발자**와 비슷합니다. 어제 뭘 했는지, 이 프로젝트가 어떻게 생겼는지 모르기 때문에 매번 코드 파일을 처음부터 다시 뒤져야 하고, 그만큼 시간과 토큰(비용)이 듭니다.

**Serena**는 여기에 두 가지를 더해주는 오픈소스 MCP 툴킷입니다.

1. **IDE 같은 똑똑한 코드 탐색** — 단순 글자 검색(grep)이 아니라, "이 함수가 어디서 쓰이는지", "이 변수의 정의가 어디인지"를 언어 서버(LSP) 기반으로 심볼 단위로 이해하며 찾아줍니다. 필요한 부분만 콕 집어내므로 파일을 통째로 읽지 않아도 됩니다.

2. **메모리 기능 ("캐싱 같은 역할")** — 처음 실행될 때 프로젝트를 한 번 분석해서 핵심 내용을 요약 메모(`.serena/memories/`)로 저장합니다. 다음 작업부터는 이 요약 노트를 읽기 때문에 매번 전체를 다시 분석할 필요가 없습니다. 교과서를 매번 통째로 다시 읽는 대신 정리해둔 요약 노트를 펼쳐보는 것과 비슷하다고 해서 "캐시 같다"고 표현합니다.

> 참고: 이 메모리는 GPTCache 같은 시맨틱 캐시(벡터 스토어)가 아니라, 사람도 읽고 편집할 수 있는 **프로젝트 로컬 마크다운 파일**입니다.

---

## 2. 준비물 설치 (uv)

Serena는 `uv`라는 파이썬 도구로 실행됩니다. 아직 없다면 먼저 설치하세요.

**macOS / Linux**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

설치 후 터미널을 껐다 켜거나 다음 명령으로 환경을 새로고침하세요.

```bash
source ~/.bashrc # zsh를 쓰면 ~/.zshrc
```

`uvx`는 `uv`에 포함되어 있어 따로 설치할 필요가 없습니다.

---

## 3. 설치 (Claude Code에 등록)

### 3-1. 작업할 프로젝트 폴더로 이동

```bash
cd 내-프로젝트-경로
```

### 3-2. 한 줄 명령으로 등록

프로젝트 루트에서 아래 명령을 실행합니다.

```bash
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project $(pwd)
```

### 3-3. 그냥 평소처럼 Claude Code 사용

이걸로 끝입니다. Claude Code를 켜서 평소대로 대화하면 됩니다. 첫 실행 시 Serena가 프로젝트를 분석해 `.serena/memories/`에 메모리 파일을 만들고, 이후 세션부터 이를 활용합니다.

---

## 4. 명령어 옵션 설명

명령은 `--`를 기준으로 두 부분으로 나뉩니다. 앞은 "Claude Code에게 등록", 뒤는 "그 서버를 실제로 어떻게 실행할지"입니다.

| 부분 | 의미 |
|------|------|
| `claude mcp add serena` | Claude Code에 `serena`라는 이름(별명, 변경 가능)으로 MCP 서버를 추가 |
| `--` | 구분선. 여기까지가 Claude Code 옵션, 뒤는 전부 "실행할 명령"이라는 표시 |
| `uvx` | `uv`의 실행 도구. 패키지를 따로 설치하지 않고 그때그때 받아 바로 실행 |
| `--from git+https://github.com/oraios/serena` | Serena 코드를 받아올 위치(공식 저장소 oraios/serena) 지정 |
| `serena start-mcp-server` | 받아온 Serena를 MCP 서버 모드로 켜라 |
| `--context ide-assistant` | "Claude Code 같은 코딩 도구 안에서 보조로 쓴다"는 환경 설정. 도구 구성과 프롬프트가 그에 맞게 최적화됨 (권장) |
| `--project $(pwd)` | Serena가 작업할 프로젝트 폴더 지정. `$(pwd)`는 "지금 있는 폴더 경로"를 자동으로 넣는 셸 문법. 직접 경로를 적어도 됨 (예: `--project /Users/me/myapp`) |

**한 줄 요약**

> Claude Code야, `serena`라는 MCP 서버를 등록해줘. 그 서버는 이렇게 실행하면 돼: uv로 깃허브의 oraios/serena를 받아서 MCP 서버 모드로 켜고, IDE 보조용 설정으로, 지금 이 폴더를 대상으로.

---

## 5. 재부팅하면 다시 켜야 하나요?

**아니요, 매번 켤 필요 없습니다.** 한 번 `claude mcp add`로 등록하면 그 설정이 저장되어, 재부팅하든 터미널을 껐다 켜든 Claude Code를 실행할 때마다 Serena가 자동으로 함께 뜹니다.

동작 구조는 이렇습니다.

- `claude mcp add`로 한 일은 "Serena를 항상 켜둬라"가 아니라, **"Claude Code야, 너 켜질 때 이 명령으로 Serena를 같이 실행해"** 라는 *설정 등록*입니다.
- Serena 서버 자체는 평소엔 떠 있지 않다가, 해당 프로젝트에서 Claude Code를 시작하는 순간 Claude Code가 알아서 켭니다.
- Claude Code를 종료하면 Serena도 함께 꺼집니다.
- 즉 **Claude Code의 수명에 붙어 자동으로 켜지고 꺼지는** 구조라 재부팅 후 따로 손댈 게 없습니다.

> **scope 주의:** `--project $(pwd)`로 기본(local) 등록하면 그 프로젝트에서만 Serena가 붙습니다. 모든 프로젝트에서 쓰고 싶다면 등록 시 user scope로 추가하세요.

---

## 6. 확인 & 문제 해결

### 등록 확인

Claude Code 안에서:

```bash
claude mcp list
```

목록에 `serena`가 보이면 정상입니다.

### 첫 응답 속도 높이기 (선택)

프로젝트를 미리 인덱싱해두면 첫 응답이 빨라집니다.

```bash
uvx --from git+https://github.com/oraios/serena serena project index
```

### 자주 겪는 문제

- **재부팅 후 Serena가 안 보이거나 연결 실패** → 대개 새 셸 세션에서 `uv`/`uvx`의 PATH가 안 잡힌 경우입니다. 터미널을 새로 열거나 `source ~/.zshrc`(또는 `~/.bashrc`)로 환경을 새로고침하세요.
- **설치 방식 혼동** → npm이 아니라 `uvx`로 실행하는 게 맞습니다. 또한 Serena는 **MCP/플러그인 마켓플레이스를 통해 설치하지 말 것**이 공식 권장 사항입니다(마켓플레이스 등록본은 대부분 비공식 포크). 공식 저장소 `github.com/oraios/serena`의 안내를 따르세요.

---

## 7. 알아두면 좋은 점

- **비용:** MCP 기능은 Claude 무료 플랜에서도 동작하고 Serena 자체는 오픈소스라 무료입니다. 단, Claude Code 사용에 드는 토큰 비용은 평소대로 발생합니다. 오히려 Serena가 필요한 코드만 집어 읽어 토큰을 아껴주는 효과가 있습니다.
- **보안:** Claude Code / Claude Desktop 설정에서는 기본적으로 shell 명령 실행이 켜져 있어, Serena가 코드·테스트를 직접 실행해 오류를 자동 수정할 수 있습니다. 편리하지만 임의 명령을 실행하는 것이므로 주의하세요. 분석만 하고 싶다면 프로젝트 설정에서 `read_only: true`로 두면 됩니다.
- **메모리 위치:** 프로젝트별 메모리는 해당 프로젝트의 `.serena/memories/` 폴더에 마크다운으로 저장됩니다. 직접 열어보고 편집할 수 있습니다.

---

## 참고 링크

- 공식 저장소: https://github.com/oraios/serena