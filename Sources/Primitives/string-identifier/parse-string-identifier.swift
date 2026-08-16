import Foundation

@available(
    *,
    deprecated,
    message: """
    Guideline violation: structure.parse_dont_validate.strong_result. \
    Use StringIdentifierValue(_:) so successful parsing is represented \
    by a value carrying the established invariant.
    """
)
public func parseStringIdentifierValue(
    _ rawValue: String,
    field: String
) throws(StringIdentifierValidationError) -> String {
    do {
        return try StringIdentifierValue(
            rawValue
        )
        .rawValue
    } catch .empty {
        throw .empty(
            field: field
        )
    } catch .whitespace_not_allowed {
        throw .whitespace_not_allowed(
            field: field
        )
    }
}
