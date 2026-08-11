public extension String {
    struct CasingAPI: Sendable {
        private let value: String

        fileprivate init(
            _ value: String
        ) {
            self.value = value
        }

        public func `as`(
            _ casing: Casing,
            separators: Separators = .common
        ) -> String {
            Case.convert(
                value,
                to: casing,
                separators: separators
            )
        }

        public func camel(
            separators: Separators = .common
        ) -> String {
            `as`(
                .camel,
                separators: separators
            )
        }

        public func pascal(
            separators: Separators = .common
        ) -> String {
            `as`(
                .pascal,
                separators: separators
            )
        }

        public func snake(
            separators: Separators = .common
        ) -> String {
            `as`(
                .snake,
                separators: separators
            )
        }

        public func kebab(
            separators: Separators = .common
        ) -> String {
            `as`(
                .kebab,
                separators: separators
            )
        }
    }

    var casing: CasingAPI {
        .init(
            self
        )
    }
}
