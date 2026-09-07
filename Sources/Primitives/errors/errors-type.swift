@available(
    *,
    deprecated,
    message: "Import Errors and use Errors from the Errors package."
)
public struct Errors: Error, Sendable {
    public let errors: [any Error]

    public init(
        _ errors: [any Error]
    ) {
        self.errors = errors
    }
}

@available(
    *,
    deprecated,
    message: "Import Errors and use Errors from the Errors package."
)
public typealias MultiError = Errors
