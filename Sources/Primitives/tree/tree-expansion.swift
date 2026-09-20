public struct TreeExpansion<Value> {
    public struct Located {
        public let address: TreeAddress
        public let value: Value

        public init(
            address: TreeAddress,
            value: Value
        ) {
            self.address = address
            self.value = value
        }
    }

    public typealias ChildProvider = (
        _ located: Located
    ) throws -> [Value]

    public let roots: [Value]

    private let child_provider: ChildProvider

    public init(
        roots: [Value],
        children: @escaping ChildProvider
    ) {
        self.roots = roots
        self.child_provider = children
    }

    public func children(
        of located: Located
    ) throws -> [Value] {
        try child_provider(
            located
        )
    }
}

extension TreeExpansion.Located: Sendable where Value: Sendable {}
extension TreeExpansion.Located: Equatable where Value: Equatable {}
extension TreeExpansion.Located: Hashable where Value: Hashable {}
