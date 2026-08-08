# AppClip — 타깃 자리

App Clip 타깃의 자리다. 아직 Xcode 타깃으로 활성화하지 않는다 — 부모 앱 번들 ID·entitlements(App Clip
association)·서명이 필요해서, Developer Program 세팅이 끝난 뒤 S6 세션이 활성화한다. `project.yml`과
`App/` 디렉토리는 S1/S6만 수정하므로 (CLAUDE.md 소유권 규칙), 이 세션은 그 경계 밖의 것만 만든다.

## 지금 여기 있는 것

```
AppClip/
  App/                     Xcode 타깃이 될 얇은 소스 (project.yml 활성화 후 sources:로 연결)
    AppClipApp.swift         @main 진입점 — 인보케이션 URL을 ClipModel로 흘려보내는 배선만
    AppClip.entitlements     자리 표시 entitlements (associated domain 값은 소유자 결정 대기)
  AppClipKit/                로컬 SPM 패키지 — 플로우 로직·마이그레이션·URL 파싱·뷰 전부 여기
    Package.swift             ../../Packages/GyeopPackages의 Core/DesignSystem/CardKit에 의존
    Sources/AppClipKit/...
    Tests/AppClipKitTests/... `cd AppClip/AppClipKit && swift test`로 지금 바로 검증 가능
```

`project.yml`이 잠겨 있어 Xcode 타깃을 만들 수 없으므로, 검증 가능한 로직·뷰는 전부 별도의 로컬
Swift Package(`AppClipKit`)로 뺐다. App의 `GyeopApp.swift` ↔ `AppModel` 패턴과 동일하게,
`App/AppClipApp.swift`는 `AppClipKit.ClipModel` + `ClipRootView`를 띄우기만 하는 얇은 껍데기다.

**지금 검증된 것:** `swift test` 12개 테스트 통과 — 인보케이션 URL 파싱, 30일 보존 정책, 클립→풀앱
마이그레이션 쓰기측(App Group UserDefaults 왕복), 초대 수신→온보딩→교환→설치 제안 전체 플로우(Mock
기반), 겹 성립 시 마이그레이션 훅 호출, 실패→재시도 복구. CardKit의 `CardView`(정체성 카드 렌더)도
실제로 물려서 씀 — Mock/스텁이 아니다.

**아직 못 하는 것:** Xcode 타깃이 없어서 시뮬레이터에서 `_XCAppClipURL`로 실제 클립 경험을 띄우는
완료 기준은 이번 세션에서 만족시킬 수 없다. 아래 활성화 절차 이후에 가능하다.

## 활성화 절차 (S1/S6만)

1. `project.yml`의 `# --- AppClip (자리) ---` 블록을 아래로 교체하고 `xcodegen generate`:

   ```yaml
   GyeopClip:
     type: application.on-demand-install-capable
     platform: iOS
     sources: [AppClip/App]
     dependencies:
       - package: GyeopPackages
         products: [Core, DesignSystem, CardKit]
       - package: AppClipKit
         products: [AppClipKit]
     settings:
       base:
         PRODUCT_BUNDLE_IDENTIFIER: com.gyeop.app.Clip
         GENERATE_INFOPLIST_FILE: YES
         INFOPLIST_KEY_CFBundleDisplayName: 겹 클립
         CODE_SIGN_ENTITLEMENTS: AppClip/App/AppClip.entitlements
         TARGETED_DEVICE_FAMILY: "1"
   ```

   `packages:` 섹션에 로컬 패키지 참조 추가:
   ```yaml
   packages:
     GyeopPackages:
       path: Packages/GyeopPackages
     AppClipKit:
       path: AppClip/AppClipKit
   ```

   Info.plist에 App Clip 필수 키 추가 필요 (`NSAppClip` 딕셔너리 — `NSAppClipRequestEphemeralUserNotification`
   등). xcodegen의 `info:` 블록 또는 `INFOPLIST_KEY_*`로 배선.

2. 부모 앱(`App/`)에 매칭 entitlements 추가 — 지금 `App/`에는 entitlements 파일 자체가 없다. 새로 만들어서:
   - `com.apple.developer.associated-domains`: `applinks:` + `appclips:` 둘 다, `AppClip.entitlements`와
     같은 실도메인 (지금은 둘 다 자리 표시).
   - `com.apple.security.application-groups`: `group.com.gyeop.app` (클립과 동일 그룹).
   - `project.yml`의 `Gyeop` 타깃 settings에 `CODE_SIGN_ENTITLEMENTS` 추가.

3. 어소시에이티드 도메인 실도메인 확정 후 `AppClip.entitlements`와 부모 entitlements의
   `PLACEHOLDER.gyeop.example`을 교체.

4. `AppClipKit.ClipModel.live()`가 쓰는 `MockCardGenerator`/`MockGyeopRepository`/`MockExchangeSession`을
   실배선으로 교체하는 지점 — App 조립 지점(`AppModel.live()`와 대응)에서 S1/S6이 CardKit 실구현·
   App Group SwiftData 스토어·GyeopKit 실 `ExchangeSession`을 주입. `ClipModel.init`이 이미
   생성자 주입 형태라 교체 지점은 `ClipModel.live()` 하나뿐이다.

5. 클립→풀앱 마이그레이션은 이미 양쪽이 맞물려 있다 — 클립은 겹 성립 시
   `AppClipKit.ClipPendingGyeopWriter`로 App Group `UserDefaults(suiteName:)`에 `GyeopRecord`를
   쌓고(`ClipModel.live()`에 이미 배선됨), DataKit 세션이 별도로 만든
   `DataKit.ClipMigrationReceiver.migrate()`가 같은 키(`com.gyeop.clip.pendingGyeops`)를 읽어
   풀 앱 저장소로 병합한다. 남은 건 두 세션이 **같은 App Group ID 문자열**을 실제로 주고받는 것뿐 —
   지금은 클립 쪽 `"group.com.gyeop.app"` 하나만 존재하고 DataKit 쪽 호출부(어디서 어떤 ID로
   `ClipMigrationReceiver`를 생성하는지)는 아직 없어 보인다. App 조립 지점에서 두 값이 같은지
   확인하고 `AppModel.bootstrap()` 근처에서 1회 호출로 연결할 것.
   ⚠️ 키 문자열(`pendingGyeopsKey`)이 AppClip·DataKit 양쪽에 하드코딩 중복돼 있다 — Core로 옮겨
   공유 상수화하는 걸 권장하지만, Core 변경은 관련 세션 합의가 필요해 이번 세션에서 하지 않았다.

## 알려진 갭 (다음 사람이 알아야 할 것)

- **"온보딩 공용 뷰 재사용"이 지금은 구조적으로 불가능하다.** `App/Features/Onboarding/*`와
  `App/Support/EmojiCatalog.swift`는 App 타깃 전용 파일이라 Clip이 의존할 수 있는 패키지 안에 없다.
  그래서 `ClipOnboardingView`는 같은 DesignSystem 토큰·문구 톤으로 새로 만든 축약형(한 화면,
  CSV 번들 로드 없이 12개 하드코딩 관심사)이지 진짜 "재사용"이 아니다. 온보딩을 진짜 공유하려면
  App 소유 세션이 그 파일들을 패키지(예: 새 `OnboardingKit` 또는 DesignSystem)로 옮겨야 한다 —
  Core 계약 변경과 마찬가지로 관련 세션 합의가 필요한 작업이라 이 세션에서 임의로 하지 않았다.
- **참조 문서 불일치.** 이 세션에 전달된 지시가 가리킨 `docs/gyeop-prototype.html`,
  `docs/implementation-scope.md`는 레포에 없다(레포 루트의 `gyeop-spec.md`, `implementation-scope.md`만
  존재). 카피는 `gyeop-spec.md` F1·F2 기준 임시 확정 — `OnboardingFlowView.swift`가 이미 쓰고 있는
  것과 같은 관례(프로토타입 파일이 오면 교체).
- **35MB 예산.** 지금 AppClipKit이 추가하는 의존성은 Core/DesignSystem/CardKit(어차피 계획된 것)뿐,
  서드파티 추가 없음. 관심사 카탈로그도 CSV 번들 대신 Swift 배열 12개로 하드코딩해 리소스 크기를
  줄였다. GyeopKit(MPC/UWB)·DataKit(SwiftData)은 의도적으로 의존성에서 뺐다 — 실배선 전까지는
  Mock만 쓰므로 필요 없다.
- **SKOverlay 호출 시점은 뷰 계층에서 강제된다.** `ClipInstallSuggestionView`는 `ClipStage.suggestingInstall`
  에서만 그려지고, 그 뷰 자체가 `.appClipInstallSuggestion(isPresented: true)`를 무조건 건다 —
  즉 "교환 완료 후에만 설치 제안"이 화면 라우팅 구조로 보장된다(별도의 조건 분기가 아니라 도달
  가능한 상태 자체가 이미 그 조건이다).
