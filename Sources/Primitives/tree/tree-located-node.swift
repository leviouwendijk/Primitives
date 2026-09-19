extension Tree {
    public struct LocatedNode {
        public let address: TreeAddress
        public let node: Node

        public init(
            address: TreeAddress,
            node: Node
        ) {
            self.address = address
            self.node = node
        }
    }
}

extension Tree.LocatedNode: Sendable where Value: Sendable {}
extension Tree.LocatedNode: Equatable where Value: Equatable {}
extension Tree.LocatedNode: Hashable where Value: Hashable {}
