import Foundation

public extension JSONValue {
    init(_ uuid: UUID) {
        self = .string(uuid.uuidString)
    }

    var uuidValue: UUID {
        get throws {
            guard case .string(let string) = self else {
                throw JSONValueError.typeMismatch(
                    expected: "UUID string",
                    actual: self
                )
            }

            guard let uuid = UUID(uuidString: string) else {
                throw JSONValueError.invalidCast(
                    description: "Cannot convert string '\(string)' to UUID"
                )
            }

            return uuid
        }
    }
}
