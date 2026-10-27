/// An ordered directed multigraph. Node and edge identities are independent;
/// parallel edges and cycles are valid, dangling endpoints are not.
public struct Graph<NodeID: Hashable, NodeValue, EdgeID: Hashable, EdgeValue> {
    public struct Node {
        public let id: NodeID
        public let value: NodeValue

        public init(id: NodeID, value: NodeValue) {
            self.id = id
            self.value = value
        }
    }

    public struct Edge {
        public let id: EdgeID
        public let source: NodeID
        public let destination: NodeID
        public let value: EdgeValue

        public init(
            id: EdgeID,
            source: NodeID,
            destination: NodeID,
            value: EdgeValue
        ) {
            self.id = id
            self.source = source
            self.destination = destination
            self.value = value
        }
    }

    public let nodes: [Node]
    public let edges: [Edge]

    /// Parse-on-construction: a Graph always has unique identities and
    /// endpoints that refer to its own nodes.
    public init(nodes: [Node], edges: [Edge]) throws(GraphValidationError<NodeID, EdgeID>) {
        var node_ids: Set<NodeID> = []
        for node in nodes {
            guard node_ids.insert(node.id).inserted else {
                throw GraphValidationError<NodeID, EdgeID>.duplicate_node(node.id)
            }
        }
        var edge_ids: Set<EdgeID> = []
        for edge in edges {
            guard edge_ids.insert(edge.id).inserted else {
                throw GraphValidationError<NodeID, EdgeID>.duplicate_edge(edge.id)
            }
            guard node_ids.contains(edge.source) else {
                throw GraphValidationError<NodeID, EdgeID>.unknown_source(edge.id, edge.source)
            }
            guard node_ids.contains(edge.destination) else {
                throw GraphValidationError<NodeID, EdgeID>.unknown_destination(edge.id, edge.destination)
            }
        }
        self.nodes = nodes
        self.edges = edges
    }
}

public enum GraphValidationError<NodeID: Hashable, EdgeID: Hashable>: Error {
    case duplicate_node(NodeID)
    case duplicate_edge(EdgeID)
    case unknown_source(EdgeID, NodeID)
    case unknown_destination(EdgeID, NodeID)
    case unknown_root(NodeID)
}

extension GraphValidationError: Sendable where NodeID: Sendable, EdgeID: Sendable {}
extension GraphValidationError: Equatable where NodeID: Equatable, EdgeID: Equatable {}

extension Graph.Node: Sendable where NodeID: Sendable, NodeValue: Sendable {}
extension Graph.Edge: Sendable where NodeID: Sendable, EdgeID: Sendable, EdgeValue: Sendable {}
extension Graph: Sendable where NodeID: Sendable, NodeValue: Sendable, EdgeID: Sendable, EdgeValue: Sendable {}

extension Graph.Node: Equatable where NodeValue: Equatable {}
extension Graph.Edge: Equatable where EdgeValue: Equatable {}
extension Graph: Equatable where NodeValue: Equatable, EdgeValue: Equatable {}

extension Graph.Node: Hashable where NodeValue: Hashable {}
extension Graph.Edge: Hashable where EdgeValue: Hashable {}
extension Graph: Hashable where NodeValue: Hashable, EdgeValue: Hashable {}

extension Graph.Node: Codable where NodeID: Codable, NodeValue: Codable {}
extension Graph.Edge: Codable where NodeID: Codable, EdgeID: Codable, EdgeValue: Codable {}

extension Graph: Codable where NodeID: Codable, NodeValue: Codable, EdgeID: Codable, EdgeValue: Codable {
    private enum CodingKeys: String, CodingKey { case nodes, edges }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            nodes: container.decode([Node].self, forKey: .nodes),
            edges: container.decode([Edge].self, forKey: .edges)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nodes, forKey: .nodes)
        try container.encode(edges, forKey: .edges)
    }
}
