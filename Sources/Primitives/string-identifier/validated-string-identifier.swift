public protocol ValidatedStringIdentifier:
    Sendable,
    Codable,
    Hashable,
    CustomStringConvertible
{
    var rawValue: String { get }

    init(
        _ rawValue: String
    ) throws
}

public extension ValidatedStringIdentifier {
    var description: String {
        rawValue
    }

    init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.singleValueContainer()

        let rawValue = try container.decode(
            String.self
        )

        do {
            try self.init(
                rawValue
            )
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription:
                    "Invalid \(Self.self) identifier."
            )
        }
    }

    func encode(
        to encoder: Encoder
    ) throws {
        var container =
            encoder.singleValueContainer()

        try container.encode(
            rawValue
        )
    }
}
