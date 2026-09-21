public struct CasingConversion:
    Sendable,
    Hashable,
    Codable
{
    /// The expected source representation.
    ///
    /// `nil` means the source casing is inferred by the normal casing tokenizer.
    public let source: Casing?
    public let destination: Casing
    public let separators: Separators

    public init(
        from source: Casing? = nil,
        to destination: Casing,
        separators: Separators = .common
    ) {
        self.source = source
        self.destination = destination
        self.separators = separators
    }

    public func convert(
        _ value: String
    ) -> String {
        Case.convert(
            value,
            to: destination,
            separators: separators
        )
    }

    public func callAsFunction(
        _ value: String
    ) -> String {
        convert(
            value
        )
    }
}
