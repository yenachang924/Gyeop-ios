# 개발 세션 인수인계 — 겹(Gyeop) D1 시작

기획은 이 레포(`Idea`)에서 끝났다. 개발은 새 레포 + 새 세션에서 시작한다. 이 문서는 그 다리다.

## 1. 시작 전 준비 (5분, 직접)

1. **새 레포 생성:** github.com에서 `gyeop-ios` (private) 생성 — 세션의 GitHub 연동 권한상 Claude가 대신 못 만듦
2. 아래 "새 에이전트에게 넣을 문서" 표의 **필수** 항목을 새 레포 `docs/`로 복사 (`README.md`만 루트로)
3. **Apple Developer Program 등록 상태 확인** — 미등록이면 지금 신청 (승인 24~48h, 전체 일정의 크리티컬 패스)
4. 실기기 2대 확보 (MPC/UWB는 시뮬레이터 불가)

## 1-1. 새 에이전트에게 넣을 문서 — 목록

새 개발 세션은 이 대화의 맥락이 전혀 없다. 아래 순서·구분대로 넘긴다. **필수**는 D1부터 없으면 안 되는 것, **참고**는 필요할 때 찾아보는 것, **넣지 않음**은 이 프로젝트와 무관하거나 이미 흡수된 것.

| 문서 | 구분 | 왜 필요한가 |
|---|---|---|
| `gyeop-spec.md` | **필수** | 제품 정의 그 자체 — 문제 정의, 해결 원칙(헌법), F1~F8 기능 명세. 이게 없으면 에이전트가 "무엇을 왜 만드는지"를 모른다 |
| `implementation-scope.md` | **필수** | 지금 확정된 범위 — 고도화 레벨(Lv.1~3)과 ★출시 표시, 5일 데일리 일정, 컷라인 스택. **가장 자주 참조하게 될 문서** |
| `gyeop-architecture.html` | **필수** | 시스템 아키텍처(P2P 교환→동기화 흐름)와 ERD. 코드 구조·모듈 경계·데이터 모델을 그림으로 고정한 것 — 텍스트 명세보다 구현 시 혼동을 줄인다 |
| `snippets/Telemetry.swift` | **필수** | D1에 Core 모듈로 그대로 옮겨 넣을 코드. 나중에 넣으면 아티클에 쓸 측정치가 안 남는다 |
| `implementation-checklist.md` | 참고 | 기술 항목별 "공식문서 → 구현 → 남는 경험" 매핑. 특정 기술(UWB, Live Activity 등) 붙일 때 펼쳐 본다 |
| `README.md` | 참고 | 대외용 설명 — 새 레포의 루트 README로 그대로 사용 |
| `tech-article-plan.md` | 참고 | 언제 어떤 계측을 남길지, 아티클 6편 계획. D2부터 계측 심을 때 확인 |
| `gyeop-operator-spec.md` | 참고 | v0.2~에서 겹 오퍼레이터(운영 에이전트) 붙일 때. D1~D5엔 불필요 |
| `mentor-proposal.md`, `mentor-prep.md` | 넣지 않음 | 멘토 미팅용 — 개발 에이전트가 알 필요 없음 |
| `daangn-application.md` | 넣지 않음 | 채용 지원용 — 별도로 본인이 직접 참고 |
| `idea-backlog.md`, `mobile-app-ideas.md`, `runner-app-plan.md` | 넣지 않음 | 폐기된 초기 아이디어·팀 CBL 연장선 초안. gyeop-spec.md가 대체함 |

**규칙:** 멘토 미팅에서 ★ 레벨이 바뀌거나 스코프가 바뀌면 `implementation-scope.md`만 갱신하고, 그 갱신된 버전을 새 세션에 다시 넣는다. 나머지 문서는 안정적이라 자주 안 바뀐다.

## 2. 개발 환경에 대한 현실적인 판단

- iOS 빌드·실기기 실행은 **Mac + Xcode에서만** 된다. 웹(원격) 세션은 코드를 짜고 푸시할 수 있지만 빌드 검증을 못 한다
- **권장: Mac에서 로컬 Claude Code로 개발 세션을 연다** — 코드 작성→빌드→실기기 확인 루프가 한자리에서 돈다. 특히 D2 MPC부터는 실기기 확인이 매 시간 필요하다
- 웹 세션을 쓴다면: 웹에서 코드 작성·푸시 → Mac에서 pull·빌드·확인의 2박자. D1(순수 SwiftUI)까지는 가능하나 D2부터는 비효율

## 3. 새 세션 시작 프롬프트 (복사해서 붙여넣기)

```
겹(Gyeop) 앱 개발을 시작한다. docs/ 폴더의 문서를 먼저 읽어라
(gyeop-spec.md = 제품 명세, implementation-scope.md = 고도화 레벨과 5일 일정,
gyeop-architecture.html = 시스템 아키텍처+ERD 도면, implementation-checklist.md
= 기술별 구현 항목 — 필요할 때 참조).

Core 모듈을 만들 때 snippets/Telemetry.swift를 그대로 옮겨 넣어라. OSLog 카테고리,
맞대기 구간 signpost, 결정적 GyeopID 헬퍼가 들어있다 — 나중에 추가하면 늦다.

요약: 애플 디벨로퍼 아카데미 러너용 앱. 아이폰을 맞대면 정체성 카드가 교환되며
만남("겹")이 기록되고, 여가 신호로 부담 없이 모인다. 5일 개발 → App Store 심사
제출 → 10일 차 출시+실사용자(러너 20명)가 목표.

기술 결정(변경 없이 따를 것): SwiftUI 100%, Swift Concurrency(Swift 6 strict),
MVVM+@Observable, SPM 멀티모듈(App/Core/DesignSystem/GyeopKit/SignalKit),
SwiftData, MultipeerConnectivity(+UWB는 v0.2), Firebase(Auth/Firestore/Functions,
리포지토리 프로토콜 뒤에 격리), APNs 직접 호출(p8), Sign in with Apple+Keychain
직접 래핑+계정 삭제(심사 필수), 에러는 최종 호출부에서만 catch, OSLog 구조화 로깅.

오늘은 D1이다. 오전 블록: Xcode 프로젝트 골격(SPM 멀티모듈) + 온보딩 플로우
(관심사 최대 5개 + 여가 성향 정적/동적×실내/실외 + 한 줄 소개).
오후 블록: 시드→MeshGradient 결정적 카드 생성(같은 입력=같은 카드) + Metal
layerEffect 질감. 저녁 블록: Developer Program·APNs p8·capability·Firebase 세팅,
앱 아이콘.

D1 완료 기준: 온보딩 입력→카드 생성이 실기기에서 60fps로 돌고, 같은 입력을
넣으면 항상 같은 카드가 나온다.
```

## 4. D1~D5 요약 (상세는 implementation-scope.md)

| 날 | 목표 |
|---|---|
| D1 | 골격 + 온보딩 + 결정적 카드 (셰이더) |
| D2 | SwiftData 모델·홈 + MPC 상태 머신·실기기 첫 교환 + 교환 UX(햅틱) |
| D3 | 인증(SiwA·이메일·Keychain) + **계정 삭제** + 신호 모델·피드 |
| D4 | 신호 조인·TTL + APNs 직접 푸시 + **심사 대비물**(데모 계정·시연 영상·스크린샷·처리방침) |
| D5 | Live Activity 로컬 + 엣지 처리 + **App Store 심사 제출** + TestFlight 내부 테스터 실사용 시작 |

컷라인 규칙: 밀리면 아래 기능을 지우지, 일정을 늘리지 않는다. 판정은 매일 저녁.

## 5. 이 레포(Idea)의 역할

기획 아카이브로 동결. 멘토 미팅 결과(★ 레벨 조정)가 나오면 implementation-scope.md만 갱신하고, 개발 관련 커밋은 전부 gyeop-ios로.
