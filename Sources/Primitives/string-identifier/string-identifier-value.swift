import Foundation

public struct StringIdentifierValue:
    ValidatedStringIdentifier
{
    public let rawValue: String

    public init(
        _ rawValue: String
    ) throws(StringIdentifierValidationError) {
        let value = rawValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !value.isEmpty else {
            throw .empty(
                field: "rawValue"
            )
        }

        guard value.rangeOfCharacter(
            from: .whitespacesAndNewlines
        ) == nil else {
            throw .whitespace_not_allowed(
                field: "rawValue"
            )
        }

        self.rawValue = value
    }
}
