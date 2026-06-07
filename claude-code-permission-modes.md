# Claude Code 권한 모드 정리

Claude Code가 파일 편집·명령 실행 등을 할 때 매번 확인을 받을지, 자동으로 승인할지를 제어하는 방법을 정리한 매뉴얼입니다.

> 플래그 이름, 설정 파일 키 구조, 모드 순환 동작 등 세부 사항은 버전에 따라 달라질 수 있습니다. 최신 기준은 공식 문서를 확인하세요.
> Claude Code 문서: https://docs.claude.com/en/docs/claude-code/overview

---

## 권한 모드 한눈에 보기

| 방식 | 자동 승인 범위 | 위험도 | 적합한 상황 |
| --- | --- | --- | --- |
| 일반 모드 (기본) | 없음 (매번 확인) | 낮음 | 민감하거나 되돌리기 어려운 작업 |
| auto mode (`Shift+Tab`) | 편집 등 자동 수락 | 중간 | 반복 편집이 많은 일반 개발 작업 |
| `settings.json` allow 규칙 | 지정한 도구·명령만 | 중간 (세밀 제어) | 안전한 명령만 골라 자동화 |
| `--dangerously-skip-permissions` | 전부 | 높음 | 격리된 일회용 환경 전용 |

---

## 1. 세션 중 모드 전환 — `Shift+Tab` (권장)

Claude Code 세션 안에서 **`Shift+Tab`** 을 누르면 권한 모드가 순환합니다. 현재 모드는 입력창 아래 상태 표시줄에 나타납니다.

```
⏵⏵ auto mode on (shift+tab to cycle) · ← for agents · option+click to native select
```

- `⏵⏵ auto mode on` — 현재 auto mode 활성 상태. 파일 편집 등을 매번 확인 없이 자동 수락합니다.
- `shift+tab to cycle` — 다시 누르면 다음 모드로 순환. 자동 수락을 끄려면 순환시켜 일반(매번 확인) 모드로 돌아옵니다.

함께 표시되는 다른 안내(권한과 무관):

- `← for agents` — 해당 키로 에이전트(서브 작업 위임) 기능 진입.
- `option+click to native select` — Option 키를 누른 채 클릭하면 터미널 기본 텍스트 선택(복사용)이 됩니다.

> auto mode에서 자동 수락되는 범위(편집만인지, 명령 실행까지인지)는 버전에 따라 다를 수 있습니다. `sudo`가 걸린 시스템 명령처럼 되돌리기 어려운 작업 구간에서는 일반 모드로 돌려두는 것이 안전합니다.

---

## 2. 설정 파일에 허용 규칙 지정 — `settings.json` (가장 세밀)

프로젝트 또는 사용자 설정의 `settings.json`에서 `permissions`의 `allow` / `deny` 목록으로 특정 도구나 명령 패턴을 자동 허용/거부할 수 있습니다. 안전한 명령은 자동 승인하고 나머지는 계속 묻게 하는 식의 세밀한 제어가 가능합니다.

대략적인 형태(키 구조는 버전에 따라 다를 수 있으니 문서로 확인):

```json
{
"permissions": {
"allow": [
"Bash(npm run *)",
"Edit"
 ],
"deny": [
"Bash(sudo *)"
 ]
 }
}
```

- `allow` — 매번 묻지 않고 자동 허용할 도구/명령 패턴.
- `deny` — 항상 차단할 패턴. 시스템을 건드리는 위험 명령을 여기 넣어두면 실수를 방지할 수 있습니다.

---

## 3. 전체 자동 승인 — `--dangerously-skip-permissions` (위험)

```bash
claude --dangerously-skip-permissions
```

파일 편집·명령 실행 등 모든 동작을 확인 없이 자동 진행합니다. 이름 그대로 위험하므로 **신뢰할 수 있는 격리 환경(컨테이너, 일회용 VM 등)에서만** 사용하세요.

방화벽·시스템 설정 등 민감한 작업이 섞인 실제 작업 머신에서는 권장하지 않습니다.

---

## 권장 사용 가이드

- **일반 개발 작업**: 세션 중 `Shift+Tab`으로 auto mode를 켜서 편집을 자동 수락 → 반복 작업이 빨라집니다.
- **시스템·보안 작업** (pf 방화벽, LaunchDaemon, `sudo` 명령 등): 일반 모드로 두고 매번 확인하거나, `settings.json`의 `deny`에 위험 명령을 넣어 방어막을 둡니다.
- **격리된 실험 환경**: 필요하면 `--dangerously-skip-permissions`로 마찰 없이 진행.

---

## 빠른 참조

| 하고 싶은 것 | 방법 |
| --- | --- |
| 자동 수락 켜기/끄기 | 세션 중 `Shift+Tab` 순환 |
| 현재 모드 확인 | 입력창 아래 상태 표시줄 (`⏵⏵ auto mode on` 등) |
| 특정 명령만 자동 허용 | `settings.json` → `permissions.allow` |
| 특정 명령 항상 차단 | `settings.json` → `permissions.deny` |
| 전부 자동 (격리 환경) | `claude --dangerously-skip-permissions` |

> 최신 동작과 정확한 설정 키는 공식 문서에서 확인하세요: https://docs.claude.com/en/docs/claude-code/overview