public enum CasingPattern: Hashable, Sendable {
    case lower
    case upper
    case capitalized
    case convention(Casing)
    case mixed
    case uncased

    public static func infer(
        from original: String
    ) -> Self {
        if Case.components(original).count > 1 {
            for casing in Casing.allCases {
                switch casing {
                case .flat, .upperflat:
                    continue
                default:
                    break
                }

                if Case.convert(original, to: casing) == original {
                    return .convention(casing)
                }
            }
        }

        let cased = Array(original
        .unicodeScalars
        .filter {
                $0.properties.isUppercase || $0.properties.isLowercase
            }
        )

        guard !cased.isEmpty else {
            return .uncased
        }

        if cased.allSatisfy(
            { $0.properties.isLowercase }
        ) {
            return .lower
        }

        if cased.allSatisfy(
            { $0.properties.isUppercase }
        ) {
            return .upper
        }

        if cased[0].properties.isUppercase &&
            cased
            .dropFirst()
            .allSatisfy(
                { $0.properties.isLowercase }
            ) {
            return .capitalized
        }

        return .mixed
    }

    public func apply(
        to replacement: String
    ) -> String {
        switch self {
        case .lower:
            return replacement.lowercased()
        case .upper:
            return replacement.uppercased()
        case .capitalized:
            let lower = replacement.lowercased()
            guard let first = lower.firstIndex(where: { $0.isLetter }) else {
                return lower
            }
            return String(lower[..<first])
                + String(lower[first]).uppercased()
                + String(lower[lower.index(after: first)...])
        case .convention(let casing):
            return Case.convert(replacement, to: casing)
        case .mixed, .uncased:
            return replacement
        }
    }
}
