public struct CasedProperty:
    Sendable,
    Hashable
{
    public enum Error:
        Swift.Error,
        Sendable,
        Equatable
    {
        case empty
        case emptyWord(index: Int)
        case unsupportedCasing(Casing)
        case invalidIdentifier(String)
        case reservedKeyword(String)
    }

    public let words: [String]
    public let casing: Casing
    public let value: String
    public let identifier: String

    public init(
        _ words: String...,
        casing: Casing = .camel,
        allowReservedKeywords: Bool = false
    ) throws {
        try self.init(
            words,
            casing: casing,
            allowReservedKeywords: allowReservedKeywords
        )
    }

    public init(
        _ words: [String],
        casing: Casing = .camel,
        allowReservedKeywords: Bool = false
    ) throws {
        guard !words.isEmpty else {
            throw Error.empty
        }

        for (index, word) in words.enumerated() {
            guard !word.isEmpty else {
                throw Error.emptyWord(
                    index: index
                )
            }
        }

        guard Self.supports(
            casing
        ) else {
            throw Error.unsupportedCasing(
                casing
            )
        }

        let value = Case.convert(
            words.joined(
                separator: " "
            ),
            to: casing
        )

        guard Self.isIdentifier(
            value
        ) else {
            throw Error.invalidIdentifier(
                value
            )
        }

        let isReserved =
            Self.reservedKeywords.contains(
                value
            )

        if isReserved && !allowReservedKeywords {
            throw Error.reservedKeyword(
                value
            )
        }

        self.words = words
        self.casing = casing
        self.value = value
        self.identifier =
            isReserved
            ? "`\(value)`"
            : value
    }
}

private extension CasedProperty {
    static func supports(
        _ casing: Casing
    ) -> Bool {
        switch casing {
        case
            .camel,
            .pascal,
            .snake,
            .screamingsnake,
            .camelsnake,
            .pascalsnake,
            .flat,
            .upperflat:
            true

        case
            .kebab,
            .train,
            .screamingkebab,
            .dot,
            .path,
            .lower,
            .upper,
            .title,
            .sentence:
            false
        }
    }

    static func isIdentifier(
        _ value: String
    ) -> Bool {
        guard let first = value.first else {
            return false
        }

        guard
            first == "_"
                || first.isLetter
        else {
            return false
        }

        return value.dropFirst().allSatisfy {
            $0 == "_"
                || $0.isLetter
                || $0.isNumber
        }
    }

    static let reservedKeywords: Set<String> = [
        "Self",
        "actor",
        "any",
        "associatedtype",
        "async",
        "await",
        "borrowing",
        "break",
        "case",
        "catch",
        "class",
        "consume",
        "consuming",
        "continue",
        "convenience",
        "copy",
        "default",
        "defer",
        "deinit",
        "didSet",
        "discard",
        "distributed",
        "do",
        "dynamic",
        "each",
        "else",
        "enum",
        "extension",
        "fallthrough",
        "false",
        "fileprivate",
        "final",
        "for",
        "func",
        "get",
        "guard",
        "if",
        "import",
        "indirect",
        "infix",
        "init",
        "inout",
        "internal",
        "is",
        "isolated",
        "lazy",
        "let",
        "macro",
        "mutating",
        "nonisolated",
        "nonmutating",
        "open",
        "operator",
        "optional",
        "override",
        "package",
        "postfix",
        "precedencegroup",
        "prefix",
        "private",
        "protocol",
        "public",
        "repeat",
        "required",
        "rethrows",
        "return",
        "self",
        "sending",
        "set",
        "some",
        "static",
        "struct",
        "subscript",
        "super",
        "switch",
        "throwing",
        "throws",
        "true",
        "try",
        "typealias",
        "unowned",
        "var",
        "weak",
        "where",
        "while",
        "willSet",
    ]
}
