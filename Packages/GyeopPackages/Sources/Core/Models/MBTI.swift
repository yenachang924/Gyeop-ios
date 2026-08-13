import Foundation

/// MBTI 성격 유형 — 온보딩 2/3의 결과 (F55, 카드 리디자인·MBTI 라운드).
/// 강제하지 않는다: 건너뛰면 프로필에 없다(nil). 카드 뒷면에 4글자로만 담백하게 실리고,
/// 별명·궁합·설명 같은 부가 정보는 어디에도 붙이지 않는다 (소유자 지시).
public struct MBTI: Codable, Hashable, Sendable {
    public enum Energy: String, Codable, CaseIterable, Sendable {
        case extraversion = "E"
        case introversion = "I"

        /// 알약에 글자와 함께 앉는 일상어 낱말 — 사전어(외향형 등) 배제.
        public var word: String {
            switch self {
            case .extraversion: "외향"
            case .introversion: "내향"
            }
        }
    }

    public enum Perception: String, Codable, CaseIterable, Sendable {
        case sensing = "S"
        case intuition = "N"

        public var word: String {
            switch self {
            case .sensing: "현실"
            case .intuition: "직관"
            }
        }
    }

    public enum Judgment: String, Codable, CaseIterable, Sendable {
        case thinking = "T"
        case feeling = "F"

        public var word: String {
            switch self {
            case .thinking: "사고"
            case .feeling: "감정"
            }
        }
    }

    public enum Lifestyle: String, Codable, CaseIterable, Sendable {
        case judging = "J"
        case perceiving = "P"

        public var word: String {
            switch self {
            case .judging: "계획"
            case .perceiving: "즉흥"
            }
        }
    }

    public var energy: Energy
    public var perception: Perception
    public var judgment: Judgment
    public var lifestyle: Lifestyle

    public init(
        energy: Energy,
        perception: Perception,
        judgment: Judgment,
        lifestyle: Lifestyle
    ) {
        self.energy = energy
        self.perception = perception
        self.judgment = judgment
        self.lifestyle = lifestyle
    }

    /// "INTJ" 같은 4글자 코드 — 카드 뒷면 표기이자 저장·시드 정규형.
    public var code: String {
        energy.rawValue + perception.rawValue + judgment.rawValue + lifestyle.rawValue
    }

    /// 4글자 코드 파싱 — 영속(mbtiRaw)·전송 역직렬화용. 형식이 어긋나면 nil.
    public init?(code: String) {
        let letters = code.uppercased().map(String.init)
        guard letters.count == 4,
              let energy = Energy(rawValue: letters[0]),
              let perception = Perception(rawValue: letters[1]),
              let judgment = Judgment(rawValue: letters[2]),
              let lifestyle = Lifestyle(rawValue: letters[3])
        else { return nil }
        self.init(energy: energy, perception: perception, judgment: judgment, lifestyle: lifestyle)
    }
}
