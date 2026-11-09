/// A terminal-independent spatial projection of a directed multigraph.
/// Unlike GraphLayout, multiple nodes may occupy different lanes of one row,
/// routes may travel upward, and parallel/feedback edges remain present.
public struct GraphDiagram<NodeID: Hashable, EdgeID: Hashable> {
    public struct Point: Hashable, Codable, Sendable {
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
        /// Orthogonal route in source-to-destination order, even for feedback edges.
        public let points: [Point]

        public init(id: EdgeID, source: NodeID, destination: NodeID, points: [Point]) {
            self.id = id
            self.source = source
            self.destination = destination
            self.points = points
        }
    }

    public let nodes: [Node]
    public let edges: [Edge]
    public let row_count: Int
    public let lane_count: Int

    public init(nodes: [Node], edges: [Edge]) throws(GraphDiagramError<NodeID, EdgeID>) {
        var positions: [NodeID: Point] = [:]
        var occupied: Set<Point> = []
        var maximumRow = -1
        var maximumLane = -1
        for node in nodes {
            guard positions[node.id] == nil else { throw .duplicate_node(node.id) }
            guard node.position.row >= 0, node.position.lane >= 0 else {
                throw .invalid_position(node.id)
            }
            guard occupied.insert(node.position).inserted else {
                throw .occupied_position(node.id)
            }
            positions[node.id] = node.position
            maximumRow = max(maximumRow, node.position.row)
            maximumLane = max(maximumLane, node.position.lane)
        }

        var seen: Set<EdgeID> = []
        for edge in edges {
            guard seen.insert(edge.id).inserted else { throw .duplicate_edge(edge.id) }
            guard let source = positions[edge.source],
                  let destination = positions[edge.destination] else {
                throw .unknown_edge_endpoint(edge.id)
            }
            guard edge.points.count >= 2,
                  edge.points.first == source,
                  edge.points.last == destination else {
                throw .invalid_route(edge.id)
            }
            for point in edge.points {
                guard point.row >= 0, point.lane >= 0 else { throw .invalid_route(edge.id) }
                maximumRow = max(maximumRow, point.row)
                maximumLane = max(maximumLane, point.lane)
            }
            for (a, b) in zip(edge.points, edge.points.dropFirst()) {
                guard (a.row == b.row) != (a.lane == b.lane) else {
                    throw .invalid_route(edge.id)
                }
            }
        }
        self.nodes = nodes
        self.edges = edges
        self.row_count = maximumRow + 1
        self.lane_count = maximumLane + 1
    }

    public func position(of id: NodeID) -> Point? {
        nodes.first(where: { $0.id == id })?.position
    }

    public func route(of id: EdgeID) -> Edge? {
        edges.first(where: { $0.id == id })
    }
}

public enum GraphDiagramError<NodeID: Hashable, EdgeID: Hashable>: Error {
    case duplicate_node(NodeID)
    case invalid_position(NodeID)
    case occupied_position(NodeID)
    case missing_position(NodeID)
    case unmatched_positions
    case duplicate_edge(EdgeID)
    case unknown_edge_endpoint(EdgeID)
    case invalid_route(EdgeID)
}

extension GraphDiagramError: Equatable {}
extension GraphDiagramError: Sendable where NodeID: Sendable, EdgeID: Sendable {}
extension GraphDiagram.Node: Sendable where NodeID: Sendable {}
extension GraphDiagram.Edge: Sendable where NodeID: Sendable, EdgeID: Sendable {}
extension GraphDiagram: Sendable where NodeID: Sendable, EdgeID: Sendable {}
extension GraphDiagram.Node: Equatable {}
extension GraphDiagram.Edge: Equatable {}
extension GraphDiagram: Equatable {}
extension GraphDiagram.Node: Hashable {}
extension GraphDiagram.Edge: Hashable {}
extension GraphDiagram: Hashable {}
extension GraphDiagram.Node: Codable where NodeID: Codable {}
extension GraphDiagram.Edge: Codable where NodeID: Codable, EdgeID: Codable {}

extension GraphDiagram: Codable where NodeID: Codable, EdgeID: Codable {
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
