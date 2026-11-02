import Foundation
import Primitives

private enum ReferenceExpectedError: Error {
    case missing_validation
}

func run_reference_set_tests() throws {
    typealias R = ReferenceSet<String, String>
    typealias G = Graph<String, String, String, String>
    let first = try R(references: [
        .init(id: "main", target: "A"),
        .init(id: "worktree", target: "A"),
    ])
    let moved = try R(references: [
        .init(id: "main", target: "B"),
        .init(id: "worktree", target: "A"),
    ])
    try expect(first.target(for: "main") == "A", "initial target")
    try expect(moved.target(for: "main") == "B", "new snapshot can retarget same reference")
    try expect(first.references(to: "A").map(\.id) == ["main", "worktree"], "multiple refs to same target")
    try expect(moved.target(for: "absent") == nil, "unknown reference")
    let graph = try G(nodes: [.init(id: "A", value: "node")], edges: [])
    try first.validate_targets(in: graph)
    do {
        try moved.validate_targets(in: graph)
        throw ReferenceExpectedError.missing_validation
    } catch ReferenceSetError<String, String>.unknown_target(reference: "main", target: "B") {}
    do {
        _ = try R(references: [.init(id: "same", target: "A"), .init(id: "same", target: "B")])
        throw ReferenceExpectedError.missing_validation
    } catch ReferenceSetError<String, String>.duplicate_reference("same") {}
    let encoded = try JSONEncoder().encode(moved)
    let decoded = try JSONDecoder().decode(R.self, from: encoded)
    try expect(decoded == moved, "validated Codable roundtrip")
    let malformed = Data(#"{"references":[{"id":"same","target":"A"},{"id":"same","target":"B"}]}"#.utf8)
    do {
        _ = try JSONDecoder().decode(R.self, from: malformed)
        throw ReferenceExpectedError.missing_validation
    } catch ReferenceSetError<String, String>.duplicate_reference("same") {}
}
