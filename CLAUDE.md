# 겹(Gyeop) — 공용 세션 규칙

모든 개발 세션이 시작 시 자동으로 읽는 규칙이다. 여기 적힌 결정은 재논의 없이 따른다.
제품이 무엇인지는 `gyeop-spec.md`(문제 정의·해결 원칙·F1~F8), 범위는 `implementation-scope.md`를 본다.

## 정렬 스프린트 가드레일 (2026-08)
- 기획의 단일 진실 원천은 docs/다. docs와 코드가 다르면 docs가 맞다.
  기획 변경은 docs 갱신 → 세션 재시작 순서로만 반영한다.
- 반영 범위: 재성 1차 피드백까지. 보안 구조 변경(존 피드백 대비)은
  이번 스프린트 범위 밖 — 발견한 보안 이슈는 코드 수정 없이
  docs/security-backlog.md에 기록만 한다.
- 디자인 시각 이탈 금지: DesignSystem 토큰의 기존 값 변경 금지,
  새 색상·폰트·코너·그림자 도입 금지. 화면 내 콘텐츠 구성 변화와
  카피 교체만 허용. 시각 기준은 docs/gyeop-prototype.html이다.
- 프로토타입에 없는 화면·구성이 필요해지면: 구현하지 말고
  review/proposals/<화면명>.html로 제안을 만든 뒤 멈추고 보고한다.
- 내비게이션은 docs/navigation-map.md 배선표와 1:1. 배선표에 없는
  전환 추가 금지 (필요 시 배선표 수정을 먼저 제안).

## 기술 결정 (변경 금지)

- **UI: SwiftUI 100%.** UIKit 래핑은 시스템이 SwiftUI API를 제공하지 않을 때만, 해당 세션 소유 패키지 안에서만.
- **Swift 6 strict concurrency.** 전 모듈 `SwiftLanguageMode(.v6)`. `@unchecked Sendable`은 금지 — 필요하면 actor로 풀어라.
- **아키텍처: MVVM + `@Observable`.** ViewModel은 `@Observable` 클래스(@MainActor), View는 상태 없는 함수형. UseCase/도메인 로직은 Core의 프로토콜 뒤에.
- **저장: SwiftData** (+ 이후 서버 동기화 큐). 도메인은 Firebase를 모른다 — 전부 `GyeopRepository` 등 Core 프로토콜 경계 뒤에 격리.
- **에러는 최종 호출부에서만 catch.** 중간 계층은 `throws`로 전파만 한다. 삼킨 에러(`try?` 남발)는 리뷰에서 반려.
- **로깅: OSLog만.** `print` 금지. `Core/Telemetry.swift`의 `Log.*` 카테고리와 `Signpost`/`MetricCounter`를 쓴다. 새 측정 구간이 필요하면 Telemetry.swift에 키를 추가하고 쓴다.

## UI 원칙

- **유동적 무드 (2026-08-08 소유자 지시, `docs/design-decisions.md` §1차 시연 피드백 라운드).**
  모든 전환·모션은 스무스하고 물 흐르듯 — bold·strict한 연출 금지. U2의 모션 타이밍
  동결은 해제됐다. 사용자 노출 카피에 em-dash(—) 금지.
- **첫 화면(WelcomeView) 시각 디자인은 소유자가 Figma로 작업 중** — 확정 전까지 코드
  세션은 웰컴 화면의 시각을 바꾸지 않는다.
- **HIG + 시스템 컴포넌트만.** List, Form, NavigationStack, TabView 등 시스템 것을 먼저. **커스텀 비주얼이 허용되는 곳은 정체성 카드뿐이다** (CardKit 내부).
- **모든 색·폰트·간격은 DesignSystem 토큰 참조.** 뷰 코드에 리터럴(`Color(red:...)`, `.padding(13)`, `.font(.system(size: 17))`) 직접 쓰기 금지. 필요한 토큰이 없으면 DesignSystem에 토큰을 추가하고 참조한다.
- **Dynamic Type 대응** — 고정 폰트 크기 금지, 레이아웃은 텍스트 확대에도 깨지지 않아야 한다.
- **터치 타깃 최소 44pt.**
- **접근성 레이블** — 이모지·아이콘·카드 등 비텍스트 요소에는 `accessibilityLabel` 필수.

## 사이클 규칙

- **빌드 통과 상태로만 커밋한다.** 커밋 전 `xcodebuild build`(App 스킴) + `swift test`(Packages/GyeopPackages) 둘 다 통과 확인.
- **시뮬레이터 확인: iPhone 17 Pro (iOS 26.5).** (원래 기준은 iPhone 16 Pro였으나 이 Mac에 런타임이 없어 iPhone 17 Pro로 대체 — 새 런타임 설치 시 이 줄을 갱신하라.)
- **실기기가 필요한 항목은 코드에 섞지 말고 목록으로 분리한다** — `docs/device-required.md`에 추가하고, 시뮬레이터에서는 Mock 경로로 동작하게 한다. (예: MultipeerConnectivity, NearbyInteraction UWB, 푸시, Live Activity 원격 갱신)

## 소유권 규칙 (병렬 세션 충돌 방지)

- **`project.yml`·`Gyeop.xcodeproj`·App 타깃(App/ 디렉토리)은 S1/S6 세션만 수정한다.** 다른 세션은 절대 건드리지 않는다. pbxproj는 xcodegen 산출물이므로 직접 수정 금지 — `project.yml` 수정 후 `xcodegen generate`.
- **각 세션은 자기 패키지 디렉토리만 수정한다.** 패키지 경계:
  - `Packages/GyeopPackages/Sources/Core` — 계약(프로토콜·모델·Telemetry). **계약 변경은 반드시 관련 세션 합의 후** (사실상 S1이 중재).
  - `Packages/GyeopPackages/Sources/DesignSystem` — 토큰·공용 컴포넌트
  - `Packages/GyeopPackages/Sources/CardKit` — 카드 생성·렌더(셰이더)
  - `Packages/GyeopPackages/Sources/GyeopKit` — MPC·UWB 교환
  - `Packages/GyeopPackages/Sources/DataKit` — SwiftData·동기화·리포지토리 구현
- 다른 패키지의 것이 필요하면 **Core에 프로토콜을 추가**하고 자기 쪽에서 Mock으로 개발한다. 구현 연결은 App(조립 지점)에서 S1/S6이 한다.
- `Package.swift`에 타깃/의존성 추가가 필요하면 자기 타깃 블록만 수정한다.

## 빌드·테스트 명령

```bash
# 프로젝트 재생성 (project.yml 수정 후, S1/S6만)
xcodegen generate

# 앱 빌드
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# 패키지 전체 테스트 (Swift Testing)
cd Packages/GyeopPackages && swift test
```
