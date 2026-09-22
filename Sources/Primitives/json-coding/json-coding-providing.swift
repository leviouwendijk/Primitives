import Foundation

public protocol JSONCodingProviding {
    static var jsoncoding: JSONCoding { get }
}

public extension JSONCodingProviding
where Self: Encodable {
    func encode() throws -> Data {
        try Self.jsoncoding.encode(
            self
        )
    }

    func jsonvalue() throws -> JSONValue {
        try Self.jsoncoding.value(
            self
        )
    }
}

public extension JSONCodingProviding
where Self: Decodable {
    static func decode(
        _ data: Data
    ) throws(JSONDecodingError) -> Self {
        try jsoncoding.decode(
            Self.self,
            from: data
        )
    }

    static func decode(
        _ value: JSONValue
    ) throws -> Self {
        try jsoncoding.decode(
            Self.self,
            from: value
        )
    }
}
