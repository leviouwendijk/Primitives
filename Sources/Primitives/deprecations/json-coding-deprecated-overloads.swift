import Foundation

@available(
    *,
    deprecated,
    message: "Use JSONCoding.value(_:), JSONCoding.object(_:transform:), or JSONValue.encoding(_:using:)."
)
public enum JSONValueCodec {
    public static func encodeValue<Value: Encodable>(
        _ value: Value,
        using encoder: JSONEncoder = JSONEncoder()
    ) throws -> JSONValue {
        try JSONCoding(
            encoder: {
                encoder
            }
        ).value(
            value
        )
    }

    public static func encodeObject<Value: Encodable>(
        _ value: Value,
        using encoder: JSONEncoder = JSONEncoder(),
        transform: JSONValueTransform = .init()
    ) throws -> [String: JSONValue] {
        try JSONCoding(
            encoder: {
                encoder
            }
        ).object(
            value,
            transform: transform
        )
    }
}

public extension JSONValue {
    @available(
        *,
        deprecated,
        message: "Use decode(_:using:) with JSONCoding."
    )
    func `as`<Value: Decodable>(
        _ type: Value.Type,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> Value {
        let data = try JSONEncoder().encode(
            self
        )

        return try decoder.decode(
            type,
            from: data
        )
    }
}

public extension JSONCoding {
    @available(
        *,
        deprecated,
        message: "Use casing(decode:encode:) with CasingConversion values."
    )
    static func casing(
        decodeTo: Casing? = nil,
        encodeAs: Casing? = nil,
        separators: Separators = .common
    ) -> Self {
        casing(
            decode: decodeTo.map {
                CasingConversion(
                    to: $0,
                    separators: separators
                )
            },
            encode: encodeAs.map {
                CasingConversion(
                    to: $0,
                    separators: separators
                )
            }
        )
    }
}
