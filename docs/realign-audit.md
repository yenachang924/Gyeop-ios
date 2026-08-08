# 겹(Gyeop) — 정렬 스프린트 격차 감사 (R0, 2026-08-08)

docs(피벗 v2) 기준으로 현재 코드베이스를 ①제거/②유지/③추가로 3분류한다.
R1(제거·카피), R2(App Clip), R3(온보딩·이모지·카드)의 작업 목록 원본이다.
작업량: S(1커밋 내), M(반나절), L(하루+).

전제 확인: **Firebase·푸시 실구현·이메일 인증(도메인 화이트리스트)은 코드에 0건**이다.
로그인은 Sign in with Apple 단독이며 아카데미 소속 검증 로직은 존재하지 않는다.
외부 SPM 의존성 0개.

---

## ① 제거 — 아카데미 전제 (R1 소유)

| # | 항목 | 위치 | 의존 관계 (지우면 깨지는 것) | 양 |
|---|---|---|---|---|
| 1 | `Season` 타입 + "수료까지 D-n" 헤더 | `Core/Models/GyeopRecord.swift:32-49`, `Core/Mocks/MockData.swift:9-14`, `App/AppModel.swift:24`, `App/Features/Collection/CollectionView.swift:6,20,70-84` | 없음 — 타입 의존·영속화·테스트 전부 0건. 가장 깨끗하게 제거 가능 | S |
| 2 | `"Apple Developer Academy 4기"` 문자열 | `Core/Mocks/MockData.swift:11` | #1에 포함됨 (현재 미렌더) | S |
| 3 | 사용자 노출 "러너" 카피 5건 | `ProfileStepView:19`, `ClipOnboardingView:49`, `ExchangeView:60,167`, `CollectionView:109` | 문자열 교체만. UITest는 identifier 기반이라 안전 | S |
| 4 | 권한 문구 "근처 러너" | `project.yml:46` → **`xcodegen generate` 필수** (Info.plist는 생성물) | 없음. 단 project.yml은 S1/S6(=R4) 소유 — R1이 필요 시 조율 | S |
| 5 | `RunnerProfile`→중립 명칭 리네임 (+`RunnerProfileEntity`, `GyeopID.make(runnerA:runnerB:)` 레이블) | 정의: `Core/Models/RunnerProfile.swift:5`, `DataKit/Persistence/RunnerProfileEntity.swift:7`, `Core/Telemetry/Telemetry.swift:163-164`. 참조 24개 파일(Core 계약·Mock, CardKit 시드, DataKit 저장소, App 온보딩, AppClipKit, 테스트 6파일) | 전면 리네임. GyeopID 해시 값은 불변(레이블은 해시 입력 아님). `RunnerProfileEntity`는 @Model이나 미출시라 마이그레이션 부담 낮음 | M |
| 6 | 데드 코드: `AppleSignInCoordinator.swift` 전체, `Telemetry.swift`의 `Log.signal/auth`·`Signpost.signal`·`Metric.signal*·pushReceived`, `GyeopRecord.Method.signal`, Firebase 언급 주석(`GyeopRepository.swift:3`) | 참조 전부 0건 → 삭제 안전. `Method.signal`만 String raw Codable 주의(저장 데이터 없으면 무해) | 컴파일 영향 0 | S |
| 7 | UITest 입력 `"보드게임 좋아하는 러너"` | `UITests/ScreenshotAndAccessibilityUITests.swift:85` | **심사 스크린샷에 그대로 찍힘** — 재촬영과 세트 | S |
| 8 | 런타임 ID 프리픽스 `runner-`/`clip-runner-`, 테스트 픽스처 `runner-*`, 주석 "러너" | `AppModel.swift:166`, `ClipModel.swift:65`, 테스트 다수 | 노출 없음 — #5 리네임 때 일괄 처리 | S |

수료 D-day·기수·팀·cohort·graduation 심볼: `Season` 외 **0건**.

## ② 유지 — 수정 없이 재사용 가능한가

| 항목 | 위치 | 재사용 판정 | 비고 |
|---|---|---|---|
| 카드 엔진 | `CardKit/` (CardSeed·CardVisual·CardView·CardImageExporter) | **그대로 재사용** | 시드에 이모지 이미 포함, HSL(S 0.70-0.80 / B 0.45-0.62) 이미 스코프 일치, 결정성·WCAG 대비 테스트 존재. 주의 2건: `Core/MockCardGenerator`가 실구현과 다른 시드 규칙(ownerID·version 포함), 신규 `CardAmbientBackground`가 `String.hashValue` 기반이라 비결정적 |
| MPC 교환 | `GyeopKit/` (순수 상태 머신 + 타이브레이크 + 타임아웃 20/10/5s + 겹침 로그) | **그대로 재사용** | 겹침 계산은 `Core.CardSnapshot.sharedInterests(with:)`. "같은 이모지" 비교는 없음(③-5) |
| SwiftData 기록 | `DataKit/` (엔티티 3종, 결정적 GyeopID 멱등, 24h 중복 제거, ClipMigrationReceiver) | **재사용** (단 클립 연동 시 수정) | 현재 앱 기본 컨테이너 사용 — App Group SwiftData 컨테이너 아님(③-2). `pendingGyeopsKey` 문자열이 AppClipKit·DataKit에 중복 하드코딩 |
| 온보딩 골격 | `App/Features/Onboarding/` (NavigationStack 3단계 + Draft) | **골격 재사용, 내용 수정 필요** | 이모지 그리드 원탭 이미 존재(키보드 아님). 배선표와 다른 점은 §네비 대조표 참조 |
| Telemetry | `Core/Telemetry/Telemetry.swift` | **그대로 재사용** | 데드 상수만 정리(①-6). GyeopID·Signpost·MetricCounter는 현역 |
| DesignSystem 토큰 | `DesignSystem/Tokens.swift` | **재사용 — 단 결정 지점 1** | 작업 트리에 커밋 안 된 팔레트 교체(indigo→POSTECH 5색 + heroTitleStyle + success=teal)가 있음. 가드레일 "기존 값 변경 금지"와 충돌 — 아래 [결정 지점] 참조 |
| SIWA·계정 삭제 | `WelcomeView`, `KeychainTokenStore`, `AccountDeletionService`, `SettingsView` | **유지** (스코프 ⑤ Lv2 ★출시: SiwA+계정삭제) | 단 로그인 게이트 화면이 배선표에 없음 — 배선표 수정 제안 필요(아래) |
| App Clip 기반 | `AppClip/` 타깃 + AppClipKit + App Group entitlements + SKOverlay + 마이그레이션 우편함 | **재사용** | R2 프롬프트의 "타깃 생성"은 이미 완료 상태. 남은 것은 ③-1~4 |

## ③ 추가 — docs에 있으나 코드에 없는 것

| # | 항목 | 근거 docs | 현재 상태 | 양 | 소유 |
|---|---|---|---|---|---|
| 1 | 클립 플로우를 배선표 레인으로 재구성: **카드 수신 화면**(발신자 카드 표시 + 「내 카드 만들기」 + 설명 시트) → 본앱 온보딩 3단계 재사용 → card → bump → overlap → keep | navigation-map §1 | 클립은 현재 한 화면 Form 축약 온보딩(발신자 카드 미표시, 별도 `ClipInterestCatalog` 12개 하드코딩) | **L** | R2 |
| 2 | 클립 실배선: `ClipModel.live()`의 Mock 3종 → CardKit 실생성기·MPC·**App Group 공유 컨테이너 SwiftData** + 30일 보존 집행 | scope ③ Lv2 | 전부 Mock, 보존 정책은 문구만 | M | R2 |
| 3 | 인보케이션 정합: 스킴 `_XCAppClipURL`(`?inviter=`)이 파서 계약(`?t=&n=`)과 불일치 → 시뮬레이터에서 초대 정보 항상 빈 값 | scope ③ | 파서·테스트는 존재 | S | R2 |
| 4 | SKOverlay 이전 화면 설치 유도 금지 검증 + `keep`의 「나중에 할게요」(거절 비용 0) 경로 | navigation-map §1-8 | SKOverlay 라우팅은 이미 교환 후로 강제됨. "나중에" 경로·`done` 전환은 미확인 | S | R2 |
| 5 | **겹침 이스터에그**: 같은 이모지면 "이모지도 겹쳤어요" 한 줄 (기존 컴포넌트 스타일) | 프로토타입 `overlap-emoji`, R3 프롬프트 | 이모지 비교 로직 0건 | S | R3 |
| 6 | 온보딩 `intro` 전부 선택사항화: 현재 닉네임+이모지 필수(버튼 비활성) → "입력 전부 비워도 진행" | navigation-map §1-4 | 필수 검증 제거 + 빈 값 카드 시드 처리 | S | R3 |
| 7 | 이모지 카탈로그 교체: 번들 CSV 25개 → `docs/assets/emoji-icons.csv` 138행, 1차 16개 노출(+검색은 실앱 전체 세트) | R3 프롬프트 | 그리드·토글·44pt·접근성은 이미 있음 | M | R3 |
| 8 | `interests` 실시간 카드 프리뷰 — 선택 시 카드가 물듦 | navigation-map §1-2, 프로토타입 | `CardPreview` API는 존재, 화면 배선 없음 | M | R3 |
| 9 | 새 카피 전면 반영: 프로토타입 기준 ("요즘 나를 이루는 것"·"쉬는 날의 나는"·"마지막 한 줄"·"이게 나예요" 등) + 온보딩 헤더의 "프로토타입 부재" 주석 제거 | gyeop-prototype.html | 현재 카피는 구스펙 임시본 | S | R1·R3 분담 |
| 10 | `vibe` 4택1 후 「다음」 버튼 (현재 원탭 즉시 push — 배선표는 선택 표시 후 「다음」) | navigation-map §1-3 | | S | R3 |
| 11 | `card`(카드 완성)에서 「맞대기」 진입 (현재 「컬렉션으로」만) | navigation-map §1-5 | | S | R3 |
| 12 | 로컬 네트워크 권한 사전 설명 1장 (`card`→`bump` 최초 1회) | navigation-map §3 | 없음 — **프로토타입에 없는 구성 → `review/proposals/` HTML 제안 먼저** | S | R4 전 제안 |
| 13 | 클립→풀앱 첫 실행 마이그레이션 완료 안내 | navigation-map §3 | 마이그레이션은 무음 실행 중 — 동일하게 HTML 제안 먼저 | S | R4 전 제안 |

## 현재 화면·전환 ↔ 배선표 대조

### 본앱 (전환 방식: TabView·fullScreenCover 없음. 온보딩 push 1곳 + sheet 3개 + stage 루트 스위칭)

| 배선표 | 현재 코드 | 판정 |
|---|---|---|
| (배선표에 없음) | `WelcomeView` SIWA 게이트 → 온보딩 | ⚠️ **배선표 밖** — 스코프 ⑤가 SiwA ★출시를 요구하므로 배선표에 추가 제안 필요 |
| 2 `interests`: 칩 토글 max5, 0개면 다음 비활성 | `InterestsStepView` 동일 | ✅ 일치 (프리뷰만 없음 → ③-8) |
| 3 `vibe`: 4택1 선택 표시 → 「다음」 | `StyleStepView` 원탭 즉시 push | ❌ 코드 수정 (③-10) |
| 4 `intro`: 전부 선택사항, 「카드 완성」 | `ProfileStepView` 닉네임·이모지 필수 | ❌ 코드 수정 (③-6) |
| 5 `card` → 「맞대기」 → `bump` | `CardRevealView` → 「컬렉션으로」(루트 스위칭)만 | ❌ 코드 수정 (③-11) |
| 6 `bump` → 1.5s → 7 `overlap` | `ExchangeView` sheet 내 4상태 인라인 전환 (searching→connecting→completed/failed) | 🔶 구조 다름·기능 동등 — R4에서 배선표 문구와 맞춰 판정 |
| 9 `done` 컬렉션 (빈 상태 변형 포함) | `CollectionView` (빈 상태 있음, D-day 헤더는 ①-1 제거 대상) | ✅ 골격 일치 |
| §3 교환 실패 (재시도/취소 + 사유 1줄) | `ExchangeView` failed phase — 사유 4종·재시도 | ✅ 일치 |
| §3 설정 (프로필 수정·계정 삭제) | `SettingsView` — 계정 삭제만, 프로필 수정 없음 | 🔶 부분 (프로필 수정은 프로토타입에 없음 → 제안 대상) |
| §3 본앱 홈 (탭 구조 확정 필요) | 탭 없음 — Collection 단일 루트 | 🔶 배선표 자체가 미결 |
| (배선표에 없음) | `CardDetailView` (받은 카드 상세 sheet) | ⚠️ **배선표 밖** — 제거하거나 배선표 추가 제안 |
| §3 로컬 네트워크 사전 설명 / 클립→풀앱 안내 | 없음 | ❌ 추가 (③-12·13, HTML 제안 먼저) |

### 클립 레인

| 배선표 | 현재 코드 | 판정 |
|---|---|---|
| 1 `clip` 카드 수신 (발신자 카드 + 설명 시트) | 없음 — `ClipOnboardingView` 텍스트 인사만 | ❌ 추가 (③-1) |
| 2~4 온보딩 3단계 (본앱 뷰 재사용) | 한 화면 Form 축약 | ❌ 재구성 (③-1) |
| 5~7 card→bump→overlap | `ClipExchangingView`→`ClipInstallSuggestionView`에 압축 | ❌ 재구성 (③-1) |
| 8 `keep`: SKOverlay 교환 후만 + 「나중에 할게요」 | SKOverlay 교환 후 강제 ✅ / 「나중에」·`done` 경로 미확인 | 🔶 (③-4) |

## docs/screenshots/ 감사 (심사용 10장, iPhone 17 Pro Max)

| 파일 | 구기획 노출 | 판정 |
|---|---|---|
| asc-6.9-1-onboarding-interests | 카피 구스펙 임시본 | 재촬영 (R1·R3 후) |
| asc-6.9-2-onboarding-style | "여가 성향…" 카피 + 원탭 구조 | 재촬영 |
| asc-6.9-3-onboarding-profile | **"러너들이 부를 이름" 노출** | 재촬영 필수 |
| asc-6.9-4-card-reveal | 구기획 요소 없음 | 카피 확정 후 재확인 |
| asc-6.9-5-collection-empty | **"옆 러너와…" + D-day 헤더** | 재촬영 필수 |
| asc-6.9-6-exchange-searching | **"주변 러너를 찾는 중"** | 재촬영 필수 |
| asc-6.9-7-exchange-completed | 입력값 "보드게임 좋아하는 러너" 가능성 | 재촬영 |
| asc-6.9-8-collection-filled | **D-day 헤더 "수료까지 D-n"** | 재촬영 필수 |
| asc-6.9-9-card-detail | 배선표 밖 화면 | 배선표 결정 후 재촬영 |
| asc-6.9-10-settings | 구기획 요소 없음 | 유지 가능 |

Welcome·클립 화면은 세트에 없음. 결론: **10장 전부 정렬 완료 후 재촬영 대상**(절차는 `docs/review-kit.md`의 UITest 기반).

## [결정 지점] — 소유자 판단 필요

1. **커밋 안 된 POSTECH 팔레트 작업** (작업 트리: `Tokens.swift` accent indigo→POSTECH Red 등 5색 + `heroTitleStyle` + `CardAmbientBackground.swift` 신규 + App 뷰 12파일). 코멘트엔 "Figma 확정본(2026-08-08)"으로 표기 — 가드레일 "토큰 기존 값 변경 금지"보다 먼저 만들어진 작업이다. **승인해 커밋할지, 되돌릴지** 결정 필요. 승인 시 `CardAmbientBackground`의 비결정성(hashValue)은 수정 대상.
2. **배선표 수정 제안 2건**: (a) SIWA 로그인 게이트(스코프 ⑤ ★출시와 배선표 불일치) (b) 받은 카드 상세(`CardDetailView`) — 배선표에 추가하거나 화면 제거.
3. **R2 프롬프트 범위 보정**: "AppClip 타깃 생성"은 완료 상태. R2의 실작업은 ③-1~4 (레인 재구성·실배선·인보케이션 정합·keep 경로). 어소시에이티드 도메인은 전부 `PLACEHOLDER.gyeop.example` 자리 표시(실도메인 확정 대기, `realign-and-testflight.md` D-1).

## 보안 관찰 (코드 수정 없음 — 가드레일에 따라 기록만)

`docs/security-backlog.md`에 기록: App Group UserDefaults 우편함 평문 JSON, 클립 무계정 데이터 경계, `pendingGyeopsKey` 중복 하드코딩. (구조 변경은 존 피드백 이후.)
