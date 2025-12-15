import Foundation

public struct JSONValueTransform {
    public var renames: [String:String] = [:]       // e.g. ["ip":"ip_address"]
    public var drops: Set<String> = []              // omit these keys
    public var extras: [String: JSONValue] = [:]    // inject or override

    public init(
        renames: [String:String] = [:],
        drops: Set<String> = [],
        extras: [String: JSONValue] = [:]
    ) {
        self.renames = renames
        self.drops = drops
        self.extras = extras
    }
}

public enum JSONValueCodec {
    /// Encode any `Encodable` into a JSONValue.
    public static func encodeValue<T: Encodable>(
        _ value: T,
        using encoder: JSONEncoder = JSONEncoder()
    ) throws -> JSONValue {
        let data = try encoder.encode(value)
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }

    /// Encode any `Encodable` payload to an **object** `[String: JSONValue]`,
    /// then apply optional renames/drops/extras.
    public static func encodeObject<T: Encodable>(
        _ value: T,
        using encoder: JSONEncoder = JSONEncoder(),
        transform: JSONValueTransform = .init()
    ) throws -> [String: JSONValue] {
        let j = try encodeValue(value, using: encoder)
        guard case .object(var obj) = j else {
            throw JSONValueError.invalidCast(description: "Payload did not encode to a JSON object.")
        }

        // renames
        if !transform.renames.isEmpty {
            for (from, to) in transform.renames {
                if let v = obj.removeValue(forKey: from) {
                    obj[to] = v
                }
            }
        }

        // drops
        if !transform.drops.isEmpty {
            for k in transform.drops { obj.removeValue(forKey: k) }
        }

        // extras (override/insert)
        if !transform.extras.isEmpty {
            for (k, v) in transform.extras { obj[k] = v }
        }

        return obj
    }
}
