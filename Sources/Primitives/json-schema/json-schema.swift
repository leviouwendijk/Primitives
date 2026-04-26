public enum JSONSchema {
    public struct Property: Sendable, Hashable {
        public let name: String
        public let schema: JSONValue
        public let required: Bool

        public init(
            name: String,
            schema: JSONValue,
            required: Bool = false
        ) {
            self.name = name
            self.schema = schema
            self.required = required
        }
    }

    @resultBuilder
    public enum Properties {
        public static func buildBlock(
            _ components: [Property]...
        ) -> [Property] {
            components.flatMap {
                $0
            }
        }

        public static func buildExpression(
            _ expression: Property
        ) -> [Property] {
            [
                expression
            ]
        }

        public static func buildExpression(
            _ expression: [Property]
        ) -> [Property] {
            expression
        }

        public static func buildOptional(
            _ component: [Property]?
        ) -> [Property] {
            component ?? []
        }

        public static func buildEither(
            first component: [Property]
        ) -> [Property] {
            component
        }

        public static func buildEither(
            second component: [Property]
        ) -> [Property] {
            component
        }

        public static func buildArray(
            _ components: [[Property]]
        ) -> [Property] {
            components.flatMap {
                $0
            }
        }

        public static func buildLimitedAvailability(
            _ component: [Property]
        ) -> [Property] {
            component
        }
    }

    public enum Value {
        public static func object(
            description: String? = nil,
            properties: [String: JSONValue] = [:],
            required: [String] = []
        ) -> JSONValue {
            var object: [String: JSONValue] = [
                "type": .string("object")
            ]

            if let description {
                object["description"] = .string(
                    description
                )
            }

            if !properties.isEmpty {
                object["properties"] = .object(
                    properties
                )
            }

            if !required.isEmpty {
                object["required"] = .array(
                    required.map {
                        .string($0)
                    }
                )
            }

            return .object(
                object
            )
        }

        public static func object(
            description: String? = nil,
            @Properties _ properties: () -> [Property]
        ) -> JSONValue {
            let properties = properties()

            return object(
                description: description,
                properties: Dictionary(
                    uniqueKeysWithValues: properties.map {
                        (
                            $0.name,
                            $0.schema
                        )
                    }
                ),
                required: properties
                    .filter(\.required)
                    .map(\.name)
            )
        }

        public static func array(
            description: String? = nil,
            items: JSONValue
        ) -> JSONValue {
            var object: [String: JSONValue] = [
                "type": .string("array"),
                "items": items
            ]

            if let description {
                object["description"] = .string(
                    description
                )
            }

            return .object(
                object
            )
        }

        public static func string(
            description: String? = nil,
            cases: [String] = []
        ) -> JSONValue {
            var object: [String: JSONValue] = [
                "type": .string("string")
            ]

            if let description {
                object["description"] = .string(
                    description
                )
            }

            if !cases.isEmpty {
                object["enum"] = .array(
                    cases.map {
                        .string($0)
                    }
                )
            }

            return .object(
                object
            )
        }

        public static func integer(
            description: String? = nil
        ) -> JSONValue {
            var object: [String: JSONValue] = [
                "type": .string("integer")
            ]

            if let description {
                object["description"] = .string(
                    description
                )
            }

            return .object(
                object
            )
        }

        public static func double(
            description: String? = nil
        ) -> JSONValue {
            var object: [String: JSONValue] = [
                "type": .string("number")
            ]

            if let description {
                object["description"] = .string(
                    description
                )
            }

            return .object(
                object
            )
        }

        public static func boolean(
            description: String? = nil
        ) -> JSONValue {
            var object: [String: JSONValue] = [
                "type": .string("boolean")
            ]

            if let description {
                object["description"] = .string(
                    description
                )
            }

            return .object(
                object
            )
        }
    }

    public static func object(
        description: String? = nil,
        @Properties _ properties: () -> [Property]
    ) -> JSONValue {
        Value.object(
            description: description,
            properties
        )
    }

    public static func object(
        description: String? = nil,
        properties: [String: JSONValue] = [:],
        required: [String] = []
    ) -> JSONValue {
        Value.object(
            description: description,
            properties: properties,
            required: required
        )
    }

    public static func array(
        _ name: String,
        required: Bool = false,
        description: String? = nil,
        items: JSONValue
    ) -> Property {
        .init(
            name: name,
            schema: Value.array(
                description: description,
                items: items
            ),
            required: required
        )
    }

    public static func object(
        _ name: String,
        required: Bool = false,
        description: String? = nil,
        @Properties _ properties: () -> [Property]
    ) -> Property {
        .init(
            name: name,
            schema: Value.object(
                description: description,
                properties
            ),
            required: required
        )
    }

    public static func string(
        _ name: String,
        required: Bool = false,
        description: String? = nil,
        cases: [String] = []
    ) -> Property {
        .init(
            name: name,
            schema: Value.string(
                description: description,
                cases: cases
            ),
            required: required
        )
    }

    public static func integer(
        _ name: String,
        required: Bool = false,
        description: String? = nil
    ) -> Property {
        .init(
            name: name,
            schema: Value.integer(
                description: description
            ),
            required: required
        )
    }

    public static func double(
        _ name: String,
        required: Bool = false,
        description: String? = nil
    ) -> Property {
        .init(
            name: name,
            schema: Value.double(
                description: description
            ),
            required: required
        )
    }

    public static func boolean(
        _ name: String,
        required: Bool = false,
        description: String? = nil
    ) -> Property {
        .init(
            name: name,
            schema: Value.boolean(
                description: description
            ),
            required: required
        )
    }
}
