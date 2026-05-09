extension JSONValue {
    public struct ValueAccessorAPI: Sendable, Codable {
        public let jsonvalue: JSONValue 
        
        public init(
            jsonvalue: JSONValue
        ) {
            self.jsonvalue = jsonvalue
        }

        var string: String? {
            try? self.jsonvalue.stringValue
        }

        var int: Int? {
            try? self.jsonvalue.intValue
        }

        var double: Double? {
            try? self.jsonvalue.doubleValue
        }

        var bool: Bool? {
            try? self.jsonvalue.boolValue
        }

        var object: [String: JSONValue]? {
            try? self.jsonvalue.objectValue
        }

        var array: [JSONValue]? {
            try? self.jsonvalue.arrayValue
        }
    }

    public var valueOrNil: ValueAccessorAPI {
        return .init(jsonvalue: self)
    }
}
