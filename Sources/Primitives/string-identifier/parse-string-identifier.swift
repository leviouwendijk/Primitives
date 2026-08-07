import Foundation

public func parseStringIdentifierValue(
    _ rawValue: String,
    field: String
) throws(StringIdentifierValidationError) -> String {
    let value = rawValue.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    guard !value.isEmpty else {
        throw .empty(
            field: field
        )
    }

    guard value.rangeOfCharacter(
        from: .whitespacesAndNewlines
    ) == nil else {
        throw .whitespace_not_allowed(
            field: field
        )
    }

    return value
}
