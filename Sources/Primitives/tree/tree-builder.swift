@resultBuilder
public enum TreeBuilder {
    public static func buildBlock<Value>(
        _ components: [Tree<Value>.Node]...
    ) -> [Tree<Value>.Node] {
        components.flatMap { $0 }
    }

    public static func buildExpression<Value>(
        _ expression: Tree<Value>.Node
    ) -> [Tree<Value>.Node] {
        [
            expression,
        ]
    }

    public static func buildExpression<Value>(
        _ expression: [Tree<Value>.Node]
    ) -> [Tree<Value>.Node] {
        expression
    }

    public static func buildOptional<Value>(
        _ component: [Tree<Value>.Node]?
    ) -> [Tree<Value>.Node] {
        component ?? []
    }

    public static func buildEither<Value>(
        first component: [Tree<Value>.Node]
    ) -> [Tree<Value>.Node] {
        component
    }

    public static func buildEither<Value>(
        second component: [Tree<Value>.Node]
    ) -> [Tree<Value>.Node] {
        component
    }

    public static func buildArray<Value>(
        _ components: [[Tree<Value>.Node]]
    ) -> [Tree<Value>.Node] {
        components.flatMap { $0 }
    }
}

public extension Tree {
    init(
        @TreeBuilder roots: () -> [Node]
    ) {
        self.init(
            roots: roots()
        )
    }
}

public extension Tree.Node {
    init(
        _ value: Value,
        annotations: [TreeAnnotation] = [],
        @TreeBuilder children: () -> [Self]
    ) {
        self.init(
            value,
            annotations: annotations,
            children: children()
        )
    }
}
