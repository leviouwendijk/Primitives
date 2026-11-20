import Foundation
import Primitives

private enum GraphDiagramExpectedError: Error {
    case missing_error
}

func run_graph_diagram_tests() throws {
    typealias G = Graph<String, String, String, String>
    typealias D = GraphDiagram<String, String>
    let ids = ["cycle_open", "P1", "I1", "P2", "I2", "P3", "I3", "gate", "reset_gate"]
    let links: [(String, String, String)] = [
        ("e_start", "cycle_open", "P1"),
        ("x1", "P1", "I1"), ("x2", "I1", "P2"),
        ("x3", "P2", "I2"), ("x4", "I2", "P3"),
        ("x5", "P3", "I3"), ("x6", "I3", "gate"),
        ("vP1", "P1", "P2"), ("vP2", "P2", "P3"),
        ("vI1", "I1", "I2"), ("vI2", "I2", "I3"),
        ("g1", "gate", "reset_gate"),
        ("c1", "reset_gate", "cycle_open"),
        ("c2", "reset_gate", "cycle_open"),
    ]
    let graph = try G(
        nodes: ids.map { .init(id: $0, value: $0) },
        edges: links.map { .init(id: $0.0, source: $0.1, destination: $0.2, value: "") }
    )
    let locations = Dictionary(uniqueKeysWithValues: ids.enumerated().map { index, id in
        (id, D.Point(row: index, lane: [1, 0, 2, 0, 2, 0, 2, 1, 1][index]))
    })
    let diagram = try graph.diagram(positions: locations)
    try expect(diagram.nodes.map(\.id) == ids, "node identity and graph order")
    try expect(diagram.edges.map(\.id) == links.map(\.0), "all 14 edges survive")
    try expect(diagram.position(of: "P2") == .init(row: 3, lane: 0), "left lane")
    try expect(diagram.position(of: "I2") == .init(row: 4, lane: 2), "right lane")
    try expect(diagram.route(of: "x1")?.points.contains(.init(row: 1, lane: 1)) == true, "inner crossing corridor")
    try expect(diagram.route(of: "vP1")?.points == [.init(row: 1, lane: 0), .init(row: 3, lane: 0)], "vertical lane")
    try expect(diagram.route(of: "c1")?.points.first == diagram.position(of: "reset_gate"), "upward return starts at reset")
    try expect(diagram.route(of: "c1")?.points.last == diagram.position(of: "cycle_open"), "upward return ends at cycle")
    try expect(diagram.route(of: "c1")?.points != diagram.route(of: "c2")?.points, "parallel feedback routes remain distinct")
    try expect(try graph.diagram(positions: locations) == diagram, "deterministic projection")
    try expect(try JSONDecoder().decode(D.self, from: JSONEncoder().encode(diagram)) == diagram, "validated roundtrip")

    var incomplete = locations
    incomplete.removeValue(forKey: "P2")
    do {
        _ = try graph.diagram(positions: incomplete)
        throw GraphDiagramExpectedError.missing_error
    } catch GraphDiagramError<String, String>.missing_position("P2") {}

    var unknown = locations
    unknown["outside"] = .init(row: 12, lane: 1)
    do {
        _ = try graph.diagram(positions: unknown)
        throw GraphDiagramExpectedError.missing_error
    } catch GraphDiagramError<String, String>.unmatched_positions {}

    var collision = locations
    collision["I1"] = collision["P1"]
    do {
        _ = try graph.diagram(positions: collision)
        throw GraphDiagramExpectedError.missing_error
    } catch GraphDiagramError<String, String>.occupied_position("I1") {}

    let empty = try G(nodes: [], edges: []).diagram(positions: [:])
    try expect(empty.nodes.isEmpty && empty.edges.isEmpty && empty.lane_count == 0, "empty diagram")
    let selfLoop = try G(
        nodes: [.init(id: "S", value: "")],
        edges: [.init(id: "self", source: "S", destination: "S", value: "")]
    ).diagram(positions: ["S": .init(row: 0, lane: 0)])
    try expect(selfLoop.route(of: "self")?.points.count == 5, "self-loop retained")

    // Explicit routes may be diagonal and must retain their edge identity.
    let explicit = try graph.diagram(
        positions: locations,
        routes: [
            "x1": [
                .init(row: 1, lane: 0),
                .init(row: 2, lane: 2)
            ]
        ]
    )
    try expect(explicit.edges.count == links.count, "explicit routes preserve all edges")
    try expect(
        explicit.route(of: "x1")?.points == [
            .init(row: 1, lane: 0),
            .init(row: 2, lane: 2)
        ],
        "diagonal route is retained"
    )
    try expect(
        explicit.route(of: "vP1")?.points == diagram.route(of: "vP1")?.points,
        "unspecified routes remain unchanged"
    )
    try expect(
        try JSONDecoder().decode(D.self, from: JSONEncoder().encode(explicit)) == explicit,
        "diagonal route survives serialization"
    )

    do {
        _ = try graph.diagram(
            positions: locations,
            routes: ["unknown": [.init(row: 0, lane: 0), .init(row: 1, lane: 1)]]
        )
        throw GraphDiagramExpectedError.missing_error
    } catch GraphDiagramError<String, String>.unmatched_routes {}

    do {
        _ = try graph.diagram(
            positions: locations,
            routes: ["x1": [.init(row: 1, lane: 0), .init(row: 1, lane: 0)]]
        )
        throw GraphDiagramExpectedError.missing_error
    } catch GraphDiagramError<String, String>.invalid_route("x1") {}

    let malformed = Data(#"{"nodes":[{"id":"A","position":{"row":-1,"lane":0}}],"edges":[]}"#.utf8)
    do {
        _ = try JSONDecoder().decode(D.self, from: malformed)
        throw GraphDiagramExpectedError.missing_error
    } catch GraphDiagramError<String, String>.invalid_position("A") {}
}
