# 디자인 토큰 결정 기록

`DesignSystem/Tokens.swift`에 반영된 결정과 그 근거. HIG·시스템 관습을 우선 검토하고,
필요성이 확인된 것만 토큰으로 추가했다(YAGNI — 안 쓰는 토큰은 미리 만들지 않는다).

| # | 항목 | 결정 | 근거 |
|---|---|---|---|
| 1 | 앱 액센트 컬러 | `Palette.accent = .indigo` (기존 유지) | 시스템 시맨틱 컬러라 다크모드 자동 대응. "겹의 보라" 브랜드 은유와 정합. 카드 배경(MeshGradient)의 시드 기반 제너러티브 색과는 무관한, 카드 '밖' UI(버튼·탭바·링크)용 색. |
| 2 | 상태 시맨틱 컬러 | `Palette.success = accent`, `Palette.pending = secondaryText`, `Palette.failure = secondaryText` | 표준 HIG는 성공=녹색·경고=주황·실패=빨강이지만, 겹의 해결원칙 2("거절이 성립하지 않는 구조")상 연결 실패·타임아웃을 경고색으로 담지 않는다. 성사만 액센트로 축하하고 대기·실패는 중립. |
| 3 | Typography 확장 | `Typo.subheadline`, `Typo.footnote` 추가 | F3 신호 피드 등에서 제목 아래 정보 위계(핵심 보조정보 / 타임스탬프)가 필요. 표준 iOS 텍스트 스타일 매핑이라 Dynamic Type 자동 대응. 카테고리 아이콘·매치 표시 등 컴포넌트 레벨 디자인(이모지→SF Symbol, Liquid Glass 틴트 등)은 Figma에서 직접 다루기로 하고 보류. |
| 4 | D-day 숫자 스타일 | `Typo.counter = .system(.title, design: .rounded).weight(.heavy).monospacedDigit()` | D-day는 홈·위젯·잠금화면에 상시 노출되는 핵심 숫자. Weather/Fitness/Screen Time처럼 Rounded 디자인으로 "따뜻한 카운터" 느낌을 주고, monospacedDigit으로 자릿수 변화(D-183→D-9) 시 레이아웃이 흔들리지 않게 한다. |
| 5 | Radius 확장(버튼·시트) | 추가 안 함 | 시스템 버튼(.borderedProminent 등)은 기본이 캡슐 — iOS 26 Liquid Glass 툴바도 동일 관습. 시트 상단 코너도 시스템이 자동 처리. 커스텀 컨트롤이 실제로 필요해지면 그때 추가. |
| 6 | Spacing 확장(xxs) | 추가 안 함 | 현재 최소값 `xs = 4pt`와 가상 2pt를 나란히 비교했을 때 실사용 차이가 미미했고, 칩 사이 간격은 오히려 4pt가 더 명확히 분리됨. |
| 7 | Motion 프리셋 | `Motion.standard`(response 0.35 / damping 0.8), `Motion.quick`(response 0.2 / damping 0.9) | 카드 도착·매칭 성사(F2/F5)처럼 "축하할 만한" 전환엔 standard의 튕김이, 버튼·토글처럼 잦고 가벼운 반응엔 quick이 맞다 — 하나만 두면 한쪽 맥락에서 항상 어색해진다. 시스템 시트·탭 전환과 같은 계열의 스프링이라 이질감이 없다. Reduce Motion 대응은 호출부에서 `accessibilityReduceMotion` 확인 후 대체. |
| 8 | Disabled Opacity | `Opacity.disabled = 0.4` | 시스템 컨트롤은 `.disabled(true)`에서 자동으로 흐려져 토큰이 필요 없지만, 커스텀 합성 뷰(FlowingChips 등)는 `.disabled()`가 상호작용만 막고 겉모습은 그대로라 직접 흐려줘야 한다. 0.4는 iOS 표준 disabled 버튼 체감과 가장 가까운 값.

## 보류된 항목

F3 신호 피드 행의 컴포넌트 디자인(카테고리 아이콘, "관심사 겹침" 매치 표시)은 세션 중
이모지 → SF Symbol → Liquid Glass 틴트 순으로 반복 검토했으나, 최종 형태는 Figma에서
직접 다루기로 하고 이번 토큰 결정에서는 제외했다. `Typo.subheadline`/`Typo.footnote`
텍스트 위계만 토큰으로 확정.
