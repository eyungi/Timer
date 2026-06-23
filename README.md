# Timer

Focus-To-Do 스타일의 포모도로 타이머를 **작은 플로팅 창**으로 만든 macOS 네이티브 앱.
Focus-To-Do의 측정 화면이 너무 커서, 화면 한쪽에 살짝 떠있는 미니멀한 위젯으로 다시 만들었습니다.

## 특징

- **작은 플로팅 창** — 항상 위에 떠있고, 배경을 드래그해서 원하는 위치로 이동
- **포모도로** — 집중 → 휴식 → (N회마다) 긴 휴식 자동 전환, 종료 시 알림음
- **커스텀 시간** — 집중/휴식/긴 휴식 길이, 긴 휴식까지의 횟수를 설정에서 조정
- **통계/기록** — 오늘·이번 주 집중 시간, 누적 세션 수, 최근 7일 막대그래프
- **Dock 앱** — Dock 아이콘으로 실행/종료, ⌘Q 지원
- **닫기(×)** — 창을 닫아도 타이머는 Dock에서 계속 동작, Dock 아이콘 클릭으로 다시 열기

## 설치하기

이 앱은 코드 서명이 안 되어 있어, 만들어진 파일을 받는 대신 **각자 소스에서 직접 빌드**합니다.
직접 빌드하면 "확인되지 않은 개발자" 같은 Gatekeeper 경고 없이 바로 실행됩니다.

### 1. 요구사항

- **Apple Silicon Mac** (M1 이상), **macOS 14 이상**
- **Xcode Command Line Tools** (Swift 컴파일러). 설치 여부는 아래로 확인:
  ```bash
  swift --version
  ```
  `command not found`가 나오면 설치:
  ```bash
  xcode-select --install
  ```

### 2. 내려받아 빌드

```bash
git clone https://github.com/<아이디>/timer.git
cd timer
./build-app.sh
```

빌드가 끝나면 `~/Applications/Timer.app` 에 자동 설치됩니다.
(`Permission denied`가 나면 `chmod +x build-app.sh` 후 다시 실행)

### 3. 실행 & Dock 고정

```bash
open ~/Applications/Timer.app
```

- 실행하면 화면 우측 상단에 작은 타이머 창이 뜹니다.
- **Dock에 계속 두려면**: 실행 중에 Dock 아이콘 우클릭 → **옵션 → Dock에 유지**.
- 로그인 시 자동 실행하려면: 시스템 설정 → 일반 → 로그인 항목 → `+` 로 추가.

> 빌드 없이 한 번만 실행해보려면 `swift run -c release` 도 됩니다(번들/아이콘 없음).

## 사용법

- ▶ / ⏸ : 시작 / 일시정지
- ↺ : 현재 단계 리셋
- 📊 : 통계 보기 (오늘·이번 주·최근 7일)
- ⚙ : 설정 — 집중/휴식 시간 조정(**숫자 위에서 스크롤** 또는 +/− 버튼) · **건너뛰기** · **종료**
- ✕ (좌측 상단) : 창 닫기 → Dock 아이콘 클릭으로 다시 열기
- ⌘Q : 완전 종료
- 창 **배경을 드래그**하면 위치 이동

## 문제 해결

| 증상 | 해결 |
|------|------|
| `swift: command not found` | `xcode-select --install` 로 Command Line Tools 설치 |
| `./build-app.sh: Permission denied` | `chmod +x build-app.sh` 후 다시 실행 |
| 창이 안 보임 | 다른 모니터/화면 가장자리 확인. Dock 아이콘을 클릭하면 다시 앞으로 나옵니다 |
| 설정/통계 초기화하고 싶음 | `defaults delete com.timer.app` 실행 |
| 업데이트(최신 코드 반영) | `git pull` 후 `./build-app.sh` 다시 실행 |

## 구조

| 파일 | 역할 |
|------|------|
| `Sources/Timer/main.swift` | 앱 진입점 · 플로팅 패널(`NSPanel`) 구성 |
| `Sources/Timer/Model.swift` | 포모도로 로직 · 통계 저장(`UserDefaults`) |
| `Sources/Timer/Views.swift` | 타이머 UI · 통계/설정 팝오버 |

설정과 통계는 `UserDefaults`에 저장되어 재실행해도 유지됩니다.
