extension Tree {
    public struct Annotation: Sendable, Equatable, Hashable {
        public var text: String

        public init(
            _ text: String
        ) {
            self.text = text
        }
    }
}
