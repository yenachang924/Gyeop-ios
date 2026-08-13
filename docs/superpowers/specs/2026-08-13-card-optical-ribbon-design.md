# 카드 연속 광학 리본 배경 설계

## 목적

카드가 개별 원형 유리 오브젝트를 얹은 표면이 아니라, 앞·뒤 전체에 이어지는 Apple 배경화면식 광학 리본 표면으로 읽히게 한다. 사용자가 준 레퍼런스의 정보 구도를 유지한다.

## 범위

- F76의 `CardBackGlassLayers`와 `CardInterestAssetStack`을 제거한다.
- `CardVisual`의 이미 존재하는 결정적 `RibbonParameters`와 5×5 메시 색 배열을 카드 앞·뒤에 공통 적용한다.
- 앞면은 우측 상단 대표 이모지와 좌측 하단 닉네임·소개를 유지한다.
- 뒷면은 세로 중앙 좌측 MBTI와 관심사 이름 캡슐만 유지한다.

## 비범위

- 이미지 에셋, CSS·HTML 렌더링, 새 색·폰트·간격 토큰, 배경 애니메이션은 추가하지 않는다.
- 카드 비율, 플립 동작, Dynamic Type 동작, 접근성 라벨, `CardVisual`의 4.5:1 대비 보정은 바꾸지 않는다.

## 설계

`CardVisual(seed:)`는 이미 두 리본의 각도·폭·오프셋·앵커를 시드에서 결정한다. 이 값으로 생성된 25개 메시 색을 `CardView`와 `CardBackView` 모두에 적용해, 플립 전후에 배경이 한 장의 표면처럼 이어진다. 색상 계산은 초기화 시 한 번만 일어나며, 정지 상태에는 추가 합성 레이어나 반복 모션이 없다.

`CardBackView`는 Material 한 겹과 공통 MeshGradient만 사용한다. MBTI 및 관심사 캡슐의 기존 정렬을 보존하고, 관심사 대표 이모지의 별도 우측 스택은 제거한다.

## 검증

- 순수 테스트: 같은 시드는 동일한 리본 파라미터와 메시 색을, 서로 다른 시드는 적어도 하나의 리본 변주를 낸다.
- 패키지: `cd Packages/GyeopPackages && swift test`.
- 앱: iPhone 17 Pro 빌드와 `ScreenshotAndAccessibilityUITests` 전체 흐름을 실행하고, 카드 앞·뒤·다크 모드·접근성 크기 스크린샷을 확인한다.
