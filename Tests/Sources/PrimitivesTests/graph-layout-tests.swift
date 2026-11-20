import Foundation
import Primitives

private enum LayoutExpectedError: Error {
    case missing_error
}

func run_graph_layout_tests() throws {
    typealias G = Graph<String, String, String, String>
    typealias L = GraphLayout<String, String>
    let graph = try G(
        nodes: [
            .init(id: "A", value: "root"),
            .init(id: "B", value: "branch"),
            .init(id: "C", value: "branch"),
            .init(id: "D", value: "merge"),
            .init(id: "E", value: "independent"),
        ],
        edges: [
            .init(id: "ab", source: "A", destination: "B", value: "ancestry"),
            .init(id: "ac", source: "A", destination: "C", value: "ancestry"),
            .init(id: "bd", source: "B", destination: "D", value: "ancestry"),
            .init(id: "cd", source: "C", destination: "D", value: "ancestry"),
            .init(id: "db", source: "D", destination: "B", value: "annotation"),
        ]
    )
    let ordered = ["A", "B", "C", "D", "E"]
    let layout = try graph.layout(order: ordered, including_edges: { $0.value == "ancestry" })
    try expect(layout.nodes.map(\.id) == ordered, "explicit topological row order")
    try expect(layout.nodes.map(\.position.row) == Array(0..<5), "contiguous rows")
    try expect(layout.lane_count == 2, "split and merge reserve two lanes")
    try expect(layout.position(of: "A")?.lane == 0, "root occupies first lane")
    try expect(layout.position(of: "C")?.lane == 1, "parallel branch remains on lane one")
    try expect(layout.position(of: "D")?.lane == 0, "merge converges on deterministic lane")
    try expect(layout.route(of: "cd")?.points.last == layout.position(of: "D"), "edge reaches canonical target")
    try expect(layout.route(of: "cd")?.points.contains(.init(row: 3, lane: 1)) == true, "merge route spans adjacent lanes")
    try expect(layout.edges.map(\.id) == ["ab", "ac", "bd", "cd"], "excluded semantic edges do not receive routes")
    try expect(try graph.layout(order: ordered, including_edges: { $0.value == "ancestry" }) == layout, "stable repeated layout")
    let decoded = try JSONDecoder().decode(L.self, from: JSONEncoder().encode(layout))
    try expect(decoded == layout, "validated Codable roundtrip")

    do {
        _ = try graph.layout(order: ["A", "B", "D", "C", "E"])
        throw LayoutExpectedError.missing_error
    } catch GraphLayoutError<String, String>.order_constraint_violation {}
    do {
        _ = try graph.layout(order: ["A", "B", "C", "D", "D"], including_edges: { $0.value == "ancestry" })
        throw LayoutExpectedError.missing_error
    } catch GraphLayoutError<String, String>.duplicate_order_node("D") {}
    do {
        _ = try graph.layout(order: ["A", "B", "C", "D"], including_edges: { $0.value == "ancestry" })
        throw LayoutExpectedError.missing_error
    } catch GraphLayoutError<String, String>.missing_order_node("E") {}
    do {
        _ = try graph.layout(order: ["A", "B", "C", "D", "G"], including_edges: { $0.value == "ancestry" })
        throw LayoutExpectedError.missing_error
    } catch GraphLayoutError<String, String>.unknown_order_node("G") {}
    do {
        _ = try graph.layout(including_edges: { _ in true })
        throw LayoutExpectedError.missing_error
    } catch GraphTopologyError<String>.cycle_detected {}

    let reversed = try graph.layout(
        order: ["E", "D", "C", "B", "A"],
        orientation: .destination_first,
        including_edges: { $0.value == "ancestry" }
    )
    try expect(reversed.nodes.map(\.id) == ["E", "D", "C", "B", "A"], "reverse orientation keeps requested rows")
    try expect(reversed.route(of: "ab")?.points.first == reversed.position(of: "B"), "reverse orientation begins at destination")
    try expect(reversed.route(of: "ab")?.points.last == reversed.position(of: "A"), "reverse orientation ends at source")

    let parallel = try G(
        nodes: [.init(id: "A", value: ""), .init(id: "B", value: "")],
        edges: [
            .init(id: "first", source: "A", destination: "B", value: ""),
            .init(id: "second", source: "A", destination: "B", value: ""),
        ]
    )
    let parallel_layout = try parallel.layout()
    try expect(parallel_layout.lane_count == 2, "parallel edges retain independent lanes")
    try expect(parallel_layout.edges.map(\.id) == ["first", "second"], "parallel edge identity maintained")
    let empty = try G(nodes: [], edges: []).layout()
    try expect(empty.lane_count == 0 && empty.nodes.isEmpty, "empty graph layout")

    let references = try ReferenceSet<String, String>(references: [
        .init(id: "main", target: "D"),
        .init(id: "other", target: "D"),
        .init(id: "outside", target: "Z"),
    ])
    let placed = layout.place_references(references)
    try expect(placed.map(\.id) == ["main", "other", "outside"], "reference order preserved")
    try expect(placed[0].position == layout.position(of: "D"), "reference locates node")
    try expect(placed[1].position == placed[0].position, "multiple refs share a target")
    try expect(placed[2].target == "Z" && placed[2].position == nil, "off-layout reference is retained")
    let reference_roundtrip = try JSONDecoder().decode(
        [L.ReferencePlacement<String>].self,
        from: JSONEncoder().encode(placed)
    )
    try expect(reference_roundtrip == placed, "reference placements serialize without losing identities")

    let malformed = Data(#"{"orientation":"source_first","nodes":[{"id":"A","position":{"row":2,"lane":0}}],"edges":[],"lane_count":1}"#.utf8)
    do {
        _ = try JSONDecoder().decode(L.self, from: malformed)
        throw LayoutExpectedError.missing_error
    } catch GraphLayoutError<String, String>.invalid_node_row("A") {}
}
