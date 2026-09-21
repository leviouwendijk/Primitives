import Foundation

public struct JSONCoding: Sendable {
    private let makeEncoder: @Sendable () -> JSONEncoder
    private let makeDecoder: @Sendable () -> JSONDecoder

    public init(
        encoder: @escaping @Sendable () -> JSONEncoder = {
            JSONEncoder()
        },
        decoder: @escaping @Sendable () -> JSONDecoder = {
            JSONDecoder()
        }
    ) {
        self.makeEncoder = encoder
        self.makeDecoder = decoder
    }

    public func encoder() -> JSONEncoder {
        makeEncoder()
    }

    public func decoder() -> JSONDecoder {
        makeDecoder()
    }

    public func decode<Value: Decodable>(
        _ type: Value.Type,
        from data: Data
    ) throws(JSONDecodingError) -> Value {
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

    public static let `default` = Self()
}

public extension JSONCoding {
    static func casing(
        decode: CasingConversion? = nil,
        encode: CasingConversion? = nil
    ) -> Self {
        .init(
            encoder: {
                let encoder = JSONEncoder()

                if let encode {
                    encoder.keyEncodingStrategy = .casing(
                        encode
                    )
                }

                return encoder
            },
            decoder: {
                let decoder = JSONDecoder()

                if let decode {
                    decoder.keyDecodingStrategy = .casing(
                        decode
                    )
                }

                return decoder
            }
        )
    }

    static func casing(
        decoded: Casing,
        encoded: Casing,
        separators: Separators = .common
    ) -> Self {
        casing(
            decode: .init(
                from: encoded,
                to: decoded,
                separators: separators
            ),
            encode: .init(
                from: decoded,
                to: encoded,
                separators: separators
            )
        )
    }
}
