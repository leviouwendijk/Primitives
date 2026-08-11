public struct Separators: Sendable, Hashable {
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

    public static let none = Separators("")
    public static let common = Separators(" _-./+:,")
    public static let commonNoDot = Separators(" _-/+:,")
    public static let space = Separators(" ")
}
