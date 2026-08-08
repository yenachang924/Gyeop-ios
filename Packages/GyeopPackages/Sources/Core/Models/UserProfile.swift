import Foundation

/// 사용자 본인 프로필. 온보딩 3단계(관심사 → 성향 → 닉네임·한 줄·이모지)의 결과물이며
/// 카드 생성(`CardGenerating`)의 유일한 입력이다.
public struct UserProfile: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public var nickname: String
    /// 한 줄 소개
    public var tagline: String
    /// 원탭으로 고른 대표 이모지
    public var emoji: String
    /// 관심사 이름 (최대 5개 — `Self.maxInterests`)
    public var interests: [String]
    public var leisureStyle: LeisureStyle
    public var createdAt: Date

    public static let maxInterests = 5

    public init(
        id: String,
        nickname: String,
        tagline: String,
        emoji: String,
        interests: [String],
        leisureStyle: LeisureStyle,
        createdAt: Date
    ) {
        self.id = id
        self.nickname = nickname
        self.tagline = tagline
        self.emoji = emoji
        self.interests = interests
        self.leisureStyle = leisureStyle
        self.createdAt = createdAt
    }
}

/// 여가 성향 2×2 (정적/동적 × 실내/실외)
public struct LeisureStyle: Codable, Hashable, Sendable {
    public enum Energy: String, Codable, CaseIterable, Sendable {
        case calm
        case active

        public var label: String {
            switch self {
            case .calm: "정적"
            case .active: "동적"
            }
        }
    }

    public enum Venue: String, Codable, CaseIterable, Sendable {
        case indoor
        case outdoor

        public var label: String {
            switch self {
            case .indoor: "실내"
            case .outdoor: "실외"
            }
        }
    }

    public var energy: Energy
    public var venue: Venue

    public init(energy: Energy, venue: Venue) {
        self.energy = energy
        self.venue = venue
    }

    public var label: String { "\(energy.label)·\(venue.label)" }
}
