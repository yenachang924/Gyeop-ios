# iMac에서 출시 수정본 검증하기

2026-11-20 사용자가 먼저 GitHub에 올린 뒤 iMac에서 빌드·업로드하도록 지시한 작업본이다. 이후 별도 테스트 생략과 버전 번호 사전 수정을 요청했다. **Windows 정적 검사만 수행했으며 Xcode 빌드·테스트·실기기 검증·서명·업로드는 아직 하지 않았다.** 이 브랜치는 정식 출시 완료본이 아니다.

- 저장소: https://github.com/yenachang924/Gyeop-ios
- 작업 브랜치: `codex/app-store-release`
- 기준: 실제 TestFlight 1.0(6)의 `3e442ccceaa5e9921bd9c48b0d7c493e6fa558a7`
- 별도 패치를 적용하지 않고 아래 브랜치를 받는다.
- 기존 작업이 있는 폴더를 덮어쓰지 않고 새 폴더에서 시작한다.
- 버전 `1.0.0`, 빌드 `7`은 `project.yml`과 `App/Support/Info.plist`에 설정해 두었다. iMac에서 번호를 다시 바꿀 필요는 없다.

## 빌드·업로드만 진행하는 경우

사용자 요청에 따라 아래 테스트 절차는 별도로 실행하지 않고 진행할 수 있다. 프로젝트 생성, 실제 Archive 컴파일, 배포 서명, Apple 업로드 처리는 필요하다.

1. 아래 소스 받기 절차로 작업 브랜치를 받는다. 이미 같은 브랜치를 받은 폴더라면 `git status --short`로 로컬 변경이 없는지 확인하고 `git pull --ff-only`를 실행한다.
2. Xcode 26 이상과 XcodeGen을 준비하고 프로젝트 루트에서 `xcodegen generate`를 실행한다. 새 소스 파일을 포함하기 위한 절차다.
3. `open Gyeop.xcodeproj`로 열고 Gyeop 타깃의 개발자 Team과 자동 서명을 설정한다. Bundle ID는 `com.gyeop.app`이다.
4. Gyeop 스킴과 실제 iOS 기기용 대상을 선택한 뒤 Product → Archive를 실행한다.
5. Organizer에서 Distribute App → TestFlight & App Store를 선택한다. 정식 출시에도 사용할 빌드이므로 TestFlight Internal Only는 선택하지 않는다.
6. Apple 처리 완료 후 TestFlight 테스터 그룹에 새 빌드를 배포한다. 외부 테스팅 심사가 표시되면 제출한다.

버전과 빌드 번호를 추가로 수정할 필요는 없다. 단, 이 브랜치 공유 이후 같은 빌드 번호로 다른 업로드를 진행했다면 새 번호가 필요하다. 아래 3·4절은 테스트를 실행할 때 사용할 참고 절차다.

## 1. 소스 받기

```bash
git clone --branch codex/app-store-release --single-branch \
  https://github.com/yenachang924/Gyeop-ios.git Gyeop-ios-release
cd Gyeop-ios-release
git status --short
git log -1 --oneline
```

## 2. 도구와 시뮬레이터 확인

사용 가능한 Xcode와 iOS SDK를 설치한 iMac이 필요하다. 호환 OS는 [Apple 공식 표](https://developer.apple.com/xcode/system-requirements)를 확인한다. 현재 업로드에는 Xcode 26 이상 및 iOS 26 SDK 이상이 요구된다. iPhone의 최소 지원 OS 18과 빌드 SDK 요건은 별개다.

```bash
xcode-select -p
xcodebuild -version
command -v xcodegen
xcrun simctl list devices available
```

XcodeGen이 없다면 기존 설치본을 사용하거나 설치한다. Homebrew가 이미 있다면 `brew install xcodegen`을 사용할 수 있다. 아래 명령은 프로젝트 루트에서 실행한다.

```bash
xcodegen generate
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -showdestinations
read -r GYEOP_SIMULATOR_ID
GYEOP_DESTINATION="platform=iOS Simulator,id=$GYEOP_SIMULATOR_ID"
```

`read` 다음에는 실제 설치된 iOS 18 이상 iPhone 시뮬레이터 UUID를 붙여넣는다. 예전 문서의 특정 기기 이름이 이 iMac에도 설치되어 있다고 가정하지 않는다.

## 3. 빌드·테스트

각 명령이 실패하면 원인을 고치고 통과한 뒤 다음 단계로 간다. 이전 빌드6의 결과를 새 코드의 결과로 대신하지 않는다.

```bash
swift test --package-path Packages/GyeopPackages --enable-code-coverage
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop \
  -destination "$GYEOP_DESTINATION" clean build
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop \
  -destination "$GYEOP_DESTINATION" \
  -only-testing:GyeopUITests/ReleasePrivacyUITests \
  -only-testing:GyeopUITests/ReleaseSafetyUITests test
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop \
  -destination "$GYEOP_DESTINATION" -enableCodeCoverage YES test
```

앱과 패키지 빌드 성공, 실제 테스트 결과와 커버리지를 기록한다. 실패한 단언을 약화해서 통과시키지 않는다. Swift 패키지 변경 후 증분 빌드가 이전 결과를 재사용하지 않도록 위 clean build를 포함한다.

## 4. 실제 iPhone 두 대에서 확인

- 양쪽 모두 새 빌드를 설치한다. 교환 프로토콜7은 기존 빌드6과 교환하지 않는다.
- Apple 로그인, 기존 빌드6 데이터가 있는 상태의 재인증, 카드 만들기·수정·교환·저장을 확인한다.
- 개인정보·고객지원 링크가 열리는지, 계정 삭제 안내와 Apple 연결 해제 및 앱 종료 중 취소 후 재실행을 확인한다.
- 신고의 미리보기·메일 작성·취소·메일 앱 부재를 확인한다. 작성 화면을 열었다고 전송 완료로 표시하면 안 된다.
- 차단·재실행·해제·저장 실패를 확인한다. 차단한 상대에게 카드가 먼저 전송되거나 성공 연출에 나타나면 안 된다.
- 자세한 회귀 시나리오: [개인정보·삭제](release-privacy-validation.md), [카드 안전·교환](release-safety-validation.md).

차단은 기기에 저장된 전체 로컬 소유자 ID에 적용된다. 상대가 새 ID를 제시하는 경우까지 막는 전역 계정 정지가 아니다. 자동 필터도 모든 언어·우회 표현을 판별하지 못한다.

## 5. 새 빌드 준비와 업로드

`project.yml`과 `App/Support/Info.plist`에는 버전 `1.0.0`, 빌드 `7`을 설정해 두었다. 번호 수동 수정은 생략한다. 새 파일을 포함하도록 iMac에서 프로젝트를 다시 생성한다. 생성 `pbxproj`를 손으로 고치지 않는다.

```bash
xcodegen generate
```

Xcode에서 Release Archive를 만들고 Organizer에서 App Store Connect로 업로드한다. 실제 Apple Developer 계정과 배포 서명이 필요하다. 최종 개인정보 보고서에서 UserDefaults `CA92.1`·`1C8F.1`, ActiveKeyboards `54BD.1`이 실제 사용과 맞는지 확인한다.

App Clip은 이번 타깃·스킴에 포함하지 않는다. 제외된 기존 소스를 다시 활성화하려면 별도 교환 API 전환과 안전성 검증이 필요하다.

## 6. App Store Connect에서 마무리

- 최신 Apple Developer Program 계약과 대한민국 정보 확인을 완료한다.
- 새 빌드 처리 완료 후 iOS 버전1.0.0에 해당 빌드를 연결한다.
- 설명·스크린샷·심사 메모를 실제 검증한 바이너리와 맞춘다.
- 사용자 콘텐츠·로그인 필요성·연령 답변의 최종 적합성을 확인한다. 코드 보완이 Apple 승인 보장은 아니다.
- 심사에 추가한 뒤 최종 제출하고 접수 상태를 확인한다.

지원: https://gyeop-support.yenachang924.chatgpt.site/support/

개인정보: https://gyeop-support.yenachang924.chatgpt.site/privacy/
