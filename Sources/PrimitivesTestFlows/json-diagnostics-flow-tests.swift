import Primitives
import TestFlows

extension PrimitivesFlowTesting {
    static func runJSONDiagnosticsCollection() async throws
        -> [TestFlowDiagnostic]
    {
        let diagnostics = JSONDiagnostics(
            [
                JSONIssue(
                    kind: .missing,
                    path: JSONCodingPath(
                        [
                            .key("root"),
                            .key("children"),
                            .index(0),
                            .key("name"),
                        ]
                    ),
                    reason: "Required value is missing."
                ),
                JSONIssue(
                    kind: .typeMismatch,
                    path: JSONCodingPath(
                        [
                            .key("root"),
                            .key("children"),
                            .index(1),
                            .key("call"),
                        ]
                    ),
                    reason: "Expected an object."
                ),
                JSONIssue(
                    kind: .invalidValue,
                    path: JSONCodingPath(
                        [
                            .key("root"),
                            .key("children"),
                            .index(2),
                            .key("execution"),
                            .key("workspace"),
                            .key("subpath"),
                        ]
                    ),
                    reason: "Value is not valid in this context."
                ),
            ]
        )

        try Expect.false(
            diagnostics.isEmpty,
            "multiple JSON issues produce non-empty diagnostics"
        )

        try Expect.equal(
            diagnostics.issues.count,
            3,
            "JSON diagnostics retain every supplied issue"
        )

        try Expect.equal(
            diagnostics.issues[0].kind,
            .missing,
            "first issue retains its kind"
        )

        try Expect.equal(
            diagnostics.issues[0].path.jsonPath,
            "$.root.children[0].name",
            "first issue retains its precise JSON path"
        )

        try Expect.equal(
            diagnostics.issues[1].kind,
            .typeMismatch,
            "second issue remains independently classified"
        )

        try Expect.equal(
            diagnostics.issues[1].path.jsonPath,
            "$.root.children[1].call",
            "second issue retains its own JSON path"
        )

        try Expect.equal(
            diagnostics.issues[2].path.jsonPath,
            "$.root.children[2].execution.workspace.subpath",
            "later issues remain visible rather than collapsing to the first failure"
        )

        try Expect.equal(
            diagnostics.issues[2].reason,
            "Value is not valid in this context.",
            "issue reason remains caller-authored context"
        )

        let empty = JSONDiagnostics()

        try Expect.true(
            empty.isEmpty,
            "empty diagnostics are explicitly representable"
        )

        return [
            .field(
                "issues",
                "\(diagnostics.issues.count)"
            ),
            .field(
                "first_path",
                diagnostics.issues[0].path.jsonPath
            ),
            .field(
                "last_path",
                diagnostics.issues[2].path.jsonPath
            ),
        ]
    }
}
