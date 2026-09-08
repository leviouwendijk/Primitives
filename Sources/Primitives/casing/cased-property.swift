import Foundation

public struct CasedProperty:
    Sendable,
    Hashable
{
    public struct Options:
        OptionSet,
        Sendable,
        Hashable
    {
        public let rawValue: UInt8

        public init(
            rawValue: UInt8
        ) {
            self.rawValue = rawValue
        }

        /// Allows Swift reserved keywords by emitting them as escaped
        /// identifiers, for example `private`.
        public static let reservedKeywords =
            Self(rawValue: 1 << 0)

        /// Allows Swift raw identifiers when the rendered property cannot
        /// be represented as an ordinary identifier.
        ///
        /// This also permits reserved keywords, since they can be represented
        /// using the same backtick-delimited source syntax.
        public static let rawIdentifiers =
            Self(rawValue: 1 << 1)

        /// Accepts any rendered property that Swift can represent as either
        /// an ordinary, escaped, or raw identifier.
        public static let lenient: Self = [
            .reservedKeywords,
            .rawIdentifiers,
        ]
    }

    public let words: [String]
    public let casing: Casing
    public let value: String
    public let identifier: String

    public init(
        _ words: String...,
        casing: Casing = .camel,
        options: Options = []
    ) throws {
        try self.init(
            words,
            casing: casing,
            options: options
        )
    }

    public init(
        _ words: [String],
        casing: Casing = .camel,
        options: Options = []
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

        let value = Case.convert(
            words.joined(
                separator: " "
            ),
            to: casing
        )

        let isReserved =
            Self.reservedKeywords.contains(
                value
            )

        let allowsReservedKeywords =
            options.contains(
                .reservedKeywords
            )
            || options.contains(
                .rawIdentifiers
            )

        let identifier: String

        if Self.isOrdinaryIdentifier(
            value
        ) {
            if isReserved {
                guard allowsReservedKeywords else {
                    throw Error.reservedKeyword(
                        value
                    )
                }

                identifier = "`\(value)`"
            } else {
                identifier = value
            }
        } else {
            guard
                options.contains(
                    .rawIdentifiers
                ),
                Self.isRawIdentifier(
                    value
                )
            else {
                throw Error.invalidIdentifier(
                    value
                )
            }

            identifier = "`\(value)`"
        }

        self.words = words
        self.casing = casing
        self.value = value
        self.identifier = identifier
    }
}

private extension CasedProperty {
    static func isOrdinaryIdentifier(
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

    static func isRawIdentifier(
        _ value: String
    ) -> Bool {
        guard !value.isEmpty else {
            return false
        }

        let scalars =
            value.unicodeScalars

        guard !scalars.contains(
            where: isForbiddenRawIdentifierScalar
        ) else {
            return false
        }

        guard !scalars.allSatisfy({
            $0.properties.isWhitespace
        }) else {
            return false
        }

        guard !scalars.allSatisfy(
            isOperatorCharacter
        ) else {
            return false
        }

        return true
    }

    static func isForbiddenRawIdentifierScalar(
        _ scalar: UnicodeScalar
    ) -> Bool {
        let value = scalar.value

        if scalar == "`" || scalar == "\\" {
            return true
        }

        if value == 0x7F {
            return true
        }

        return value <= 0x1F
    }

    static func isOperatorCharacter(
        _ scalar: UnicodeScalar
    ) -> Bool {
        switch scalar.value {
        case
            0x21,
            0x25,
            0x26,
            0x2A,
            0x2B,
            0x2D,
            0x2E,
            0x2F,
            0x3C,
            0x3D,
            0x3E,
            0x3F,
            0x5E,
            0x7C,
            0x7E:
            true

        case
            0x00A1...0x00A7,
            0x00A9...0x00A9,
            0x00AB...0x00AB,
            0x00AC...0x00AC,
            0x00AE...0x00AE,
            0x00B0...0x00B1,
            0x00B6...0x00B6,
            0x00BB...0x00BB,
            0x00BF...0x00BF,
            0x00D7...0x00D7,
            0x00F7...0x00F7,
            0x2016...0x2017,
            0x2020...0x2027,
            0x2030...0x203E,
            0x2041...0x2053,
            0x2055...0x205E,
            0x2190...0x23FF,
            0x2500...0x2775,
            0x2794...0x2BFF,
            0x2E00...0x2E7F,
            0x3001...0x3003,
            0x3008...0x3020,
            0x3030...0x3030,
            0x0300...0x036F,
            0x1DC0...0x1DFF,
            0x20D0...0x20FF,
            0xFE00...0xFE0F,
            0xFE20...0xFE2F,
            0xE0100...0xE01EF:
            true

        default:
            false
        }
    }

    static let reservedKeywords: Set<String> = [
        "Self",
        "actor",
        "any",
        "as",
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
        "in",
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
        "nil",
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
        "throw",
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

extension CasedProperty {
    public enum Error:
        Swift.Error,
        Sendable,
        Equatable,
        LocalizedError,
        CustomStringConvertible
    {
        case empty
        case emptyWord(index: Int)
        case invalidIdentifier(String)
        case reservedKeyword(String)

        public var errorDescription: String? {
            switch self {
            case .empty:
                "A cased property requires at least one word."

            case .emptyWord(let index):
                "Cased property word at index \(index) is empty."

            case .invalidIdentifier(let value):
                "'\(value)' is not a valid ordinary Swift property identifier."

            case .reservedKeyword(let value):
                "'\(value)' is a reserved Swift keyword."
            }
        }

        public var failureReason: String? {
            switch self {
            case .empty:
                "No property words were provided."

            case .emptyWord:
                "Property words must be non-empty."

            case .invalidIdentifier(let value):
                "'\(value)' requires raw identifier syntax or cannot be represented as a supported Swift identifier."

            case .reservedKeyword(let value):
                "'\(value)' requires escaped identifier syntax because Swift reserves this word."
            }
        }

        public var recoverySuggestion: String? {
            switch self {
            case .empty:
                "Provide at least one property word."

            case .emptyWord(let index):
                "Remove the empty word at index \(index) or replace it with a non-empty value."

            case .invalidIdentifier:
                "Use options: .rawIdentifiers to permit raw backticked identifiers, or options: .lenient to permit all supported escaped identifiers."

            case .reservedKeyword:
                "Use options: .reservedKeywords to permit escaped keywords, options: .rawIdentifiers to permit raw identifiers generally, or options: .lenient to permit all supported escaped identifiers."
            }
        }

        public var description: String {
            var components: [String] = []

            if let errorDescription {
                components.append(
                    errorDescription
                )
            }

            if let failureReason {
                components.append(
                    failureReason
                )
            }

            if let recoverySuggestion {
                components.append(
                    recoverySuggestion
                )
            }

            return components.joined(
                separator: " "
            )
        }
    }
}
