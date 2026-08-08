import CardKit
import Core
import DesignSystem
import SwiftUI

/// 카드 맞대기 화면. `ExchangeSession` 이벤트 스트림만 구독한다 —
/// MPC/UWB 세부는 GyeopKit에, Mock 여부는 AppModel 조립에 갇힌다.
struct ExchangeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase: Equatable {
        case searching
        case connecting(name: String)
        /// "겹!" 융합 연출 (결정 R7) — 끝나면 completed로 넘어간다.
        case merging(GyeopRecord)
        case completed(GyeopRecord)
        case failed(ExchangeFailure)
    }

    @State private var phase: Phase = .searching
    @State private var session: (any ExchangeSession)?
    /// 재시도마다 증가 — `.task(id:)`가 새 세션으로 판을 다시 돈다.
    @State private var attempt = 0

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(DS.Spacing.m)
                .background(DS.Palette.background)
                .navigationTitle("맞대기")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("닫기") {
                            Task { await session?.cancel() }
                            dismiss()
                        }
                        // 크롬은 무채 — 이 화면의 빨강은 겹 성립 순간과 CTA 몫이다 (U1 원칙 1)
                        .tint(.primary)
                        .accessibilityIdentifier("exchange.close")
                    }
                }
                .task(id: attempt) { await run() }
                .animation(reduceMotion ? nil : DS.Motion.standard, value: phase)
        }
        .interactiveDismissDisabled(isInProgress)
    }

    private var isInProgress: Bool {
        switch phase {
        case .searching, .connecting, .merging: true
        case .completed, .failed: false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .searching:
            progress(
                title: "주변 상대를 찾는 중",
                caption: "상대도 맞대기 화면을 열고, 아이폰을 가까이 맞대 주세요"
            )

        case .connecting(let name):
            progress(title: "\(name)님과 연결 중", caption: "그대로 잠시만요")

        case .merging(let record):
            momentView(record)

        case .completed(let record):
            completedView(record)

        case .failed(let failure):
            failedView(failure)
        }
    }

    // Dynamic Type 극단에서 제목+캡션이 화면을 넘칠 수 있어 completedView/failedView와
    // 같은 패턴으로 스크롤 가능하게 한다.
    private func progress(title: String, caption: String) -> some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                ProgressView()
                    .controlSize(.large)
                VStack(spacing: DS.Spacing.s) {
                    Text(title)
                        .font(DS.Typo.title)
                    Text(caption)
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Spacing.xl)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(caption)")
    }

    /// "겹!" 순간 — 융합 연출이 끝나면 완료 화면으로. 연출 뷰가 Reduce Motion을 자체 처리한다.
    private func momentView(_ record: GyeopRecord) -> some View {
        VStack(spacing: DS.Spacing.l) {
            Spacer()
            GyeopMomentView(
                myCard: model.myCard ?? record.counterpartCard,
                counterpartCard: record.counterpartCard
            ) {
                phase = .completed(record)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    // Dynamic Type 극단에서 내용이 화면을 넘칠 수 있다 — 내용은 스크롤,
    // 행동 버튼은 safeAreaInset으로 항상 화면 안에 남긴다.
    private func completedView(_ record: GyeopRecord) -> some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                VStack(spacing: DS.Spacing.s) {
                    Text("겹이 쌓였어요")
                        .font(DS.Typo.largeTitle)
                        .foregroundStyle(DS.Palette.success)
                    Text("\(record.counterpartCard.nickname)님의 카드를 받았습니다")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                }

                CardView(card: record.counterpartCard)
                    .padding(.horizontal, DS.Spacing.xl)

                if let myCard = model.myCard {
                    let shared = record.counterpartCard.sharedInterests(with: myCard)
                    if !shared.isEmpty {
                        // 겹친 칩 순차 페이드인 (결정 R8: 0.3s)
                        StaggeredOverlapChips(items: shared)
                            .padding(.horizontal, DS.Spacing.xl)
                    }
                    if !myCard.emoji.isEmpty, myCard.emoji == record.counterpartCard.emoji {
                        // 이모지 겹침도 "겹침" — 와인 톤(overlapInk)으로, 빨강은 제목·CTA 둘만 (U1)
                        Text("이모지도 겹쳤어요 \(myCard.emoji) — 오늘의 이스터에그")
                            .font(DS.Typo.headline)
                            .foregroundStyle(DS.Palette.overlapInk)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                dismiss()
            } label: {
                Text("컬렉션으로")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("exchange.done")
        }
    }

    private func failedView(_ failure: ExchangeFailure) -> some View {
        ScrollView {
            // 실패는 거절이 아니다 — 경고색 없이 중립으로 (DS.Palette.failure 원칙)
            VStack(spacing: DS.Spacing.s) {
                Text(failureTitle(failure))
                    .font(DS.Typo.title)
                    .foregroundStyle(DS.Palette.failure)
                    .multilineTextAlignment(.center)
                Text(failureCaption(failure))
                    .font(DS.Typo.body)
                    .foregroundStyle(DS.Palette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, DS.Spacing.xl)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                phase = .searching
                attempt += 1
            } label: {
                Text("다시 맞대기")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("exchange.retry")
        }
    }

    private func failureTitle(_ failure: ExchangeFailure) -> String {
        switch failure {
        case .peerLost: "상대와 연결이 끊겼어요"
        case .timedOut: "주변에서 상대를 찾지 못했어요"
        case .transferCorrupted: "카드가 제대로 오지 않았어요"
        case .cancelled: "맞대기를 중단했어요"
        }
    }

    private func failureCaption(_ failure: ExchangeFailure) -> String {
        switch failure {
        case .peerLost, .transferCorrupted:
            "아이폰을 더 가까이 맞대고 다시 시도해 주세요"
        case .timedOut:
            "상대도 맞대기 화면을 열었는지, 설정 > 겹에서 로컬 네트워크가 허용돼 있는지 확인해 주세요"
        case .cancelled:
            "준비되면 다시 맞대 주세요"
        }
    }

    private func run() async {
        phase = .searching
        guard let session = model.startExchange() else {
            dismiss()
            return
        }
        self.session = session
        do {
            try await session.start(broadcasting: model.myCard ?? MockData.sampleCards[0])
        } catch {
            // 시작 실패(페이로드 상한 초과 등)는 이 판의 실패로 취급
            Log.nearby.error("교환 시작 실패: \(error)")
            phase = .failed(.transferCorrupted)
            return
        }
        for await event in session.events {
            switch event {
            case .searching:
                phase = .searching
            case .peerFound(let name), .connecting(let name):
                phase = .connecting(name: name)
            case .cardReceived:
                break // completed가 바로 뒤따른다
            case .completed(let record):
                await model.recordGyeop(record)
                phase = .merging(record)
            case .failed(let failure):
                if failure == .cancelled { return } // 닫기 버튼 경로 — 화면도 곧 사라진다
                phase = .failed(failure)
            }
        }
    }
}

/// 겹친 관심사 칩 — 하나씩 0.3s 페이드인, 칩 사이 `chipStaggerStep` 간격 (결정 R8).
/// Reduce Motion에서는 전부 즉시 표시.
private struct StaggeredOverlapChips: View {
    let items: [String]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 96), spacing: DS.Spacing.s)],
            spacing: DS.Spacing.s
        ) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                Text(item)
                    .font(DS.Typo.headline)
                    .foregroundStyle(DS.Palette.overlapInk)
                    .padding(.horizontal, DS.Spacing.s)
                    .padding(.vertical, DS.Spacing.xs)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                    .background(DS.Palette.overlapBg, in: Capsule())
                    .overlay(Capsule().strokeBorder(DS.Palette.overlapLine))
                    .opacity(shown ? 1 : 0)
                    .animation(
                        reduceMotion
                            ? nil
                            : .smooth(duration: DS.Motion.Moment.chipFadeDuration)
                                .delay(Double(index) * DS.Motion.Moment.chipStaggerStep),
                        value: shown
                    )
            }
        }
        .onAppear { shown = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("겹치는 관심사 \(items.joined(separator: ", "))")
    }
}

#Preview {
    ExchangeView()
        .environment(
            AppModel(
                cardGenerator: MockCardGenerator(),
                repository: MockGyeopRepository()
            )
        )
}
