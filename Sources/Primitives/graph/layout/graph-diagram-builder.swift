public extension Graph {
    /// Builds an explicit-position spatial projection without requiring a DAG.
    /// Every graph node needs exactly one position. Edge order and identities are
    /// preserved; no edge is silently filtered to accommodate layout.
    func diagram(
        positions: [NodeID: GraphDiagram<NodeID, EdgeID>.Point]
    ) throws(GraphDiagramError<NodeID, EdgeID>) -> GraphDiagram<NodeID, EdgeID> {
        typealias Diagram = GraphDiagram<NodeID, EdgeID>
        typealias Point = Diagram.Point
        var placed: [Diagram.Node] = []
        for node in nodes {
            guard let position = positions[node.id] else { throw .missing_position(node.id) }
            placed.append(.init(id: node.id, position: position))
        }
        guard positions.count == nodes.count else { throw .unmatched_positions }
        let occupied = Set(positions.values)
        let largestRow = positions.values.map(\.row).max() ?? -1
        let largestLane = positions.values.map(\.lane).max() ?? -1
        var usedCorridors: [Int: [ClosedRange<Int>]] = [:]
        var placedEdges: [Diagram.Edge] = []

        func segmentClear(_ a: Point, _ b: Point) -> Bool {
            for point in occupied where point != a && point != b {
                if a.row == b.row && point.row == a.row &&
                   (min(a.lane, b.lane)...max(a.lane, b.lane)).contains(point.lane) {
                    return false
                }
                if a.lane == b.lane && point.lane == a.lane &&
                   (min(a.row, b.row)...max(a.row, b.row)).contains(point.row) {
                    return false
                }
            }
            return true
        }

        for edge in edges {
            guard let source = positions[edge.source],
                  let destination = positions[edge.destination] else {
                throw .unmatched_positions
            }
            let rowRange = min(source.row, destination.row)...max(source.row, destination.row)
            let route: [Point]
            if source != destination &&
               (source.row == destination.row || source.lane == destination.lane) &&
               segmentClear(source, destination) &&
               !placedEdges.contains(where: { $0.source == edge.source && $0.destination == edge.destination }) {
                route = [source, destination]
            } else if source.row == destination.row && source != destination {
                // Same-row detours use a dedicated row below every node, so the
                // horizontal segment cannot intersect a third node.
                let row = largestRow + 1 + placedEdges.count
                route = [source, Point(row: row, lane: source.lane),
                         Point(row: row, lane: destination.lane), destination]
            } else {
                // Prefer a free inner corridor for a compact braid, then allocate
                // distinct outer corridors for overlaps and parallel edges.
                var candidates: [Int] = []
                if source.lane != destination.lane {
                    let low = min(source.lane, destination.lane)
                    let high = max(source.lane, destination.lane)
                    if low + 1 < high { candidates += Array((low + 1)..<high) }
                }
                candidates += Array((largestLane + 1)...(largestLane + edges.count + 1))
                var chosen = largestLane + edges.count + 1
                for lane in candidates where lane != source.lane && lane != destination.lane {
                    let first = Point(row: source.row, lane: lane)
                    let last = Point(row: destination.row, lane: lane)
                    let used = usedCorridors[lane, default: []].contains {
                        $0.overlaps(rowRange)
                    }
                    if !used && segmentClear(source, first) &&
                       segmentClear(first, last) && segmentClear(last, destination) {
                        chosen = lane
                        break
                    }
                }
                usedCorridors[chosen, default: []].append(rowRange)
                if source == destination {
                    let row = largestRow + 1 + placedEdges.count
                    route = [source, Point(row: source.row, lane: chosen),
                             Point(row: row, lane: chosen),
                             Point(row: row, lane: source.lane), source]
                } else {
                    route = [source, Point(row: source.row, lane: chosen),
                             Point(row: destination.row, lane: chosen), destination]
                }
            }
            placedEdges.append(.init(
                id: edge.id, source: edge.source,
                destination: edge.destination, points: route
            ))
        }
        return try Diagram(nodes: placed, edges: placedEdges)
    }
}
