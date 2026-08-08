import Foundation

/// 프리뷰·테스트·첫 실행 데모용 샘플 데이터.
/// 날짜는 전부 고정값 — 프리뷰 스냅샷과 테스트가 흔들리지 않게.
public enum MockData {
    /// 기준 시각: 2026-08-01 00:00 KST 부근 (고정)
    public static let referenceDate = Date(timeIntervalSince1970: 1_785_000_000)

    /// 4기 시즌 (수료일까지 D-day 계산의 기준)
    public static let season = Season(
        name: "Apple Developer Academy 4기",
        startDate: Date(timeIntervalSince1970: 1_772_000_000),
        endDate: Date(timeIntervalSince1970: 1_797_600_000)
    )

    public static let sampleProfiles: [RunnerProfile] = [
        RunnerProfile(
            id: "runner-haram",
            nickname: "하람",
            tagline: "퇴근하고 클라이밍 가실 분",
            emoji: "🧗",
            interests: ["클라이밍", "보드게임", "커피"],
            leisureStyle: LeisureStyle(energy: .active, venue: .indoor),
            createdAt: referenceDate
        ),
        RunnerProfile(
            id: "runner-doyun",
            nickname: "도윤",
            tagline: "영일대 일몰 수집 중",
            emoji: "🌅",
            interests: ["사진", "커피", "여행"],
            leisureStyle: LeisureStyle(energy: .calm, venue: .outdoor),
            createdAt: referenceDate
        ),
        RunnerProfile(
            id: "runner-seyeon",
            nickname: "세연",
            tagline: "보드게임 정원 채우러 왔습니다",
            emoji: "🎲",
            interests: ["보드게임", "독서", "요리"],
            leisureStyle: LeisureStyle(energy: .calm, venue: .indoor),
            createdAt: referenceDate
        ),
    ]

    public static let sampleCards: [CardSnapshot] =
        sampleProfiles.map { MockCardGenerator().makeCard(from: $0) }

    /// 컬렉션 데모용 겹 기록 (최신순 정렬 전제와 어긋나지 않게 시간차를 둔다)
    public static let sampleGyeops: [GyeopRecord] =
        sampleCards.enumerated().map { index, card in
            let occurredAt = referenceDate.addingTimeInterval(TimeInterval(index) * 86_400)
            return GyeopRecord(
                id: GyeopID.make(
                    runnerA: "runner-me",
                    runnerB: card.ownerID,
                    serverCorrectedDate: occurredAt
                ),
                counterpartCard: card,
                method: .mock,
                occurredAt: occurredAt
            )
        }
}
