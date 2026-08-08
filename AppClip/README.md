# AppClip

> **2026-08-08 정렬 스프린트(R2): 클립 레인 재구성 + 실배선 완료.**
> `docs/navigation-map.md` §1 클립 레인과 1:1로 재구성됐고, Mock 3종 배선은
> 실구현(CardKit 카드 엔진 · 실기기 MPC · App Group SwiftData + 30일 보존 집행)으로
> 교체됐다. 남은 것은 실도메인 확정 후 entitlements의 `PLACEHOLDER.gyeop.example` 교체와
> 실기기 검증(`docs/device-required.md`) — 아래 "알려진 갭" 참조.

## 구조

```
AppClip/
  App/                        GyeopClip 타깃 소스 (project.yml `GyeopClip`)
    AppClipApp.swift            @main — 인보케이션 URL을 ClipModel로 흘려보내는 배선만
    ClipAssembly.swift          조립 지점 — ClipModel.live(): 실구현을 Core 계약에 꽂는 유일한 곳
    ClipOnboardingFlowView.swift  온보딩 3단계 조립 — 본앱 뷰를 **소스 공유로 재사용**
    AppClip.entitlements        App Group + associated domain (도메인은 자리 표시)
  UITests/                    GyeopClipUITests — 클립 레인 관통 + 설치 유도 게이트 검증
  AppClipKit/                 로컬 SPM 패키지 — 상태 머신·마이그레이션·URL 파싱·클립 전용 뷰
```

- **온보딩 3단계 재사용**: `InterestsStepView`·`StyleStepView`·`ProfileStepView`·
  `OnboardingDraft`·`EmojiCatalog`(+CSV)를 GyeopClip 타깃이 소스 공유로 컴파일한다
  (project.yml `GyeopClip.sources`). 본앱과 화면·accessibility identifier가 동일하다 —
  **본앱 온보딩을 고치는 세션(R3)은 identifier를 바꾸면 클립 UI 테스트도 깨진다는 걸 알 것.**
- **레인**: `ClipStage` = reception → onboarding → card → bump → overlap → keep → done
  (+failed). **SKOverlay는 keep의 「전체 앱 받기」 탭에서만** 뜬다 — 그 이전 화면 어디에도
  설치 유도 UI가 없고, UI 테스트가 각 단계에서 이를 단언한다.
- **실배선** (`ClipAssembly.swift`): 카드 `CardKit.CardGenerator`, 저장
  `SwiftDataGyeopRepository.appGroup(id:)`(생성 실패 시 인메모리 강등) + 실행마다
  `pruneGyeops(before: ClipRetentionPolicy.cutoffDate())`로 30일 보존 집행, 교환은
  실기기 `MultipeerExchangeSession` / 시뮬레이터 `MockExchangeSession`.
- **마이그레이션**: 겹 성립 시 `ClipPendingGyeopWriter`가 App Group UserDefaults 우편함
  (`com.gyeop.clip.pendingGyeops`)에 적재 → 본앱 `AppModel.bootstrap()`의
  `ClipMigrationReceiver.migrate()`가 병합. App Group ID는 양쪽 다 `group.com.gyeop.app`.
  ⚠️ 키 문자열은 여전히 AppClipKit·DataKit에 중복 하드코딩 — Core 공유 상수화는 계약 변경이라
  세션 합의 대기 (`docs/security-backlog.md`에도 기록됨).
- **인보케이션 URL**: `https://<도메인>/clip?t=<교환 토큰>&n=<발신자 닉네임·선택>`
  (개발 폴백 `gyeop://clip` 동일 쿼리) — navigation-map §1에 기록됨. 시뮬레이터는
  `_XCAppClipURL`로 주입 (Xcode 스킴 env + simctl `SIMCTL_CHILD__XCAppClipURL` 디버그 폴백).

## 검증 상태 (2026-08-08)

- `cd AppClip/AppClipKit && swift test` — 14개 통과 (레인 상태 머신·keep 이전 설치 불가·
  우편함 훅·URL 파싱·30일 정책).
- `cd Packages/GyeopPackages && swift test` — 64개 통과 (ClipMigrationReceiver·pruneGyeops 포함).
- GyeopClip UI 테스트 2개 통과 — `_XCAppClipURL` 인보케이션으로 reception→done 관통,
  keep 이전 화면마다 설치 유도 부재 단언, 실패→재시도.
- **클립 크기: 1.6MB** (Release·iphoneos·미서명 .app — 실행 바이너리 1.53MB + CSV 13KB).
  GyeopKit·DataKit 추가 후에도 35MB 예산 대비 약 4.6%. 외부 의존성 0.

## 알려진 갭

- **발신자 카드 실표시 불가** — 인보케이션 URL에는 토큰·닉네임뿐, 카드 데이터는 교환에서야
  도착한다. reception 화면은 닉네임 자리 표시(GroupBox)로 대체 중 — 토큰→카드 조회가 생기면
  `CardView`로 교체.
- **어소시에이티드 도메인 자리 표시** — 실도메인 확정 시 `AppClip.entitlements`·부모
  entitlements·project.yml 데모 URL의 `PLACEHOLDER.gyeop.example` 교체.
- **실기기 검증 대기** — MPC 맞대기(클립 Info.plist에 로컬 네트워크 키 추가됨), App Group
  교차 프로세스 마이그레이션 (`docs/device-required.md` 통합 실행 계획 8번).
- **R3 소관으로 남긴 것** — 온보딩 카피·이모지 카탈로그 교체(③-7)·관심사 실시간 카드
  프리뷰(③-8)·`vibe` 「다음」 버튼(③-10)·이모지 이스터에그(③-5). 클립은 본앱 뷰를
  소스 공유하므로 R3가 고치면 클립도 같이 좋아진다.
