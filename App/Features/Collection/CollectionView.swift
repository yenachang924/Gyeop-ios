import CardKit
import Core
import DesignSystem
import SwiftUI

/// 나의 카드 (홈) — 내 카드 + 겹에서 받은 카드들. (F58: "컬렉션"에서 개명)
///
/// F40: 배치를 애플 순정 앱 관습에 맞췄다. 큰 내비게이션 타이틀, 섹션 헤더는 시스템
/// 위계(`title3`)로, **주요 액션(맞대기)은 하단 고정 캡슐**로 — 미리 알림의
/// "새로운 미리 알림", 메모의 작성 버튼이 하단에 사는 것과 같은 자리다. 툴바 아이콘
/// 하나로는 이 앱의 유일한 주인공 액션이 눈에 띄지 않았다.
struct CollectionView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedCard: CardSnapshot?
    @State private var showingExchange = false
    @State private var showingSettings = false
    /// 삭제 확인을 기다리는 받은 카드 (F65) — 파괴적 액션은 alert로 붙잡는다 (F47 관례).
    @State private var pendingDeletion: GyeopRecord?
    /// 컬렉션 ↔ 카드 상세 줌 전환 — 시스템 zoom 전환이 matchedGeometry 페어링을 대신한다.
    @Namespace private var cardZoom

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    header

                    if let myCard = model.myCard {
                        myCardSection(myCard)
                    }

                    collectedSection
                }
                .padding(DS.Spacing.m)
            }
            .background(DS.Palette.background)
            // 제목과 설정이 같은 줄에 앉는다 (F65 — App Store 투데이·피트니스 요약 문법).
            // 시스템 내비게이션 바는 쓰지 않는다 — 큰 타이틀 위에 뜨던 설정 버튼이 어긋나 보였다.
            .toolbar(.hidden, for: .navigationBar)
            // 주요 액션은 하단 고정 (F40) — 아이콘도 크게
            .safeAreaInset(edge: .bottom) {
                exchangeButton
            }
            // 시트는 블러 유리로 통일 (F59) — 뒤의 카드 색이 은은하게 비친다.
            // 교환 시트는 전체 화면 성격이라 제외.
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card, myCard: model.myCard)
                    .navigationTransition(.zoom(sourceID: card.id, in: cardZoom))
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(DS.Radius.card)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingExchange, onDismiss: {
                Task { await model.enterCollection() }
            }) {
                ExchangeView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(DS.Radius.card)
                    .presentationDragIndicator(.visible)
            }
            // 받은 카드 삭제 (F65) — 되돌릴 수 없으므로 alert로 확인 (F47 관례)
            .alert(
                "이 카드를 삭제할까요?",
                isPresented: .init(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                presenting: pendingDeletion
            ) { record in
                Button("삭제", role: .destructive) {
                    Task { await model.deleteGyeop(record) }
                }
                Button("취소", role: .cancel) {}
            } message: { record in
                Text("\(record.counterpartCard.nickname)님의 카드와 겹 기록이 사라져요. 되돌릴 수 없어요.")
            }
        }
    }

    /// 큰 제목 + 설정이 한 줄 (F65 — App Store 투데이 문법).
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("나의 카드")
                .font(DS.Typo.largeTitle)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                showingSettings = true
            } label: {
                Label("설정", systemImage: "gearshape")
                    .labelStyle(.iconOnly)
                    .font(DS.Typo.actionIcon)
                    .frame(minWidth: DS.minTapTarget, minHeight: DS.minTapTarget)
            }
            // 무채 크롬 — 이 화면의 빨강은 주인공 액션(맞대기) 하나뿐 (U1 원칙 1)
            .tint(.primary)
            .accessibilityIdentifier("collection.settings")
        }
    }

    private var exchangeButton: some View {
        Button {
            showingExchange = true
        } label: {
            Label {
                Text("맞대기")
                    .font(DS.Typo.headline)
            } icon: {
                Image(systemName: "person.line.dotted.person.fill")
                    // 아이콘을 라벨보다 한 급 크게 (F40)
                    .font(DS.Typo.actionIcon)
            }
            .frame(maxWidth: .infinity, minHeight: DS.Layout.primaryActionHeight)
        }
        .dsProminentButton()
        .controlSize(.large)
        .padding(.horizontal, DS.Spacing.m)
        .padding(.bottom, DS.Spacing.s)
        .accessibilityIdentifier("collection.exchange")
        .frame(maxWidth: .infinity)
        // F67: 받은 카드가 맞대기 캡슐 밑을 지날 때도 읽히는 하단 페이드 바
        .dsBottomBarFade()
    }

    /// 내 카드는 홈에서 바로 뒤집는다 (F61 — 소유자 목업): 섹션 헤더 없이 카드가
    /// 화면 상단의 주인공으로 서고, 상세 시트를 거치지 않는다. 공유는 받은 카드
    /// 상세와 달리 카드 자체가 목적이라 이 화면에는 두지 않는다.
    private func myCardSection(_ card: CardSnapshot) -> some View {
        VStack(spacing: DS.Spacing.s) {
            CardFlipView(card: card)
                // "본인의 영역" — 내 카드에만 은은한 쉬머링 (F7)
                .overlay { ShimmerFrame().allowsHitTesting(false) }
                .frame(maxWidth: DS.Layout.homeMyCardMaxWidth)
                .accessibilityIdentifier("collection.myCard")
            Text("카드를 탭하면 뒤집혀요")
                .font(DS.Typo.footnote)
                .foregroundStyle(DS.Palette.secondaryText)
                .accessibilityHidden(true) // CardFlipView가 힌트를 전달한다
        }
        .frame(maxWidth: .infinity)
    }

    private var collectedSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("받은 카드")
                    .font(DS.Typo.section)
                if !model.gyeops.isEmpty {
                    // 개수 표기는 애플 순정 목록 관습 (연락처·앨범)
                    Text("\(model.gyeops.count)")
                        .font(DS.Typo.section)
                        .foregroundStyle(DS.Palette.secondaryText)
                }
            }

            if model.gyeops.isEmpty {
                ContentUnavailableView(
                    "아직 겹이 없어요",
                    systemImage: "person.2",
                    description: Text("옆 사람과 아이폰을 맞대보세요. 그게 전부입니다.")
                )
            } else {
                LazyVGrid(
                    // 150 → 180: 카드 전반 크기 상향 (F54, 소유자 "20% 정도 크게")
                    columns: [GridItem(.adaptive(minimum: 180), spacing: DS.Spacing.s)],
                    spacing: DS.Spacing.s
                ) {
                    ForEach(model.gyeops) { gyeop in
                        Button {
                            selectedCard = gyeop.counterpartCard
                        } label: {
                            CardView(card: gyeop.counterpartCard)
                        }
                        .buttonStyle(.plain)
                        // 받은 카드 삭제 (F65) — 길게 눌러 지우는 시스템 관례 (사진·메시지)
                        .contextMenu {
                            Button("카드 삭제", systemImage: "trash", role: .destructive) {
                                pendingDeletion = gyeop
                            }
                        }
                        .matchedTransitionSource(id: gyeop.counterpartCard.id, in: cardZoom)
                        .accessibilityIdentifier("collection.card.\(gyeop.counterpartCard.nickname)")
                    }
                }
            }
        }
    }
}

/// 내 카드 주변을 도는 은은한 광택 테두리 (F7 — 쉬머링 ~4%). 라이트·다크 공통으로
/// 액센트 틴트를 쓴다 — 흰 광택은 라이트 배경에서 사라진다. 강도는 `DS.Opacity.shimmer`,
/// 실기기 체감 튜닝 대상. Reduce Motion에서는 회전 없이 고정 광택만 남는다.
private struct ShimmerFrame: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinning = false

    var body: some View {
        AngularGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: DS.Palette.accent, location: 0.22),
                .init(color: .clear, location: 0.5),
                .init(color: DS.Palette.accent, location: 0.72),
                .init(color: .clear, location: 1),
            ],
            center: .center
        )
        // 그라디언트 면을 돌리고 테두리 모양으로 오려낸다 — 모서리가 회전에 어긋나지 않는다.
        .scaleEffect(1.6)
        .rotationEffect(.degrees(spinning ? 360 : 0))
        .mask { RoundedRectangle(cornerRadius: DS.Radius.card).strokeBorder(lineWidth: 3) }
        .opacity(DS.Opacity.shimmer)
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                spinning = true
            }
        }
    }
}

#Preview {
    CollectionView()
        .environment(
            AppModel(
                cardGenerator: MockCardGenerator(),
                repository: MockGyeopRepository(seededGyeops: MockData.sampleGyeops)
            )
        )
}
