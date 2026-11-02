/// A terminal-independent vertical projection of an ordered directed graph.
/// Rows increase downward. Lanes are nonnegative horizontal indices.
/// Every canonical node appears exactly once; edge routes preserve edge IDs.
public struct GraphLayout<NodeID: Hashable, EdgeID: Hashable> {
    public enum Orientation: String, Sendable, Hashable, Codable {
        case source_first
        case destination_first
    }

    public struct Point: Sendable, Hashable, Codable {
        public let row: Int
        public let lane: Int

        public init(row: Int, lane: Int) {
            self.row = row
            self.lane = lane
        }
    }

    public struct Node {
        public let id: NodeID
        public let position: Point

        public init(id: NodeID, position: Point) {
            self.id = id
            self.position = position
        }
    }

    public struct Edge {
        public let id: EdgeID
        public let source: NodeID
        public let destination: NodeID
        /// Top-to-bottom, orthogonal polyline, independent of edge direction.
        public let points: [Point]

        public init(id: EdgeID, source: NodeID, destination: NodeID, points: [Point]) {
            self.id = id
            self.source = source
            self.destination = destination
            self.points = points
        }
    }

    public let orientation: Orientation
    public let nodes: [Node]
    public let edges: [Edge]
    public let lane_count: Int

    /// Validates layout coordinates and endpoint identity on construction.
    public init(
        orientation: Orientation,
        nodes: [Node],
        edges: [Edge],
        lane_count: Int
    ) throws(GraphLayoutError<NodeID, EdgeID>) {
        guard lane_count >= 0, (nodes.isEmpty ? lane_count == 0 : lane_count > 0) else {
            throw .invalid_lane_count(lane_count)
        }
        var located: [NodeID: Point] = [:]
        for (row, node) in nodes.enumerated() {
            guard located[node.id] == nil else { throw .duplicate_node(node.id) }
            guard node.position.row == row else { throw .invalid_node_row(node.id) }
            guard (0..<lane_count).contains(node.position.lane) else {
                throw .invalid_node_lane(node.id)
            }
            located[node.id] = node.position
        }
        var used_edges: Set<EdgeID> = []
        for edge in edges {
            guard used_edges.insert(edge.id).inserted else { throw .duplicate_edge(edge.id) }
            guard let source = located[edge.source], let destination = located[edge.destination] else {
                throw .unknown_edge_endpoint(edge.id)
            }
            let first = orientation == .source_first ? source : destination
            let last = orientation == .source_first ? destination : source
            guard first.row < last.row,
                  edge.points.count >= 2,
                  edge.points.first == first,
                  edge.points.last == last else {
                throw .invalid_edge_route(edge.id)
            }
            for point in edge.points {
                guard (first.row...last.row).contains(point.row),
                      (0..<lane_count).contains(point.lane) else {
                    throw .invalid_edge_route(edge.id)
                }
            }
            for pair in zip(edge.points, edge.points.dropFirst()) {
                let a = pair.0
                let b = pair.1
                guard b.row >= a.row,
                      (a.row == b.row) != (a.lane == b.lane) else {
                    throw .invalid_edge_route(edge.id)
                }
            }
        }
        self.orientation = orientation
        self.nodes = nodes
        self.edges = edges
        self.lane_count = lane_count
    }

    public func position(of id: NodeID) -> Point? {
        nodes.first(where: { $0.id == id })?.position
    }

    public func route(of id: EdgeID) -> Edge? {
        edges.first(where: { $0.id == id })
    }
}

public enum GraphLayoutError<NodeID: Hashable, EdgeID: Hashable>: Error {
    case invalid_lane_count(Int)
    case duplicate_node(NodeID)
    case duplicate_edge(EdgeID)
    case invalid_node_row(NodeID)
    case invalid_node_lane(NodeID)
    case unknown_edge_endpoint(EdgeID)
    case invalid_edge_route(EdgeID)
    case duplicate_order_node(NodeID)
    case unknown_order_node(NodeID)
    case missing_order_node(NodeID)
    case order_constraint_violation(EdgeID)
}

extension GraphLayoutError: Equatable {}
extension GraphLayoutError: Sendable where NodeID: Sendable, EdgeID: Sendable {}
extension GraphLayout.Node: Sendable where NodeID: Sendable {}
extension GraphLayout.Edge: Sendable where NodeID: Sendable, EdgeID: Sendable {}
extension GraphLayout: Sendable where NodeID: Sendable, EdgeID: Sendable {}
extension GraphLayout.Node: Equatable {}
extension GraphLayout.Edge: Equatable {}
extension GraphLayout: Equatable {}
extension GraphLayout.Node: Hashable {}
extension GraphLayout.Edge: Hashable {}
extension GraphLayout: Hashable {}
extension GraphLayout.Node: Codable where NodeID: Codable {}
extension GraphLayout.Edge: Codable where NodeID: Codable, EdgeID: Codable {}
extension GraphLayout: Codable where NodeID: Codable, EdgeID: Codable {
    private enum CodingKeys: String, CodingKey {
        case orientation, nodes, edges, lane_count
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            orientation: container.decode(Orientation.self, forKey: .orientation),
            nodes: container.decode([Node].self, forKey: .nodes),
            edges: container.decode([Edge].self, forKey: .edges),
            lane_count: container.decode(Int.self, forKey: .lane_count)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(orientation, forKey: .orientation)
        try container.encode(nodes, forKey: .nodes)
        try container.encode(edges, forKey: .edges)
        try container.encode(lane_count, forKey: .lane_count)
    }
}
