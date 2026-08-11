import Foundation

public extension JSONDecoder {
    struct CasingAPI: Sendable {
        public func `as`(
            _ casing: Casing,
            separators: Separators = .common
        ) -> JSONDecoder {
            let decoder = JSONDecoder()

            decoder.keyDecodingStrategy = .casing(
                casing,
                separators: separators
            )

            return decoder
        }

        public func camel(
            separators: Separators = .common
        ) -> JSONDecoder {
            `as`(
                .camel,
                separators: separators
            )
        }

        public func pascal(
            separators: Separators = .common
        ) -> JSONDecoder {
            `as`(
                .pascal,
                separators: separators
            )
        }

        public func snake(
            separators: Separators = .common
        ) -> JSONDecoder {
            `as`(
                .snake,
                separators: separators
            )
        }

        public func kebab(
            separators: Separators = .common
        ) -> JSONDecoder {
            `as`(
                .kebab,
                separators: separators
            )
        }
    }

    static var casing: CasingAPI {
        .init()
    }
}
