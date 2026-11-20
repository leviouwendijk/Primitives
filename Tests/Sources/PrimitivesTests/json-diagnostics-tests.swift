import Primitives
import Testing

extension PrimitivesTesting {
    static func runJSONDiagnosticsCollection(
        _ test: TestContext
    ) async {
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

        await test.expect(
            !diagnostics.isEmpty,
            "multiple JSON issues produce non-empty diagnostics"
        )

        await test.expect(
            diagnostics.issues.count,
            equals: 3,
            "JSON diagnostics retain every supplied issue"
        )

        await test.expect(
            diagnostics.issues[0].kind,
            equals: .missing,
            "first issue retains its kind"
        )

        await test.expect(
            diagnostics.issues[0].path.jsonPath,
            equals: "$.root.children[0].name",
            "first issue retains its precise JSON path"
        )

        await test.expect(
            diagnostics.issues[1].kind,
            equals: .typeMismatch,
            "second issue remains independently classified"
        )

        await test.expect(
            diagnostics.issues[1].path.jsonPath,
            equals: "$.root.children[1].call",
            "second issue retains its own JSON path"
        )

        await test.expect(
            diagnostics.issues[2].path.jsonPath,
            equals: "$.root.children[2].execution.workspace.subpath",
            "later issues remain visible rather than collapsing to the first failure"
        )

        await test.expect(
            diagnostics.issues[2].reason,
            equals: "Value is not valid in this context.",
            "issue reason remains caller-authored context"
        )

        let empty = JSONDiagnostics()

        await test.expect(
            empty.isEmpty,
            "empty diagnostics are explicitly representable"
        )

        await test.record(
            .field(
                "issues",
                "\(diagnostics.issues.count)"
            )
        )
        await test.record(
            .field(
                "first_path",
                diagnostics.issues[0].path.jsonPath
            )
        )
        await test.record(
            .field(
                "last_path",
                diagnostics.issues[2].path.jsonPath
            )
        )
    }
}
