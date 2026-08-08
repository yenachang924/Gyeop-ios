import Foundation

/// 저장 계약. 도메인·UI는 이 프로토콜만 안다 — SwiftData는 DataKit 안에 갇힌다.
///
/// 소유: DataKit 세션이 실구현(SwiftData + 이후 동기화 큐)을 제공한다.
/// 다른 세션은 `MockGyeopRepository`로 개발한다.
public protocol GyeopRepository: Sendable {
    // 내 프로필·카드
    func saveMyProfile(_ profile: UserProfile) async throws
    func myProfile() async throws -> UserProfile?
    func saveMyCard(_ card: CardSnapshot) async throws
    func myCard() async throws -> CardSnapshot?

    // 겹 기록
    /// 같은 `id`(결정적 GyeopID)로 두 번 기록해도 1건이어야 한다 (멱등).
    func record(_ gyeop: GyeopRecord) async throws
    /// 최신순
    func gyeops() async throws -> [GyeopRecord]
}

extension GyeopRepository {
    /// 컬렉션 = 겹에서 받은 카드들 (최신순, 러너당 최신 카드 1장)
    public func collectedCards() async throws -> [CardSnapshot] {
        var seenOwners = Set<String>()
        return try await gyeops().compactMap { record in
            seenOwners.insert(record.counterpartCard.ownerID).inserted
                ? record.counterpartCard
                : nil
        }
    }
}
