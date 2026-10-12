# Claude Code 3모델 구성

메인·어드바이저는 Opus 5.5, 탐색(Explore)·실행(runner) 서브에이전트는 Haiku 5.5를 쓰는 사용자 범위 설정이에요.

## 설치 (내 컴퓨터에서)

1. `~/.claude/settings.json`이 없으면 `settings.json`을 그대로 복사해요. 있으면 `"model"`, `"advisorModel"` 두 키만 더해요.
2. `agents/` 안의 두 파일을 `~/.claude/agents/`에 복사해요. 같은 이름의 파일이 있으면 먼저 비교해요.
3. `CLAUDE.md`의 두 절을 `~/.claude/CLAUDE.md` 끝에 더해요.

`omitClaudeMd`는 Claude Code v2.1.271 이상에서 동작해요.
