public protocol StringIdentifier:
    Sendable,
    Codable,
    Hashable,
    RawRepresentable,
    ExpressibleByStringLiteral,
    CustomStringConvertible
where
    RawValue == String,
    StringLiteralType == String
{
    var rawValue: String { get }

    init(
        rawValue: String
    )
}

extension StringIdentifier {
    public init(
        _ rawValue: String
    ) {
        self.init(rawValue: rawValue)
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(rawValue: value)
    }

    public var description: String {
        rawValue
    }
}

extension StringIdentifier {
    public init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
