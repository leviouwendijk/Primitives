public enum TreeRewrite<Value> {
    case keep
    case remove
    case replace(Tree<Value>.Node)
    case replace_many([Tree<Value>.Node])
}

extension TreeRewrite: Sendable where Value: Sendable {}
extension TreeRewrite: Equatable where Value: Equatable {}
extension TreeRewrite: Hashable where Value: Hashable {}

public extension Tree {
    func rewrite(
        _ transform: (
            _ located: LocatedNode,
            _ children: [Node]
        ) throws -> TreeRewrite<Value>
    ) rethrows -> Tree<Value> {
        let rewrittenRootGroups: [[Node]] = try fold {
            (
                located: LocatedNode,
                childGroups: [[Node]]
            ) throws -> [Node] in
            let children: [Node] = childGroups.flatMap { $0 }

            switch try transform(
                located,
                children
            ) {
            case .keep:
                return [
                    Node(
                        located.node.value,
                        annotations: located.node.annotations,
                        children: children
                    ),
                ]

            case .remove:
                return []

            case .replace(let replacement):
                return [
                    replacement,
                ]

            case .replace_many(let replacements):
                return replacements
            }
        }

        return .init(
            roots: rewrittenRootGroups.flatMap { $0 }
        )
    }
}
