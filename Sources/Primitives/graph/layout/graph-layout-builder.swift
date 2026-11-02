public extension Graph {
    /// Deterministic multi-lane layout of the selected DAG.
    /// A supplied order must list each graph node once and respect all
    /// selected edges in the requested orientation. Nonselected edges are
    /// not routed or used to constrain the order.
    func layout(
        order: [NodeID]? = nil,
        orientation: GraphLayout<NodeID, EdgeID>.Orientation = .source_first,
        including_edges include: (Edge) -> Bool = { _ in true }
    ) throws -> GraphLayout<NodeID, EdgeID> {
        typealias Layout = GraphLayout<NodeID, EdgeID>
        let selected = edges.filter(include)
        let ordered: [NodeID]
        if let order {
            var known: Set<NodeID> = []
            let valid_ids = Set(nodes.map(\.id))
            for id in order {
                guard valid_ids.contains(id) else {
                    throw GraphLayoutError<NodeID, EdgeID>.unknown_order_node(id)
                }
                guard known.insert(id).inserted else {
                    throw GraphLayoutError<NodeID, EdgeID>.duplicate_order_node(id)
                }
            }
            for node in nodes where !known.contains(node.id) {
                throw GraphLayoutError<NodeID, EdgeID>.missing_order_node(node.id)
            }
            ordered = order
        } else {
            // A single edge-selection snapshot avoids re-evaluating the predicate.
            let selection = try Graph(nodes: nodes, edges: selected)
            let topology = try selection.topological_order()
            ordered = orientation == .source_first ? topology : Array(topology.reversed())
        }

        let rows = Dictionary(uniqueKeysWithValues: ordered.enumerated().map { ($0.element, $0.offset) })
        var starting: [NodeID: [Edge]] = [:]
        var ending: [NodeID: [Edge]] = [:]
        for edge in selected {
            let start = orientation == .source_first ? edge.source : edge.destination
            let end = orientation == .source_first ? edge.destination : edge.source
            guard rows[start]! < rows[end]! else {
                throw GraphLayoutError<NodeID, EdgeID>.order_constraint_violation(edge.id)
            }
            starting[start, default: []].append(edge)
            ending[end, default: []].append(edge)
        }

        var pending: [EdgeID: (first: Layout.Point, travel_lane: Int)] = [:]
        var routes: [EdgeID: Layout.Edge] = [:]
        var occupied: Set<Int> = []
        var placed: [Layout.Node] = []
        var maximum_lane = -1

        func free_lane(_ occupied: Set<Int>) -> Int {
            var lane = 0
            while occupied.contains(lane) { lane += 1 }
            return lane
        }

        for (row, id) in ordered.enumerated() {
            let arrivals = ending[id] ?? []
            let lane = arrivals.compactMap { pending[$0.id]?.travel_lane }.min()
                ?? free_lane(occupied)
            let position = Layout.Point(row: row, lane: lane)
            placed.append(.init(id: id, position: position))
            maximum_lane = max(maximum_lane, lane)

            for edge in arrivals {
                guard let reserved = pending.removeValue(forKey: edge.id) else {
                    throw GraphLayoutError<NodeID, EdgeID>.invalid_edge_route(edge.id)
                }
                occupied.remove(reserved.travel_lane)
                var points: [Layout.Point] = [reserved.first]
                if reserved.first.lane != reserved.travel_lane {
                    points.append(.init(row: reserved.first.row, lane: reserved.travel_lane))
                }
                points.append(.init(row: row, lane: reserved.travel_lane))
                if reserved.travel_lane != lane { points.append(position) }
                routes[edge.id] = .init(
                    id: edge.id,
                    source: edge.source,
                    destination: edge.destination,
                    points: points
                )
            }

            for (index, edge) in (starting[id] ?? []).enumerated() {
                let travel_lane = index == 0 ? lane : free_lane(occupied)
                occupied.insert(travel_lane)
                maximum_lane = max(maximum_lane, travel_lane)
                pending[edge.id] = (first: position, travel_lane: travel_lane)
            }
        }

        let output_edges = try selected.map { edge -> Layout.Edge in
            guard let route = routes[edge.id] else {
                throw GraphLayoutError<NodeID, EdgeID>.invalid_edge_route(edge.id)
            }
            return route
        }
        return try Layout(
            orientation: orientation,
            nodes: placed,
            edges: output_edges,
            lane_count: maximum_lane + 1
        )
    }
}
