public extension Casing {
    struct Style:
        Sendable,
        Codable,
        Hashable
    {
        public let firstWord: WordCase
        public let remainingWords: WordCase
        public let separator: Separator

        public init(
            firstWord: WordCase,
            remainingWords: WordCase,
            separator: Separator
        ) {
            self.firstWord = firstWord
            self.remainingWords = remainingWords
            self.separator = separator
        }
    }

    var style: Style {
        switch self {
        case .camel:
            .init(firstWord: .lower, remainingWords: .capitalized, separator: .none)
        case .pascal:
            .init(firstWord: .capitalized, remainingWords: .capitalized, separator: .none)
        case .snake:
            .init(firstWord: .lower, remainingWords: .lower, separator: .underscore)
        case .screamingsnake:
            .init(firstWord: .upper, remainingWords: .upper, separator: .underscore)
        case .camelsnake:
            .init(firstWord: .lower, remainingWords: .capitalized, separator: .underscore)
        case .pascalsnake:
            .init(firstWord: .capitalized, remainingWords: .capitalized, separator: .underscore)
        case .kebab:
            .init(firstWord: .lower, remainingWords: .lower, separator: .hyphen)
        case .train:
            .init(firstWord: .capitalized, remainingWords: .capitalized, separator: .hyphen)
        case .screamingkebab:
            .init(firstWord: .upper, remainingWords: .upper, separator: .hyphen)
        case .dot:
            .init(firstWord: .lower, remainingWords: .lower, separator: .dot)
        case .path:
            .init(firstWord: .lower, remainingWords: .lower, separator: .slash)
        case .flat:
            .init(firstWord: .lower, remainingWords: .lower, separator: .none)
        case .upperflat:
            .init(firstWord: .upper, remainingWords: .upper, separator: .none)
        case .lower:
            .init(firstWord: .lower, remainingWords: .lower, separator: .space)
        case .upper:
            .init(firstWord: .upper, remainingWords: .upper, separator: .space)
        case .title:
            .init(firstWord: .capitalized, remainingWords: .capitalized, separator: .space)
        case .sentence:
            .init(firstWord: .capitalized, remainingWords: .lower, separator: .space)
        }
    }
}
