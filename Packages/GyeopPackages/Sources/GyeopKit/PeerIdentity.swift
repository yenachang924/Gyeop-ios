import Foundation

/// 로컬 차단용 전체 ID 교환. 암호학적으로 검증된 계정 신원이나 서비스 전체 차단은 아니다.
struct PeerIdentity: Codable, Equatable, Sendable {
    static let protocolVersion = 7
    static let maximumContextBytes = 512
    let ownerID: String
    let version: Int

    init?(ownerID: String) {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        guard !ownerID.isEmpty, ownerID.utf8.count <= 128,
              ownerID.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        self.ownerID = ownerID
        version = Self.protocolVersion
    }

    var discoveryInfo: [String: String] {
        ["gyeopVersion": String(version), "ownerID": ownerID]
    }

    func encodedContext() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func fromDiscovery(_ info: [String: String]?) -> PeerIdentity? {
        guard info?["gyeopVersion"] == String(protocolVersion),
              let ownerID = info?["ownerID"] else { return nil }
        return PeerIdentity(ownerID: ownerID)
    }

    static func fromContext(_ data: Data?) -> PeerIdentity? {
        guard let data, data.count <= maximumContextBytes,
              let decoded = try? JSONDecoder().decode(PeerIdentity.self, from: data),
              decoded.version == protocolVersion else { return nil }
        return PeerIdentity(ownerID: decoded.ownerID)
    }
}
