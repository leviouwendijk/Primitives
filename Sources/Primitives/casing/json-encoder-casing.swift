import Foundation

public extension JSONEncoder {
    struct CasingAPI: Sendable {
        public func `as`(
            _ casing: Casing,
            separators: Separators = .common
        ) -> JSONEncoder {
            let encoder = JSONEncoder()

            encoder.keyEncodingStrategy = .casing(
                casing,
                separators: separators
            )

            return encoder
        }

        public func camel(
            separators: Separators = .common
        ) -> JSONEncoder {
            `as`(
                .camel,
                separators: separators
            )
        }

        public func pascal(
            separators: Separators = .common
        ) -> JSONEncoder {
            `as`(
                .pascal,
                separators: separators
            )
        }

        public func snake(
            separators: Separators = .common
        ) -> JSONEncoder {
            `as`(
                .snake,
                separators: separators
            )
        }

        public func kebab(
            separators: Separators = .common
        ) -> JSONEncoder {
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
