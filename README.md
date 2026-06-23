# Timer for Terry

Focus-To-Do 스타일의 포모도로 타이머를 **작은 플로팅 창**으로 만든 macOS 네이티브 앱.
Focus-To-Do의 측정 화면이 너무 커서, 화면 한쪽에 살짝 떠있는 미니멀한 위젯으로 다시 만들었습니다.

## 특징

- **작은 플로팅 창** — 항상 위에 떠있고, 배경을 드래그해서 원하는 위치로 이동
- **포모도로** — 집중 → 휴식 → (N회마다) 긴 휴식 자동 전환, 종료 시 알림음
- **커스텀 시간** — 집중/휴식/긴 휴식 길이, 긴 휴식까지의 횟수를 설정에서 조정
- **통계/기록** — 오늘·이번 주 집중 시간, 누적 세션 수, 최근 7일 막대그래프
- **Dock 앱** — Dock 아이콘으로 실행/종료, ⌘Q 지원
- **닫기(×)** — 창을 닫아도 타이머는 Dock에서 계속 동작, Dock 아이콘 클릭으로 다시 열기

## 요구사항

- **Apple Silicon Mac** (M1 이상), macOS 14 이상
- **Xcode Command Line Tools** — Swift 컴파일러가 필요합니다. 없다면:
  ```bash
  xcode-select --install
  ```

> 코드 서명이 안 된 앱이라 배포된 `.app`을 그냥 받는 대신, **각자 소스에서 직접 빌드**하는 방식입니다.
> 직접 빌드하면 Gatekeeper 경고 없이 바로 실행됩니다.

## 빌드 & 설치

```bash
git clone <이 저장소 주소>
cd timer-for-terry
./build-app.sh
```

`~/Applications/TimerForTerry.app` 에 설치됩니다. 실행:

```bash
open ~/Applications/TimerForTerry.app
```

개발 중 빠른 실행 (번들 없이 바로):

```bash
swift run -c release
```

설치 후 **Dock에 고정**하려면, 실행된 상태에서 Dock 아이콘을 우클릭 → "옵션 → Dock에 유지"를 선택하세요.

## 사용법

- ▶ / ⏸ : 시작 / 일시정지
- ↺ : 현재 단계 리셋
- 📊 : 통계 보기
- ⚙ : 설정 (시간 조정 · 스크롤로 값 조절 · **건너뛰기** · **종료**)
- ✕ (좌측 상단) : 창 닫기 → Dock 아이콘 클릭으로 다시 열기
- ⌘Q : 완전 종료
- 창 **배경을 드래그**하면 위치 이동

## 구조

| 파일 | 역할 |
|------|------|
| `Sources/TimerForTerry/main.swift` | 앱 진입점 · 플로팅 패널(`NSPanel`) 구성 |
| `Sources/TimerForTerry/Model.swift` | 포모도로 로직 · 통계 저장(`UserDefaults`) |
| `Sources/TimerForTerry/Views.swift` | 타이머 UI · 통계/설정 팝오버 |

설정과 통계는 `UserDefaults`에 저장되어 재실행해도 유지됩니다.
