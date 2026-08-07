import Foundation

public protocol UUIDIdentifier:
    Sendable,
    Codable,
    Hashable,
    RawRepresentable,
    CustomStringConvertible
where
    RawValue == UUID
{
    var rawValue: UUID { get }

    init(
        rawValue: UUID
    )
}

public extension UUIDIdentifier {
    init(
        _ rawValue: UUID
    ) {
        self.init(
            rawValue: rawValue
        )
    }

    init(
        _ rawValue: String
    ) throws(UUIDIdentifierError) {
        let value = rawValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard
            !value.isEmpty,
            value.rangeOfCharacter(
                from: .whitespacesAndNewlines
            ) == nil,
            let uuid = UUID(
                uuidString: value
            )
        else {
            throw .invalid_uuid(
                type: String(
                    describing: Self.self
                ),
                provided: rawValue
            )
        }

        self.init(
            rawValue: uuid
        )
    }

    static func random() -> Self {
        Self(
            rawValue: UUID()
        )
    }

    var stringValue: String {
        rawValue
            .uuidString
            .lowercased()
    }

    var description: String {
        stringValue
    }

    init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.singleValueContainer()

        let value = try container.decode(
            String.self
        )

        do {
            try self.init(value)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription:
                    "Invalid \(Self.self) UUID identifier."
            )
        }
    }

    func encode(
        to encoder: Encoder
    ) throws {
        var container =
            encoder.singleValueContainer()

        try container.encode(
            stringValue
        )
    }
}
