public extension JSONValue {
    static func encoding<Value: Encodable>(
        _ value: Value,
        using coding: JSONCoding = .default
    ) throws -> Self {
        try coding.value(
            value
        )
    }

    func decode<Value: Decodable>(
        _ type: Value.Type,
        using coding: JSONCoding = .default
    ) throws -> Value {
        try coding.decode(
            type,
            from: self
        )
    }

    func decode<Value: Decodable>(
        using coding: JSONCoding = .default
    ) throws -> Value {
        try decode(
            Value.self,
            using: coding
        )
    }
}
