# agents/ — 서브에이전트 정의

메인 컨텍스트를 보호하기 위해 넓은 탐색·조사를 **읽기 전용 서브에이전트**에게 위임하고 요약 결과만 받는다. Claude Code가 `~/.claude/agents/*.md` 중 **YAML frontmatter가 있는 파일**을 스캔해 서브에이전트로 등록한다.

> 이 `README.md`는 frontmatter(`name`/`description`)가 없어 Claude Code 서브에이전트 스캐너가 **조용히 무시**한다(문서 전용, 런타임 영향 없음).

## 파일 목록

| 파일 | name | 용도 |
|---|---|---|
| `codebase-investigator.md` | codebase-investigator | 다수 파일/모듈에 걸친 로직·호출 체인 추적 → 구조화 리포트 + Red Flag |
| `cross-project-researcher.md` | cross-project-researcher | 연관 프로젝트(프론트↔백) 코드 대조로 스펙 불일치 사전 방지 |
| `git-history-researcher.md` | git-history-researcher | 특정 파일/함수의 변경 이력·버그 도입 시점 역추적 |
| `log-analyzer.md` | log-analyzer | 대용량 로그에서 에러 시그널 추출 · 근본 원인 가설 |

## frontmatter 형식

```yaml
---
name: <고유 식별자 — 파일명과 일치 권장>
description: <언제 위임할지 — 자동 위임 판단 근거>
model: sonnet                   # 선택
tools: Read, Glob, Grep, Bash   # 선택 — 미지정 시 전체 상속
---
```

`name`·`description`은 필수. 누락 시 해당 파일은 등록되지 않는다.

## 공통 규칙

- **읽기 전용**: 파일 수정·커밋·상태 변경 금지(프롬프트로 강제).
- **민감정보 마스킹**: 토큰/키/비밀번호 발견 시 `[REDACTED]`.
- **한국어 응답**, 추측 금지(코드/로그/이력에 실제로 있는 내용만).
- **불확실성 명시**: 숨기지 말고 "메인 검증 요청(Red Flag)"으로 드러낸다.

## 호출 방법

`Agent`(또는 `Task`) 도구의 `subagent_type`에 name을 지정하거나, 메인 에이전트가 작업 성격에 따라 자동 위임한다. 위임 절제 원칙(반사적 위임 금지)은 `rules/workflow.md` §2 참조.
