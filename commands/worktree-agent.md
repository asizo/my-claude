git worktree로 agent 작업을 격리해 충돌을 방지합니다 — 병렬 mutation·큰 리팩토링·실험적 변경에 `isolation: 'worktree'` 적용 시점·방법·머지 절차 가이드.

이 커맨드는 **사용자가 명시적으로 호출**할 때 적용한다(자동 적용 아님). 여러 agent가 같은 코드베이스를 동시에 mutate하거나, 단일 agent에게 큰 변경을 맡길 때 메인 워킹 트리와 분리해 안전하게 작업한다.

## 적용 대상 (요청된 작업이 아래에 해당하면 isolation 적용)

- 여러 agent가 동시에 같은 파일/디렉토리를 수정할 가능성이 있는 작업
- 큰 리팩토링 (수십 파일 이상), 마이그레이션, 실험적 변경
- 메인 브랜치와 분리해 검증 후 머지하고 싶은 작업

## Skip Conditions (호출돼도 격리 안 함 — 일반 실행으로 폴백)

비용 대비 효과가 낮으면 worktree 미적용:

- **read-only 분석**: Explore agent, 코드 검색, 영향도 조사
- **단일 agent · 작은 변경**: 한 함수 수정, 한 줄 버그 수정
- **단일 파일 작업**: 충돌 가능성 자체가 없음
- **세션 내 즉시 검증이 필요한 변경**: worktree 생성·정리 오버헤드가 더 큼

## 판단 트리

```
요청 분석
   │
   ├─ read-only 인가? ──── Yes ──→ 미적용
   │       │
   │       No
   │       ↓
   ├─ 단일 agent · 작은 변경 인가? ──── Yes ──→ 미적용
   │       │
   │       No
   │       ↓
   ├─ 여러 agent · 동시 mutation 가능성 있나? ──── Yes ──→ ✅ isolation: 'worktree'
   │       │
   │       No
   │       ↓
   ├─ 큰 리팩토링 · 실험적 변경 · 메인과 분리 필요? ──── Yes ──→ ✅ isolation: 'worktree'
   │       │
   │       No
   │       ↓
   └─ 모호 ──→ 사용자에게 1줄 확인 ("이 작업 격리해서 진행할까요?")
```

## 실행 패턴

### 단일 Agent (큰 작업 격리)

```typescript
Agent({
  description: "<작업 요약>",
  subagent_type: "general-purpose",   // 또는 적합한 agent 유형
  prompt: "<상세 지시>",
  isolation: "worktree"               // 핵심
})
```

→ 임시 git worktree + 별도 브랜치에서 agent가 작업.
→ 변경 없으면 worktree 자동 정리. 변경 있으면 worktree 경로·브랜치명이 결과에 포함됨.

### 병렬 Agents (Workflow 사용)

```typescript
Workflow({
  script: `
    export const meta = {
      name: 'parallel-refactor',
      description: '같은 영역을 동시에 mutate하는 병렬 작업',
      phases: [{ title: 'Refactor', detail: 'isolation per agent' }],
    }

    phase('Refactor')
    const results = await parallel(
      items.map(item => () =>
        agent(\`refactor: \${item.name}\`, {
          isolation: 'worktree',     // 각 agent가 별도 worktree
          schema: RESULT_SCHEMA,
        })
      )
    )
  `
})
```

→ 각 agent가 독립 worktree에서 실행. OS 레벨 파일 충돌 발생 불가.

## 비용 및 동작

| 항목 | 값 |
|---|---|
| worktree 생성 오버헤드 | ~200-500ms + 디스크 공간 |
| 변경 없을 시 정리 | 자동 (commit 없이 종료 시 폴더 삭제) |
| 변경 있을 시 반환값 | `{ worktreePath, branchName, ... }` |
| 같은 파일 동시 수정 시 | OS 충돌 없음 (각자 다른 디렉토리) |
| 머지 시점 충돌 | 가능 (사용자가 해결) |

## 머지 처리 절차

agent들이 작업을 끝낸 후:

1. **각 worktree 경로·브랜치 확인**: agent 결과에서 반환된 경로·브랜치명 수집
2. **변경 사항 검토**: `git diff main..<agent-branch>` 등으로 사용자가 확인
3. **머지 또는 폐기 결정**:
   - 머지: `git checkout main && git merge <agent-branch>`
   - 폐기: `git worktree remove <path> && git branch -D <branch>`
4. **충돌 발생 시**: 사용자가 직접 해결 (agent에게 위임하지 않음 — 정책적 판단 영역)
5. **검증**: 머지 후 lint / typecheck / 빌드로 정합성 확인

## 명령 예시 (수동 worktree)

이 커맨드는 `isolation` 파라미터로 자동 처리하지만, 수동 운용이 필요할 때 참고:

```bash
# worktree 추가
git worktree add ../<project>-feature feature-branch

# 목록 확인
git worktree list

# worktree 제거 (브랜치는 따로 정리)
git worktree remove ../<project>-feature
git branch -D feature-branch   # 필요 시
```

## 운용 원칙

1. **항상 worktree가 아니다**: 비용 대비 효과를 판단해 적용. 위 "Skip Conditions"를 우선 검토.
2. **사용자 결정 영역 존중**: 자동 머지·자동 충돌 해결은 금지. agent는 작업까지, 머지·검증은 사람.
3. **결과 추적성**: 모든 격리 작업의 worktree 경로·브랜치명을 사용자에게 명시적으로 보고.
4. **워크트리 누적 방지**: 작업 완료 또는 폐기 시점에 정리. `git worktree list`로 정기 점검.
5. **글로벌 가이드 일관성**: `~/.claude/CLAUDE.md`의 승인 게이트(DB 쓰기·운영 변경 등)는 worktree 안에서도 동일 적용.

## 관련 도구

- **`Agent` 도구**: `isolation: 'worktree'` 파라미터로 단일 호출 격리
- **`Workflow` 도구**: 스크립트 내 `agent(..., { isolation: 'worktree' })` 로 병렬 격리
- **Bash + `git worktree`**: 수동 운용 (직접 워크트리 추가·정리)
- **`git-workflow` skill**: 일반 git 워크플로우 (브랜치 전략·머지 정책) — 보완재
