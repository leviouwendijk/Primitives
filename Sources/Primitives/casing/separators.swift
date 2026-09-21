public struct Separators:
    Sendable,
    Hashable,
    Codable
{
    public let scalars: Set<UnicodeScalar>

    public init<S: Sequence>(
        _ separators: S
    ) where S.Element == UnicodeScalar {
        self.scalars = Set(
            separators
        )
    }

    public init<S: Sequence>(
        _ separators: S
    ) where S.Element == Character {
        self.scalars = Set(
            separators.flatMap { character in
                character.unicodeScalars
            }
        )
    }

    public func contains(
        _ scalar: UnicodeScalar
    ) -> Bool {
        scalars.contains(
            scalar
        )
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(
            String.self
        )

        self.init(
            value.unicodeScalars
        )
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        var container = encoder.singleValueContainer()
        let ordered = scalars.sorted {
            $0.value < $1.value
        }
        let value = String(
            String.UnicodeScalarView(
                ordered
            )
        )

        try container.encode(
            value
        )
    }

    public static let none = Separators("")
    public static let common = Separators(" _-./+:,")
    public static let commonNoDot = Separators(" _-/+:,")
    public static let space = Separators(" ")
}
