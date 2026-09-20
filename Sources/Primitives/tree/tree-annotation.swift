public struct TreeAnnotation {
    public var text: String

    public init(
        _ text: String
    ) {
        self.text = text
    }
}

extension TreeAnnotation: Sendable {}
extension TreeAnnotation: Equatable {}
extension TreeAnnotation: Hashable {}
extension TreeAnnotation: Codable {}

