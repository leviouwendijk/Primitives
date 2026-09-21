import Foundation

public protocol JSONCodingProviding {
    static var jsonCoding: JSONCoding { get }
}

public extension JSONCodingProviding
where Self: Encodable {
    func encode() throws -> Data {
        try Self.jsonCoding.encode(
            self
        )
    }

    func jsonValue() throws -> JSONValue {
        try Self.jsonCoding.value(
            self
        )
    }
}

public extension JSONCodingProviding
where Self: Decodable {
    static func decode(
        _ data: Data
    ) throws(JSONDecodingError) -> Self {
        try jsonCoding.decode(
            Self.self,
            from: data
        )
    }

    static func decode(
        _ value: JSONValue
    ) throws -> Self {
        try jsonCoding.decode(
            Self.self,
            from: value
        )
    }
}
