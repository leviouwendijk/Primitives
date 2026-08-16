import Foundation

public struct DayOfMonth:
    Equatable,
    Hashable,
    Sendable,
    Codable
{
    public let value: Int

    private enum CodingKeys:
        String,
        CodingKey
    {
        case value
    }

    public init(
        _ value: Int
    ) throws(DayOfMonthError) {
        guard (1...31).contains(
            value
        ) else {
            throw .outOfRange(
                value
            )
        }

        self.value = value
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        let value =
            try container.decode(
                Int.self,
                forKey: .value
            )

        do {
            try self.init(
                value
            )
        } catch {
            throw DecodingError
                .dataCorruptedError(
                    forKey: .value,
                    in: container,
                    debugDescription:
                        "Invalid day of month: \(value)"
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
            value,
            forKey: .value
        )
    }
}

public enum DayOfMonthError:
    Error,
    LocalizedError,
    Sendable,
    Equatable
{
    case outOfRange(
        Int
    )

    public var errorDescription: String? {
        switch self {
        case .outOfRange(
            let value
        ):
            return "Day of month must be between 1 and 31, got \(value)."
        }
    }
}
