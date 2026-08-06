# 겹 — 구현 경험 체크리스트 (공식문서 뜯어보기 방식)

applecider2020의 "영문 공식문서 뜯어보기" 시리즈처럼, **공식문서 → 직접 구현 → 글감**의 단위로 겹(`gyeop-spec.md`)에서 내가 구현할 것들을 나열한다. 원칙은 하나: **여기 있는 모든 항목은 앱의 실제 기능이다.** 예제 프로젝트로 연습하는 게 아니라, 겹의 기능을 구현하다 보면 경험이 쌓이는 순서로 배치했다.

각 항목 형식:
- ☐ **구현할 것** — 겹의 어느 기능인지
- 📄 뜯어볼 공식문서/WWDC
- 💬 남는 경험 (면접·블로그에서 말할 한 줄)
- 🔗 applecider2020 시리즈에 같은 주제가 있으면 표시 (15개 글 중 해당 번호)

---

## A. 만남 인증 — P2P (스프린트 S2)

### A1. MultipeerConnectivity — 피어 발견과 카드 전송
- ☐ `MCNearbyServiceAdvertiser`/`Browser`로 주변 러너 발견, `MCSession`으로 카드 데이터(JSON) 전송
- ☐ 발견→초대→수락→전송의 상태 머신을 enum으로 설계, 각 단계 타임아웃 처리
- 📄 Multipeer Connectivity Framework, WWDC 2013 "Nearby Networking with Multipeer Connectivity"
- 💬 "서버 없이 두 기기가 카드를 교환합니다 — 발견부터 전송까지 상태 머신으로 설계했고, 와이파이가 죽어도 동작합니다"

### A2. NearbyInteraction — UWB 거리·방향으로 '맞대기' 판정
- ☐ discovery token을 MPC 채널로 교환 → `NISession` 수립 → 30cm 이내 접근 시 교환 트리거
- ☐ 거리 이벤트를 `AsyncStream`으로 래핑해 뷰모델에서 `for await` 소비
- ☐ U1 미지원 기기 폴백: MPC 발견 + 양측 확인 버튼 (기능 저하를 UX로 흡수)
- 📄 NearbyInteraction, WWDC 2020 "Meet Nearby Interaction", WWDC 2022 "What's new in Nearby Interaction"
- 💬 "delegate 콜백을 AsyncStream으로 감싸 구조화 동시성 세계로 가져오는 패턴을 직접 만들었습니다"

### A3. CoreHaptics — 교환 순간의 촉각 연출
- ☐ 맞대기 성공 시 커스텀 햅틱 패턴(`CHHapticPattern`) + 사운드 동기 재생
- 📄 Core Haptics, WWDC 2019 "Introducing Core Haptics"
- 💬 "성공의 순간을 손끝으로 알게 하는 게 이 앱의 브랜드 모먼트라서, 시스템 햅틱이 아닌 커스텀 패턴을 설계했습니다"

## B. 알림·실시간 — 서버가 앱 밖까지 (스프린트 S3~S4)

### B1. UserNotifications + APNs — 신호 푸시 파이프라인 🔗 #2
- ☐ `requestAuthorization`(provisional 검토), device token 등록·서버 전달, 포그라운드/백그라운드 수신 분기
- ☐ `UNNotificationCategory`로 액션 버튼("조인", "오늘은 패스") — 앱 안 열고 조인
- ☐ FCM 경유가 아닌 **APNs 직접 호출**(p8 token auth)을 Cloud Functions에서 구현해 파이프라인 전체를 이해
- 📄 UserNotifications, "Sending notification requests to APNs", "Establishing a token-based connection to APNs"
- 💬 "FCM이 가려주는 부분(p8 인증, payload, token 수명)을 직접 구현해서 푸시가 도착하기까지 전 구간을 설명할 수 있습니다"

### B2. HIG Notifications — 문구·액션 설계 🔗 #3
- ☐ 신호 푸시의 title/body를 HIG 기준으로 설계: 간결, 개인정보 미노출(닉네임만), destructive 액션 금지
- ☐ 야간 무음 정책(오후 11시~오전 8시 로컬 억제) — 알림 피로가 곧 삭제라는 전제
- 📄 HIG > Notifications
- 💬 "알림은 기능이 아니라 예의라서, HIG 기준으로 문구·액션·시간대를 설계했습니다"

### B3. ActivityKit — Live Activity를 푸시로 갱신
- ☐ 신호 참여자의 잠금화면·Dynamic Island에 "보드게임 19:00 · 3/4" 실시간 표시
- ☐ push token 기반 원격 갱신 + stale date로 자동 소멸 (휘발성 신호의 수명 = Live Activity 수명)
- 📄 ActivityKit, "Updating Live Activities with push notifications", WWDC 2023 "Update Live Activities with push notifications"
- 💬 "앱이 종료돼 있어도 잠금화면의 신호가 서버 푸시로 갱신됩니다 — 갱신 빈도 제한과 콘텐츠 크기 제약 안에서 정보 설계를 했습니다"

### B4. WidgetKit — D-day·겹 위젯 🔗 #3(HIG 연장)
- ☐ 홈/잠금화면 액세서리 위젯: "D-183 · 이번 주 겹 2회", App Group으로 앱-위젯 데이터 공유
- ☐ 타임라인 예산(하루 40~70회) 안에서 갱신 전략 설계 (자정 1회 + 겹 발생 시 reload)
- 📄 WidgetKit, "Keeping a widget up to date"
- 💬 "위젯은 미니 앱이 아니라 타임라인 스냅샷이라는 것을, 예산 제한에 부딪히며 배웠습니다"

### B5. App Intents — 앱 실행 0회로 신호 켜기
- ☐ `AppIntent`로 "신호 켜기" 노출: Siri, 단축어, 잠금화면 컨트롤(iOS 18 ControlWidget), 액션버튼
- 📄 App Intents, WWDC 2024 "Bring your app's core features to users with App Intents"
- 💬 "앱의 핵심 동사를 시스템 전체에 심는 경험 — 프로세스 밖에서 인텐트가 실행될 때의 제약을 다뤘습니다"

## C. 데이터·보안 (스프린트 S1, S3)

### C1. Keychain — 세션 토큰 저장 🔗 #4, #5
- ☐ Sign in with Apple 후 받은 토큰을 `SecItemAdd`/`SecItemCopyMatching`로 저장·조회하는 `KeychainStore` 직접 구현 (라이브러리 미사용)
- ☐ `kSecAttrAccessible` 옵션 선택 근거 정리 (`afterFirstUnlock` — 백그라운드 푸시 처리 시 접근 필요)
- 📄 Keychain Services (Adding/Searching/Updating items)
- 💬 "토큰을 UserDefaults에 넣으면 안 되는 이유와, C API 기반 키체인을 Swift답게 감싸는 방법을 구현으로 답할 수 있습니다"

### C2. UserDefaults — 온보딩·설정 상태 🔗 #1
- ☐ 온보딩 완료 여부를 `bool(forKey:)`가 아닌 `object(forKey:)`로 판정 — "값 없음"과 "false"의 구분 (블로그 #1의 함정 그대로 실전 적용)
- ☐ 설정(야간 무음, 룰렛 옵트인)을 `@AppStorage`로 노출하되 키를 타입 세이프하게 상수화
- 📄 UserDefaults
- 💬 "bool(forKey:)의 기본값 모호성 때문에 신규 유저 판정이 꼬이는 버그를 설계 단계에서 차단했습니다"

### C3. SwiftData — 겹·카드·스탬프 로컬 저장
- ☐ `@Model` 관계 모델링 (Runner–Gyeop–Spot), 마이그레이션 플랜 1회 이상 실제 수행 (v1→v2 스키마 변경)
- ☐ 백그라운드 `ModelActor`에서 쓰기, 메인에서 읽기 — 동시성 경계 설계
- 📄 SwiftData, WWDC 2023 "Model your schema with SwiftData"
- 💬 "출시 후 스키마를 바꿔야 했을 때 마이그레이션을 어떻게 했는지 말할 수 있는 사람은 드뭅니다 — 그걸 겪으러 갑니다"

### C4. 서버 동기화 — 오프라인 큐잉
- ☐ 맞대기(로컬 발생) → 서버 업로드 큐: 네트워크 없을 때 쌓고, 복구 시 순서 보장 업로드, 중복 방지 idempotency key
- 📄 URLSession, Background Tasks (BGTaskScheduler)
- 💬 "P2P로 생긴 데이터를 서버와 정합성 있게 합치는 문제 — 클라이언트가 진실의 원천인 데이터의 동기화를 설계했습니다"

## D. UI·렌더링 (스프린트 S1, S5)

### D1. MeshGradient + Metal 셰이더 — 정체성 카드
- ☐ 관심사 시드 → 결정적 비주얼 함수 (같은 입력 = 픽셀 동일), `layerEffect`로 질감 셰이더
- ☐ `matchedGeometryEffect`로 목록↔상세 카드 전환
- 📄 SwiftUI MeshGradient, Shader, WWDC 2024 "Create custom visual effects with SwiftUI"
- 💬 "SwiftUI가 언제 어떻게 다시 그리는지를, 60fps 셰이더 카드를 만들며 프로파일링으로 확인했습니다"

### D2. SwiftUI Canvas — 겹 그래프 (force-directed)
- ☐ 150노드 물리 시뮬레이션을 오프메인 actor에서 계산, `TimelineView` + `Canvas`로 렌더
- ☐ 시뮬레이션 틱과 렌더 프레임의 분리 (계산 30Hz, 렌더 60fps 보간)
- 📄 Canvas, TimelineView
- 💬 "뷰 업데이트와 무거운 계산을 분리하는 구조를 직접 설계했습니다 — main actor 격리가 왜 필요한지 체감한 사례"

### D3. MapKit — 포항 스팟 맵 + 지오펜스 검증
- ☐ SwiftUI MapKit 커스텀 어노테이션·클러스터링, 스팟 반경 100m 내 맞대기만 스탬프 인정(CoreLocation)
- 📄 MapKit for SwiftUI (WWDC 2023), CoreLocation CLMonitor
- 💬 "위치 인증의 오탐/미탐 트레이드오프를 반경·정확도 옵션으로 조정한 경험"

### D4. UIKit 인터롭 — 러너 목록 화면 1개를 일부러 UIKit으로 🔗 #7, #8, #9
- ☐ 전체 러너 브라우즈 화면을 `UICollectionView` + Compositional Layout + **Diffable DataSource**로 구현, 셀 내부는 `UIHostingConfiguration`으로 SwiftUI 카드 재사용
- ☐ 스냅샷 중복 아이템 함정(Hashable 식별자 설계)을 실제로 밟고 해결
- 📄 "Implementing Modern Collection Views", WWDC 2019 "Advances in UI Data Sources", WWDC 2022 "Use SwiftUI with UIKit"
- 💬 "SwiftUI 앱이지만 UIKit 경계를 넘나들 수 있음을 한 화면으로 증명합니다 — 실무 코드베이스 대부분이 혼재라서, 인터롭이 곧 실무 준비"

### D5. 레이아웃 시스템 이해 — SwiftUI판 CHCR 🔗 #6, #12
- ☐ 카드 내 텍스트 줄임 우선순위를 `layoutPriority`/`fixedSize`로 제어 — UIKit CHCR(hugging/compression)과의 대응 관계를 정리
- ☐ Dynamic Type 대응: 카드·위젯이 접근성 글자 크기에서도 안 깨지게
- 📄 SwiftUI Layout fundamentals, HIG > Typography
- 💬 "UIKit CHCR과 SwiftUI layoutPriority를 같은 문제의 두 답으로 설명할 수 있습니다"

## E. 품질·출시 (스프린트 S6~S7, 상시)

### E1. Swift Concurrency 심화 — 앱 전체의 뼈대
- ☐ `TaskGroup` 병렬 프리페치(카드 이미지), 부분 실패 정책 명시
- ☐ actor로 신호 캐시 격리, Swift 6 strict concurrency 빌드 통과 (`Sendable` 정리)
- ☐ do-catch는 최종 호출부에만 — 구현부 catch 금지 원칙을 린트 수준으로 강제
- 📄 WWDC 2021 "Meet async/await" / "Protect mutable state with actors", Swift 6 Migration Guide
- 💬 "GCD 질문에 '왜 안 썼는지'로 답합니다 — 구조화 동시성으로 취소·수명·격리를 어떻게 다뤘는지 사례로"

### E2. OSLog + Instruments — 관측 가능성
- ☐ `Logger` 카테고리 설계(networking/sync/nearby), signpost로 맞대기 구간 측정
- ☐ Instruments로 카드 셰이더 프레임 드랍·메모리 프로파일링 1회 이상, 결과를 수치로 기록
- 📄 OSLog, WWDC 2023 "Analyze hangs with Instruments"
- 💬 "느린 것 같다가 아니라, signpost 수치로 어디가 몇 ms인지 말합니다"

### E3. Swift Testing — 가치 있는 것만
- ☐ 신호 수명 상태 머신, 맞대기 프로토콜, 룰렛 매칭 규칙(자카드 유사도·미겹 필터)을 단위 테스트
- ☐ `URLProtocol` 목킹으로 네트워크 레이어 테스트
- 📄 Swift Testing, WWDC 2024 "Meet Swift Testing"
- 💬 "커버리지가 아니라 '무엇이 테스트할 가치가 있는가'를 판단한 기준을 말합니다"

### E4. Sign in with Apple + 계정 삭제
- ☐ ASAuthorization 플로우, 아카데미 이메일 도메인 검증과 결합, **계정 삭제 기능**(심사 필수) 포함
- 📄 Sign in with Apple, "Offering account deletion in your app"
- 💬 "서드파티 로그인을 제공하면 Sign in with Apple이 의무라는 심사 규정까지 포함해 인증 전체를 구현했습니다"

### E5. App Store 심사·출시 🔗 #10
- ☐ 심사지침 체크리스트 통과: 데모 계정 제공, 개인정보 처리방침, 위치·알림 권한 문구, (폐쇄 커뮤니티 앱의 가입 제한 사유 소명)
- ☐ TestFlight 외부 테스터 → 정식 심사 제출, 리젝 시 대응 기록
- 📄 App Store Review Guidelines, App Privacy Details
- 💬 "심사에서 뭘 보는지, 리젝을 어떻게 풀었는지 — 출시해 본 사람만 있는 이야기"

### E6. HIG — 설계 결정의 근거 문서 🔗 #13, #14, #15
- ☐ 신호 조인은 모달인가 내비게이션인가 — HIG Modality 기준으로 결정하고 근거 기록
- ☐ 탭바 구조(홈/그래프/맵/마이) vs 다른 내비게이션 스타일 검토, iPad 대응 시 SplitView 전환 계획 🔗 #11
- 📄 HIG > Modality, Navigation
- 💬 "왜 이 화면이 sheet인지 push인지를 취향이 아니라 HIG 기준으로 답합니다"

---

## 요약 — 경험의 우선순위

"구현해 본 경험"의 가치 순서로 다시 줄 세우면:

1. **A2 NearbyInteraction + A1 MPC** — 희소성 최상. 이걸 해본 지원자는 거의 없다.
2. **B3 Live Activity 푸시 갱신 + B1 APNs 직접 구현** — 파이프라인 전 구간을 아는 사람이 되는 경험.
3. **E1 Swift 6 동시성 + C4 오프라인 동기화** — 어렵고, 어른스럽고, 모든 면접에서 통용.
4. **C1 Keychain + E4 Sign in with Apple + E5 심사** — "출시까지 해봤다"의 3종 세트.
5. **D4 UIKit 인터롭(Diffable)** — 실무 혼재 코드베이스 대비. 블로그 시리즈(#7~9)와 정확히 겹치는 주제라 공식문서 학습 경로도 이미 있다.
6. 나머지(D1·D2·B4·B5·D3·E2·E3)는 만들다 보면 자연히 쌓인다.

블로그 시리즈 15개 글 중 이 앱과 겹치지 않는 것은 #6(UIKit CHCR — D5로 개념만 흡수), #11~14(SplitView/Sidebar — iPad 대응 시점에 회수)뿐이다. 나머지는 전부 겹의 실제 기능 구현으로 소화된다.
