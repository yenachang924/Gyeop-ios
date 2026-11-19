# 출시 전 개인정보·Apple 로그인 삭제 검증

기준: 빌드 6 소스 `3e442ccceaa5e9921bd9c48b0d7c493e6fa558a7`.

## 2026-11-20 매니페스트 보완

- 앱 전용 UserDefaults 플래그의 `CA92.1`에 더해, 같은 App Group의 App Clip 마이그레이션 데이터를 읽는 `ClipMigrationReceiver` 경로에 `1C8F.1`을 선언했다. App Clip 타깃이 제외되어 있어도 본앱의 공유 저장소 접근 경로는 남아 있으므로 함께 명시한다.
- 카드가 근처 상대 기기로 전달되는 실제 동작에 맞게 매니페스트 주석을 바로잡았다. 운영자 서버 수집 없음과 기기 밖 전송 없음은 같은 의미가 아니다.
- Windows에서 plist 구조와 선언 이유·현재 접근 경로를 정적으로 대조했다. 최종 Archive의 Xcode 개인정보 보고서와 업로드 검증은 Mac에서 확인해야 한다. 이 보완만으로 네이티브 빌드나 심사를 통과했다고 주장하지 않는다.
- 공식 이유 정의: https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype

## 이번 변경

- 설정에 공개 개인정보처리방침과 고객지원 링크를 추가했다.
- 앱의 로컬 데이터 삭제 완료 후 Apple 로그인 연결을 사용자가 별도로 해제하는 방법을 안내한다.
- Apple 인증 취소 알림을 받으면 로컬 데이터와 앱의 Keychain 로그인 정보를 삭제한 후 처음 화면으로 돌아간다.
- 초기 데이터 로딩 중 인증 취소가 오면 로딩이 끝난 뒤 삭제를 실행한다. 삭제 실패 시 정상 앱 화면을 숨기고 다시 시도하도록 한다.
- 인증 취소를 받으면 삭제 대기 표시를 UserDefaults에 먼저 저장하며, 삭제 성공 후에만 지운다. 앱이 삭제 도중 종료되거나 삭제 실패 후 재실행돼도 대기 표시를 읽어 bootstrap 전에 정리를 재시도한다. 표시가 남아 있는 동안 기존 컬렉션은 노출하지 않는다.
- Apple 인증 완료 시 시스템이 제공한 `credential.user`와 identity token을 Keychain의 `com.gyeop.app.auth` / `appleSignInSession` 항목에 하나의 세션으로 보관한다. JWT 본문에서 사용자 식별자를 추출하지 않는다.
- 시작할 때 저장한 사용자 식별자를 Apple의 `credentialState(forUserID:)`에 조회한다. `authorized`일 때만 로컬 카드를 불러온다. `revoked`/`notFound`는 삭제 대기를 저장하고 로컬 정보를 정리하며, `transferred`는 재인증한다. 조회 오류·알 수 없는 상태는 데이터를 불러오거나 삭제하지 않고 재시도 화면을 보여 준다.
- 기존 빌드 6은 사용자 식별자가 없으므로 업데이트 후 한 번 Apple 재인증을 요구한다. 취소해도 로컬 카드·기록은 삭제하지 않으며, 실제 Apple 인증 성공 후 기존 로컬 컬렉션을 복원한다.
- 로컬 저장소 생성이 실패한 인메모리 강등 경로는 삭제 성공을 가장하지 않도록 한다. 이 경로에서 인증 취소 정리는 실패 상태로 남고, 다음 실행에서 실제 저장소가 복구되면 재시도한다.
- 서버 없는 삭제 방법은 Apple [TN3194](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple)의 수동 연결 해제 경로를 따른다. 앱 내부에서 Apple 토큰을 자동 폐기했다고 표시하지 않는다.

## 현재 검증 상태

`ReleasePrivacyUITests.swift`를 구현 변경 전에 작성했다. 기존 설정에 링크와 완료 안내가 없다는 것을 재현하도록 구성했다. Windows에서 해당 테스트 실행을 시도했지만 `xcodebuild`가 설치되어 있지 않아 실행되지 않았다. 따라서 네이티브 RED/GREEN, 빌드 성공, 테스트 통과 또는 커버리지를 확인했다고 주장하지 않는다.

`git diff --check`는 통과했다. 2026-11-20 사용자가 iMac에서 받아 검증할 수 있도록 먼저 GitHub에 올리도록 지시하여, 네이티브 검증 전 작업 브랜치로 공유한다. 이 예외는 빌드·테스트 통과나 출시 승인을 뜻하지 않는다. 시작 절차는 `release-mac-handoff.md`를 따른다.

## Mac에서 실행

프로젝트 루트에서 생성 프로젝트에 새 UI 테스트 파일을 반영한다.

```bash
xcodegen generate
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GyeopUITests/ReleasePrivacyUITests test
swift test --package-path Packages/GyeopPackages
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

`ReleasePrivacyUITests`는 설정의 링크 노출과 로컬 삭제 후 Apple 연결 해제 안내 및 초기 화면 복귀를 검증한다. 기존 `AccountDeletionServiceTests`는 SwiftData·Keychain 삭제의 실구현 검증을 담당한다. 작업 브랜치는 사용자 지시에 따라 먼저 공유하지만, 실제 배포용 Archive·서명·업로드는 네이티브 테스트와 실기기 확인 뒤 진행한다.

추가한 `AppleCredentialLaunchPolicyTests`는 상태별 시작 결정을, `AppleSignInSessionStoreTests`는 Keychain 세션 쌍의 저장·삭제·빈 값 거부·손상값 거부를 검증한다. `AccountDeletionServiceTests`에는 새 Apple 세션까지 지워지는 검증을 추가했다. 이 테스트들 역시 구현 전에 작성했지만 Windows에 `swift`가 없어 실제 RED/GREEN 실행을 확인하지 못했다.

```bash
swift test --package-path Packages/GyeopPackages --filter AppleCredentialLaunchPolicyTests
swift test --package-path Packages/GyeopPackages --filter AppleSignInSessionStoreTests
swift test --package-path Packages/GyeopPackages --filter AccountDeletionServiceTests
```

## 실기기 검증

1. Apple로 로그인하고 프로필 및 교환 기록을 만든다.
2. 설정의 개인정보처리방침·고객지원 링크가 로그인 없이 열리는지 확인한다.
3. 계정 삭제를 실행한다. 삭제 완료 안내가 나온 뒤 Apple 연결 해제 안내 버튼이 공식 지원 페이지를 여는지 확인한다. 완료 후 로그인 화면으로 돌아오는지 확인한다.
4. 다시 로그인해 데이터를 만든 뒤, iPhone 설정의 Apple 계정 > Apple로 로그인에서 겹 사용을 중단한다.
5. 겹으로 돌아왔을 때 인증 취소 알림 처리 후 로그인 화면으로 전환되고 프로필·카드·기록이 제거되는지 확인한다.
6. 삭제 도중 앱을 백그라운드로 보냈다가 복귀하는 경우와 앱을 다시 실행하는 경우도 확인한다. 삭제 실패 시 일반 컬렉션을 노출하지 않고 재시도 화면이 유지되어야 한다.

### 중단 후 재실행 회귀 확인

이 시나리오는 삭제가 끝나기 전에 프로세스가 사라져도 인증 취소 대기가 유지되는지 확인한다.

1. 시뮬레이터 또는 실기기에서 실제 Apple 로그인 상태와 저장된 카드를 만든다.
2. Xcode에서 `RootView.deleteRevokedCredentials()`의 `guard await model.deleteAccount()` 줄에 중단점을 둔다.
3. Apple 로그인 연결을 해제하고 앱으로 복귀한다. 중단점에서 `gyeop.pendingAppleCredentialRevocation` UserDefaults 값이 `true`인지 확인한다.
4. 삭제를 완료하지 않은 상태에서 앱 프로세스를 종료한다. 중단점을 비활성화하고 앱을 다시 실행한다.
5. 기존 컬렉션이 나타나지 않고 정리가 먼저 실행되는지 확인한다. 성공하면 로그인 화면이 나오고 대기 값이 `false`가 되어야 한다.
6. 실제 저장소 삭제 실패를 재현할 수 있는 진단 빌드에서는 실패·강제 종료·재실행 순서에도 대기 값이 유지되고 재시도 화면이 나타나는지 확인한다.

현재 UI 테스트 타깃은 별도 프로세스이며 앱의 영속 UserDefaults나 실제 저장소 삭제 실패를 직접 주입할 수 없다. 위 경로를 검증했다고 가장하는 디버그 전용 자동 통과 훅은 추가하지 않았다. 이 재실행 검증은 Mac/iOS 환경에서 실제 수행해야 한다.

Apple 시스템 인증 취소 알림과 삭제 실패 경로는 현재 UI 자동화 테스트에서 인위적으로 주입하지 않는다. 실제 iOS 동작 확인이 남아 있다. 로컬 삭제 후에도 상대 기기에 이미 전달한 카드는 상대가 보관할 수 있다.

### 종료 중 취소·기존 빌드 업그레이드 확인

- 앱을 완전히 종료한 뒤 Apple 설정에서 겹의 연결을 해제한다. 다시 실행했을 때 Apple 상태 조회 결과를 통해 기존 컬렉션을 표시하기 전에 로컬 삭제 후 로그인 화면으로 이동해야 한다.
- Apple 상태 조회를 완료할 수 없는 연결 상황에서는 재시도 화면만 표시하고 로컬 카드나 기록을 삭제하지 않아야 한다. 연결 복구 후 재시도하면 올바른 상태에 따라 복원 또는 삭제해야 한다.
- 빌드 6에서 카드·기록을 만든 후 앱을 제거하지 말고 새 빌드로 업데이트한다. 첫 실행은 재로그인을 요구하고 기존 컬렉션을 노출하지 않아야 한다. Apple 인증을 취소하면 데이터는 남아 있어야 하며, 같은 Apple 계정으로 인증 성공하면 이전 컬렉션을 복원해야 한다.
- 새 Keychain 세션을 보관한 후 앱의 계정 삭제를 실행하면 이전 `appleIDToken`과 새 `appleSignInSession` 항목이 모두 삭제되어야 한다.
