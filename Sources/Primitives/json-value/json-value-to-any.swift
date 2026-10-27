import Foundation

extension JSONValue {
    public func toAny() -> Any {
        switch self {
        case .null:
            return NSNull()

        case .bool(let b):
            return b

        case .int(let i):
            return i

        case .double(let d):
            return d

        case .string(let s):
            return s

        case .array(let array):
            return array.map {
                $0.toAny()
            }

        case .object(let object):
            return object.mapValues {
                $0.toAny()
            }
        }
    }
}
