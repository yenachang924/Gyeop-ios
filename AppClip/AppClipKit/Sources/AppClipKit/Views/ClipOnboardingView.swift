import Core
import DesignSystem
import SwiftUI

/// 클립 전용 축약 온보딩 — 닉네임·관심사(최대 5)·성향을 한 화면에서 받는다.
/// App의 3단계 온보딩(OnboardingFlowView)과 같은 DesignSystem 토큰·문구 톤을 따르되,
/// 화면 수를 줄인 건 의도적이다: App Clip은 설치 없이 바로 핵심 동작(카드 교환)까지
/// 가야 마찰이 없다는 게 Apple 가이드이자 이 제품의 "설치 전 가치 체감" 주장과도 맞는다.
///
/// ⚠️ 카피는 gyeop-prototype.html 부재로 gyeop-spec.md F1 기준 임시 확정 —
/// 프로토타입 파일이 커밋되면 그 카피로 교체할 것 (App 쪽과 동일한 관례).
public struct ClipOnboardingView: View {
    let inviterNickname: String?
    let onCreate: (_ nickname: String, _ tagline: String, _ emoji: String, _ interests: [String], _ style: LeisureStyle) async -> Void

    @State private var nickname = ""
    @State private var tagline = ""
    @State private var emoji = ""
    @State private var interests: [String] = []
    @State private var style: LeisureStyle?
    @State private var isCreating = false

    public init(
        inviterNickname: String?,
        onCreate: @escaping (_ nickname: String, _ tagline: String, _ emoji: String, _ interests: [String], _ style: LeisureStyle) async -> Void
    ) {
        self.inviterNickname = inviterNickname
        self.onCreate = onCreate
    }

    private var canCreate: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
            && !emoji.isEmpty
            && !interests.isEmpty
            && style != nil
    }

    public var body: some View {
        Form {
            Section {
                Text(headline)
                    .font(DS.Typo.title)
                Text("빠르게 카드만 만들고 바로 교환할게요")
                    .font(DS.Typo.body)
                    .foregroundStyle(DS.Palette.secondaryText)
            }

            Section("닉네임") {
                TextField("상대가 부를 이름", text: $nickname)
                    .accessibilityIdentifier("clip.onboarding.nickname")
            }

            Section("한 줄") {
                TextField("예: 퇴근하고 클라이밍 가실 분", text: $tagline)
                    .accessibilityIdentifier("clip.onboarding.tagline")
            }

            Section("대표 이모지 — 하나만 탭") {
                emojiGrid
            }

            Section("관심사 — 최대 \(UserProfile.maxInterests)개") {
                interestGrid
            }

            Section("여가 성향") {
                styleGrid
            }

            Section {
                Button {
                    isCreating = true
                    Task {
                        await onCreate(nickname, tagline, emoji, interests, style ?? LeisureStyle(energy: .calm, venue: .indoor))
                        isCreating = false
                    }
                } label: {
                    if isCreating {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                    } else {
                        Text("카드 만들고 교환하기")
                            .font(DS.Typo.headline)
                            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                    }
                }
                .disabled(!canCreate || isCreating)
                .accessibilityIdentifier("clip.onboarding.createCard")
            }
        }
    }

    private var headline: String {
        if let inviterNickname {
            return "\(inviterNickname)님이 카드를 건넸어요"
        }
        return "카드를 주고받을 준비를 할게요"
    }

    private var emojiGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: DS.minTapTarget), spacing: DS.Spacing.xs)],
            spacing: DS.Spacing.xs
        ) {
            ForEach(ClipInterestCatalog.all) { icon in
                Button {
                    emoji = icon.emoji
                } label: {
                    Text(icon.emoji)
                        .font(DS.Typo.title)
                        .frame(minWidth: DS.minTapTarget, minHeight: DS.minTapTarget)
                        .background(
                            emoji == icon.emoji ? DS.Palette.accent.opacity(0.25) : .clear,
                            in: RoundedRectangle(cornerRadius: DS.Radius.chip)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("이모지 \(icon.name)")
                .accessibilityAddTraits(emoji == icon.emoji ? .isSelected : [])
                .accessibilityIdentifier("clip.onboarding.emoji.\(icon.name)")
            }
        }
    }

    private var interestGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 96), spacing: DS.Spacing.s)],
            spacing: DS.Spacing.s
        ) {
            ForEach(ClipInterestCatalog.all) { icon in
                interestChip(icon)
            }
        }
    }

    private func interestChip(_ icon: ClipInterest) -> some View {
        let isSelected = interests.contains(icon.name)
        let isFull = interests.count >= UserProfile.maxInterests

        return Button {
            if isSelected {
                interests.removeAll { $0 == icon.name }
            } else if !isFull {
                interests.append(icon.name)
            }
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                Text(icon.emoji)
                Text(icon.name)
                    .font(DS.Typo.body)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? DS.Palette.accent : .secondary)
        .disabled(!isSelected && isFull)
        .accessibilityLabel("관심사 \(icon.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("clip.onboarding.interest.\(icon.name)")
    }

    private var styleGrid: some View {
        Grid(horizontalSpacing: DS.Spacing.s, verticalSpacing: DS.Spacing.s) {
            ForEach(LeisureStyle.Energy.allCases, id: \.self) { energy in
                GridRow {
                    ForEach(LeisureStyle.Venue.allCases, id: \.self) { venue in
                        styleCell(LeisureStyle(energy: energy, venue: venue))
                    }
                }
            }
        }
    }

    private func styleCell(_ candidate: LeisureStyle) -> some View {
        Button {
            style = candidate
        } label: {
            Text(candidate.label)
                .font(DS.Typo.headline)
                .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
        }
        .buttonStyle(.bordered)
        .tint(style == candidate ? DS.Palette.accent : .secondary)
        .accessibilityLabel("여가 성향 \(candidate.label)")
        .accessibilityIdentifier("clip.onboarding.style.\(candidate.energy.rawValue)-\(candidate.venue.rawValue)")
    }
}

#Preview {
    ClipOnboardingView(inviterNickname: "하람") { _, _, _, _, _ in }
}
