extension JSONValue {
    public struct ValueAccessorAPI: Sendable, Codable {
        public let jsonvalue: JSONValue 
        
        public init(
            jsonvalue: JSONValue
        ) {
            self.jsonvalue = jsonvalue
        }

        public var string: String? {
            try? self.jsonvalue.stringValue
        }

        public var int: Int? {
            try? self.jsonvalue.intValue
        }

        public var double: Double? {
            try? self.jsonvalue.doubleValue
        }

        public var bool: Bool? {
            try? self.jsonvalue.boolValue
        }

        public var object: [String: JSONValue]? {
            try? self.jsonvalue.objectValue
        }

        public var array: [JSONValue]? {
            try? self.jsonvalue.arrayValue
        }
    }

    public var valueOrNil: ValueAccessorAPI {
        return .init(jsonvalue: self)
    }
}
