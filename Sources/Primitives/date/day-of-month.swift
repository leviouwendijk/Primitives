public struct DayOfMonth: Equatable, Hashable, Sendable, Codable {
    public let value: Int

    public init(_ value: Int) throws(DateSpecificationError) {
        guard (1...31).contains(value) else {
            throw .invalidInferDay(value)
        }
        self.value = value
    }
}
