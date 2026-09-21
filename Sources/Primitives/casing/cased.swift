public struct Cased<Value: CasingCodable>: Encodable {
    public let value: Value
    public let casing: Casing
    public let separators: Separators
    public let sourceCoding: JSONCoding

    public init(
        _ value: Value,
        as casing: Casing,
        separators: Separators = .common,
        sourceCoding: JSONCoding = .default
    ) {
        self.value = value
        self.casing = casing
        self.separators = separators
        self.sourceCoding = sourceCoding
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        let encoded = try sourceCoding.value(
            value
        )

        let cased = try encoded.casing.as(
            casing,
            separators: separators
        )

        try cased.encode(
            to: encoder
        )
    }
}

extension Cased: Sendable where Value: Sendable {}
