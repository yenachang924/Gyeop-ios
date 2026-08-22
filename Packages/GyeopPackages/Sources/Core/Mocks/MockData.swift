import Foundation

/// 프리뷰·테스트·첫 실행 데모용 샘플 데이터.
/// 날짜는 전부 고정값 — 프리뷰 스냅샷과 테스트가 흔들리지 않게.
public enum MockData {
    /// 기준 시각: 2026-08-01 00:00 KST 부근 (고정)
    public static let referenceDate = Date(timeIntervalSince1970: 1_785_000_000)

    /// 관심사는 반드시 `InterestCatalog` 안의 이름을 쓴다. 겹침 판정이 정확한 문자열
    /// 비교라(`CardSnapshot.sharedInterests`) 카탈로그 밖의 이름을 두면 이 상대와는
    /// **무엇을 골라도 겹이 잡히지 않는다** — 데모와 심사 스크린샷에서 이 앱의 핵심
    /// 순간인 "겹치는 관심사"가 늘 비어 보이던 원인.
    public static let sampleProfiles: [UserProfile] = [
        UserProfile(
            id: "user-haram",
            nickname: "하람",
            tagline: "퇴근하고 클라이밍 가실 분",
            emoji: "🧗",
            interests: ["운동", "게임", "카페"],
            mbti: MBTI(code: "ESTP"),
            createdAt: referenceDate
        ),
        UserProfile(
            id: "user-doyun",
            nickname: "도윤",
            tagline: "영일대 일몰 수집 중",
            emoji: "🌅",
            interests: ["사진", "카페", "여행"],
            mbti: MBTI(code: "INFP"),
            createdAt: referenceDate
        ),
        UserProfile(
            id: "user-seyeon",
            nickname: "세연",
            tagline: "보드게임 정원 채우러 왔습니다",
            emoji: "🎲",
            interests: ["게임", "독서", "요리"],
            mbti: nil,
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
                    participantA: "user-me",
                    participantB: card.ownerID,
                    serverCorrectedDate: occurredAt
                ),
                counterpartCard: card,
                method: .mock,
                occurredAt: occurredAt
            )
        }
}
