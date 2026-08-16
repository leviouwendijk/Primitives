import Foundation

public struct NonBlankString:
    Sendable,
    Codable,
    Equatable,
    Hashable
{
    public private(set) var rawValue: String

    private enum CodingKeys:
        String,
        CodingKey
    {
        case rawValue
    }

    public init(
        _ rawValue: String
    ) throws(NonBlankStringError) {
        let trimmed =
            rawValue.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            throw .blank
        }

        self.rawValue = trimmed
    }

    public mutating func update(
        to rawValue: String
    ) throws(NonBlankStringError) {
        self = try Self(
            rawValue
        )
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        let rawValue =
            try container.decode(
                String.self,
                forKey: .rawValue
            )

        do {
            try self.init(
                rawValue
            )
        } catch {
            throw DecodingError
                .dataCorruptedError(
                    forKey: .rawValue,
                    in: container,
                    debugDescription:
                        "Expected a non-blank string."
                )
        }
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        var container =
            encoder.container(
                keyedBy: CodingKeys.self
            )

        try container.encode(
            rawValue,
            forKey: .rawValue
        )
    }
}

extension NonBlankString:
    CustomStringConvertible
{
    public var description: String {
        rawValue
    }
}

public enum NonBlankStringError:
    Error,
    LocalizedError,
    Sendable,
    Equatable
{
    case blank

    public var errorDescription: String? {
        switch self {
        case .blank:
            return "Expected a non-blank string."
        }
    }
}
