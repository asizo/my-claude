# Claude Code 플러그인 설치 매뉴얼

Docker 컨테이너에서 Claude Code 실행 시 매번 수행하는 플러그인 설치 절차입니다.

---

## 설치할 플러그인

| 플러그인 | 마켓플레이스 |
|----------|-------------|
| `everything-claude-code` | https://github.com/affaan-m/everything-claude-code |
| `claude-hud` | https://github.com/jarrodwatts/claude-hud |

---

## 설치 순서

### Step 1. Claude Code 실행

```bash
claude
```

### Step 2. 마켓플레이스 등록

Claude Code 프롬프트에서 아래 3개를 순서대로 입력합니다.

```
/plugin marketplace add https://github.com/affaan-m/everything-claude-code
```
```
/plugin marketplace add https://github.com/jarrodwatts/claude-hud
```

각각 `Successfully added marketplace: ...` 메시지가 뜨면 정상입니다.

### Step 3. 플러그인 설치

```
/plugin install everything-claude-code@everything-claude-code
```

> ⚠️ 설치 화면(TUI)이 뜨면 **방향키**로 `Install for you (user scope)` 선택 후 **Enter**
> 
> `✓ Installed everything-claude-code. Run /reload-plugins to apply.` 메시지가 나올 때까지 반복 실행이 필요할 수 있습니다.

```
/plugin install claude-hud@claude-hud
```
```
/plugin install claude-mem@thedotmack
```

> 이미 설치된 경우 `Plugin '...' is already installed globally.` 메시지가 뜨며 정상입니다.

### Step 4. 플러그인 로드

```
/reload-plugins
```

정상 로드 시 아래와 같이 출력됩니다.

```
Reloaded: 2 plugins · 81 skills · 43 agents · 35 hooks · 7 plugin MCP servers · 0 plugin LSP servers
```

### Step 5. 상태 확인

```
/doctor
```

아래 1개 오류는 무시해도 됩니다 (제거한 플러그인의 잔여 기록):

```
backend-development@claude-code-workflows: Plugin backend-development not found in marketplace claude-code-workflows
```

이 오류를 완전히 제거하려면:

```
/plugin uninstall backend-development@claude-code-workflows
/reload-plugins
```

---

## 설치 완료 확인

`/reload-plugins` 결과에서 다음을 확인합니다.

- `2 plugins` — 플러그인 2개 로드됨
- `0 errors` 또는 `backend-development` 관련 1개만 — 정상

---

## 참고

- `everything-claude-code` rules는 플러그인으로 자동 설치되지 않습니다. 필요 시 수동 설치:

```bash
git clone https://github.com/affaan-m/everything-claude-code.git
cd everything-claude-code
npm install
./install.sh --profile full
```

- Claude Code 공식 문서: https://docs.claude.com/en/docs/claude-code/overview
