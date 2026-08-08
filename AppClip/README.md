# AppClip — 타깃 자리

App Clip 타깃의 자리다. 아직 활성화하지 않는다 — 부모 앱 번들 ID·entitlements(App Clip
association)·서명이 필요해서, Developer Program 세팅이 끝난 뒤 S6 세션이 활성화한다.

활성화 절차 (S1/S6만):
1. `project.yml`의 `# --- AppClip (자리) ---` 주석 블록을 해제
2. 이 디렉토리에 `AppClipApp.swift` + entitlements 추가
3. `xcodegen generate` 후 서명 설정 확인

용도(예정): 앱 미설치 러너가 QR로 바로 카드 교환을 받는 진입점.
