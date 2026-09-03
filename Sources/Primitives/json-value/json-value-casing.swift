public extension JSONValue {
    struct CasingAPI: Sendable {
        private let value: JSONValue

        fileprivate init(
            _ value: JSONValue
        ) {
            self.value = value
        }

        public func `as`(
            _ casing: Casing,
            separators: Separators = .common
        ) throws -> JSONValue {
            try convert(
                value,
                to: casing,
                separators: separators
            )
        }

        public func `as`(
            style: Casing.Style,
            separators: Separators = .common
        ) throws -> JSONValue {
            func convert(
                _ value: JSONValue
            ) throws -> JSONValue {
                switch value {
                case .array(let values):
                    return .array(
                        try values.map {
                            try convert(
                                $0
                            )
                        }
                    )

                case .object(let object):
                    var converted: [String: JSONValue] = [:]
                    var sources: [String: String] = [:]

                    converted.reserveCapacity(
                        object.count
                    )
                    sources.reserveCapacity(
                        object.count
                    )

                    for (key, nestedValue) in object {
                        let convertedKey = Case.convert(
                            key,
                            style: style,
                            separators: separators
                        )

                        if let first = sources[convertedKey] {
                            throw JSONValueError.casingKeyCollision(
                                first: first,
                                second: key,
                                result: convertedKey
                            )
                        }

                        sources[convertedKey] = key
                        converted[convertedKey] = try convert(
                            nestedValue
                        )
                    }

                    return .object(
                        converted
                    )

                case .string,
                     .int,
                     .double,
                     .bool,
                     .null:
                    return value
                }
            }

            return try convert(
                value
            )
        }

        public func camel(
            separators: Separators = .common
        ) throws -> JSONValue {
            try `as`(
                .camel,
                separators: separators
            )
        }

        public func pascal(
            separators: Separators = .common
        ) throws -> JSONValue {
            try `as`(
                .pascal,
                separators: separators
            )
        }

        public func snake(
            separators: Separators = .common
        ) throws -> JSONValue {
            try `as`(
                .snake,
                separators: separators
            )
        }

        public func kebab(
            separators: Separators = .common
        ) throws -> JSONValue {
            try `as`(
                .kebab,
                separators: separators
            )
        }

        private func convert(
            _ value: JSONValue,
            to casing: Casing,
            separators: Separators
        ) throws -> JSONValue {
            switch value {
            case .array(let values):
                return .array(
                    try values.map { value in
                        try convert(
                            value,
                            to: casing,
                            separators: separators
                        )
                    }
                )

            case .object(let object):
                var converted: [String: JSONValue] = [:]
                var sources: [String: String] = [:]

                converted.reserveCapacity(
                    object.count
                )

                sources.reserveCapacity(
                    object.count
                )

                for (key, value) in object {
                    let convertedKey = Case.convert(
                        key,
                        to: casing,
                        separators: separators
                    )

                    if let first = sources[convertedKey] {
                        throw JSONValueError.casingKeyCollision(
                            first: first,
                            second: key,
                            result: convertedKey
                        )
                    }

                    sources[convertedKey] = key

                    converted[convertedKey] = try convert(
                        value,
                        to: casing,
                        separators: separators
                    )
                }

                return .object(
                    converted
                )

            case .string, .int, .double, .bool, .null:
                return value
            }
        }
    }

    var casing: CasingAPI {
        .init(
            self
        )
    }
}
