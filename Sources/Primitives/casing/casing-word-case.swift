public extension Casing {
    enum WordCase:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case lower
        case upper
        case capitalized
    }
}

extension Casing.WordCase {
    @inline(__always)
    func apply(
        to value: String
    ) -> String {
        switch self {
        case .lower:
            value.lowercased()

        case .upper:
            value.uppercased()

        case .capitalized:
            capitalized_case_word(
                value
            )
        }
    }
}
