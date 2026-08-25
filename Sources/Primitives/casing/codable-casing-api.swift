import Foundation

public struct CodableCasingAPI<Value: CasingCodable> {
    private let value: Value

    internal init(
        _ value: Value
    ) {
        self.value = value
    }

    public func `as`(
        _ casing: Casing,
        separators: Separators = .common,
        sourceCoding: JSONCoding = .default
    ) throws -> JSONValue {
        let encoded = try JSONValueCodec.encodeValue(
            value,
            using: sourceCoding.encoder()
        )

        return try encoded.casing.as(
            casing,
            separators: separators
        )
    }

    public func camel(
        separators: Separators = .common,
        sourceCoding: JSONCoding = .default
    ) throws -> JSONValue {
        try `as`(
            .camel,
            separators: separators,
            sourceCoding: sourceCoding
        )
    }

    public func pascal(
        separators: Separators = .common,
        sourceCoding: JSONCoding = .default
    ) throws -> JSONValue {
        try `as`(
            .pascal,
            separators: separators,
            sourceCoding: sourceCoding
        )
    }

    public func snake(
        separators: Separators = .common,
        sourceCoding: JSONCoding = .default
    ) throws -> JSONValue {
        try `as`(
            .snake,
            separators: separators,
            sourceCoding: sourceCoding
        )
    }

    public func kebab(
        separators: Separators = .common,
        sourceCoding: JSONCoding = .default
    ) throws -> JSONValue {
        try `as`(
            .kebab,
            separators: separators,
            sourceCoding: sourceCoding
        )
    }

    public func data(
        as casing: Casing,
        separators: Separators = .common,
        sourceCoding: JSONCoding = .default,
        outputFormatting: JSONEncoder.OutputFormatting = []
    ) throws -> Data {
        let value = try `as`(
            casing,
            separators: separators,
            sourceCoding: sourceCoding
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting

        return try encoder.encode(
            value
        )
    }

    public func string(
        as casing: Casing,
        separators: Separators = .common,
        sourceCoding: JSONCoding = .default,
        prettyPrinted: Bool = true
    ) throws -> String {
        let value = try `as`(
            casing,
            separators: separators,
            sourceCoding: sourceCoding
        )

        return try value.toJSONString(
            prettyPrinted: prettyPrinted
        )
    }
}

extension CodableCasingAPI:
    Sendable
where Value: Sendable {}
