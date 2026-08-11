public enum Case {
    public static func convert(
        _ value: String,
        to casing: Casing,
        separators: Separators = .common
    ) -> String {
        let words = tokenize_identifier(
            value,
            separators: separators
        )

        guard !words.isEmpty else {
            return value
        }

        switch casing {
        case .camel:
            return words[0].lowercased()
                + words
                    .dropFirst()
                    .map(capitalized_case_word)
                    .joined()

        case .pascal:
            return words
                .map(capitalized_case_word)
                .joined()

        case .snake:
            return words
                .map { $0.lowercased() }
                .joined(separator: "_")

        case .kebab:
            return words
                .map { $0.lowercased() }
                .joined(separator: "-")
        }
    }
}
