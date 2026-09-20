public struct Tree<Value> {
    public var roots: [Node]

    public init(
        roots: [Node] = []
    ) {
        self.roots = roots
    }

    public struct Node {
        public var value: Value
        public var annotations: [TreeAnnotation]
        public var children: [Node]

        public init(
            _ value: Value,
            annotations: [TreeAnnotation] = [],
            children: [Node] = []
        ) {
            self.value = value
            self.annotations = annotations
            self.children = children
        }
    }
}

extension Tree.Node: Sendable where Value: Sendable {}
extension Tree: Sendable where Value: Sendable {}

extension Tree.Node: Equatable where Value: Equatable {}
extension Tree: Equatable where Value: Equatable {}

extension Tree.Node: Hashable where Value: Hashable {}
extension Tree: Hashable where Value: Hashable {}

extension Tree.Node: Codable where Value: Codable {}
extension Tree: Codable where Value: Codable {}
