import Foundation

public extension JSONCoding {
    func encode<Value: Encodable>(
        _ value: Value
    ) throws -> Data {
        try encoder().encode(
            value
        )
    }

    func value<Value: Encodable>(
        _ value: Value
    ) throws -> JSONValue {
        let data = try encode(
            value
        )

        return try JSONDecoder().decode(
            JSONValue.self,
            from: data
        )
    }

    func object<Value: Encodable>(
        _ value: Value,
        transform: JSONValueTransform = .init()
    ) throws -> [String: JSONValue] {
        let encoded = try self.value(
            value
        )
        var object = try encoded.objectValue

        for (source, destination) in transform.renames {
            if let value = object.removeValue(
                forKey: source
            ) {
                object[destination] = value
            }
        }

        for key in transform.drops {
            object.removeValue(
                forKey: key
            )
        }

        for (key, value) in transform.extras {
            object[key] = value
        }

        return object
    }

    func decode<Value: Decodable>(
        _ type: Value.Type,
        from value: JSONValue
    ) throws -> Value {
        let data = try JSONEncoder().encode(
            value
        )

        do {
            return try decoder().decode(
                type,
                from: data
            )
        } catch {
            throw JSONDecodingError(
                error
            )
        }
    }
}
