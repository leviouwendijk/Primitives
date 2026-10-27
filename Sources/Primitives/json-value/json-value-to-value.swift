extension JSONValue {
    public func value(
        forDotPath path: String
    ) throws -> JSONValue {
        let components = path.split(separator: ".").map(String.init)

        return try value(forPathComponents: components, fullPath: path)
    }

    private func value(
        forPathComponents components: [String],
        fullPath: String
    ) throws -> JSONValue {
        guard let first = components.first else { return self }
        switch self {
        case .object(let dict):
            if let next = dict[first] {
                return try next.value(forPathComponents: Array(components.dropFirst()), fullPath: fullPath)
            }
        case .array(let arr):
            if let idx = Int(first), arr.indices.contains(idx) {
                return try arr[idx].value(forPathComponents: Array(components.dropFirst()), fullPath: fullPath)
            }
        default:
            break
        }

        throw JSONValueError.pathNotFound(path: fullPath)
    }

    public var stringValue: String {
        get throws {
            switch self {
            case .string(let s): 
                return s

            case .int(let i): 
                return String(i)

            case .double(let d): 
                return String(d)

            case .bool(let b): 
                return String(b)

            default:
                throw JSONValueError.typeMismatch(
                    expected: "String/Int/Double/Bool",
                    actual: self
                )
            }
        }
    }

    public var intValue: Int {
        get throws {
            switch self {
            case .int(let i):
                return i

            case .string(let s):
                if let value = Int(s) {
                    return value
                }

                throw JSONValueError.invalidCast(
                    description: "Cannot convert string '\(s)' to Int"
                )

            case .double(let d):
                guard let integer = Int(exactly: d) else {
                    throw JSONValueError.invalidCast(
                        description: "Cannot convert Double \(d) to Int without loss"
                    )
                }
                return integer

            case .bool(let b):
                return b ? 1 : 0

            default:
                throw JSONValueError.typeMismatch(
                    expected: "Int/String/Double/Bool",
                    actual: self
                )
            }
        }
    }

    public var doubleValue: Double {
        get throws {
            switch self {
            case .double(let d):
                return d

            case .int(let i):
                return Double(i)

            case .string(let s):
                if let value = Double(s) {
                    return value
                }

                throw JSONValueError.invalidCast(
                    description: "Cannot convert string '\(s)' to Double"
                )

            case .bool(let b):
                return b ? 1.0 : 0.0

            default:
                throw JSONValueError.typeMismatch(
                    expected: "Double/Int/String/Bool",
                    actual: self
                )
            }
        }
    }

    public var boolValue: Bool {
        get throws {
            switch self {
            case .bool(let b):
                return b

            case .string(let s):
                let normalized = s
                    .lowercased()
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                if normalized == "true" || normalized == "1" {
                    return true
                }

                if normalized == "false" || normalized == "0" {
                    return false
                }

                throw JSONValueError.invalidCast(
                    description: "Cannot convert string '\(s)' to Bool"
                )

            case .int(let i):
                return i != 0

            case .double(let d):
                return d != 0.0

            default:
                throw JSONValueError.typeMismatch(
                    expected: "Bool/String/Int/Double",
                    actual: self
                )
            }
        }
    }

    public var arrayValue: [JSONValue] {
        get throws {
            if case .array(let array) = self {
                return array
            }

            throw JSONValueError.typeMismatch(
                expected: "Array",
                actual: self
            )
        }
    }

    public var objectValue: [String: JSONValue] {
        get throws {
            if case .object(let object) = self {
                return object
            }

            throw JSONValueError.typeMismatch(
                expected: "Object",
                actual: self
            )
        }
    }
}
