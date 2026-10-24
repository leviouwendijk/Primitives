/// Immutable, reusable lookup and adjacency index. Traversal preserves edge order.
public extension Graph {
    struct Index {
        private let nodes_by_id: [NodeID: Node]
        private let edges_by_id: [EdgeID: Edge]
        private let outgoing_by_node: [NodeID: [Edge]]
        private let incoming_by_node: [NodeID: [Edge]]

        public init(_ graph: Graph) {
            self.nodes_by_id = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })
            self.edges_by_id = Dictionary(uniqueKeysWithValues: graph.edges.map { ($0.id, $0) })
            var outgoing: [NodeID: [Edge]] = [:]
            var incoming: [NodeID: [Edge]] = [:]
            for edge in graph.edges {
                outgoing[edge.source, default: []].append(edge)
                incoming[edge.destination, default: []].append(edge)
            }
            self.outgoing_by_node = outgoing
            self.incoming_by_node = incoming
        }

        public func node(_ id: NodeID) -> Node? { nodes_by_id[id] }
        public func edge(_ id: EdgeID) -> Edge? { edges_by_id[id] }
        public func outgoing_edges(from id: NodeID) -> [Edge] { outgoing_by_node[id] ?? [] }
        public func incoming_edges(to id: NodeID) -> [Edge] { incoming_by_node[id] ?? [] }
    }

    var index: Index { .init(self) }
}

public enum GraphDirection: Sendable, Hashable, Codable {
    case outgoing
    case incoming
}

public enum GraphTraversal: Sendable, Hashable, Codable {
    case depth_first
    case breadth_first
}
