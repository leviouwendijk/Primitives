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

    public static let `default` = Self()
}

public extension JSONCoding {
    static func casing(
        decodeTo: Casing? = nil,
        encodeAs: Casing? = nil,
        separators: Separators = .common
    ) -> Self {
        .init(
            encoder: {
                guard let encodeAs else {
                    return JSONEncoder()
                }

                return JSONEncoder.casing.as(
                    encodeAs,
                    separators: separators
                )
            },
            decoder: {
                guard let decodeTo else {
                    return JSONDecoder()
                }

                return JSONDecoder.casing.as(
                    decodeTo,
                    separators: separators
                )
            }
        )
    }
}
