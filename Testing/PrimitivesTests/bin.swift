import Testing

private enum PrimitivesTestMainError: Error {
    case failed
}

@main
enum PrimitivesTestMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(
            PrimitivesTestSuite.suite,
            sink: reporter
        )

        print(
            await reporter.rendered()
        )

        if result.isFailure {
            throw PrimitivesTestMainError.failed
        }
    }
}

enum PrimitivesTestSuite {
    static let suite = TestSuite(
        "primitives",
        title: "Primitives tests",
        tags: [
            "primitives",
        ]
    ) {
        Test(
            "json-coding",
            tags: [
                "json",
                "coding",
            ]
        ) {
            try run_json_coding_tests()
        }

        Test(
            "json-value-native",
            tags: [
                "json",
                "native",
            ]
        ) {
            try run_json_value_native_tests()
        }

        Test(
            "tree",
            tags: [
                "tree",
            ]
        ) {
            try run_tree_tests()
        }

        Test(
            "graph",
            tags: [
                "graph",
            ]
        ) {
            try run_graph_tests()
        }

        Test(
            "json-decoding-diagnostics",
            tags: [
                "json",
                "decoding",
                "diagnostics",
            ]
        ) { test in
            try await PrimitivesTesting
                .runJSONDecodingDiagnostics(
                    test
                )
        }

        Test(
            "json-diagnostics-collection",
            tags: [
                "json",
                "diagnostics",
                "validation",
            ]
        ) { test in
            await PrimitivesTesting
                .runJSONDiagnosticsCollection(
                    test
                )
        }

        Test("invariant-nonthrowing", tags: ["invariant"]) {
            try test_invariant_nonthrowing()
        }

        Test("invariant-shared-error", tags: ["invariant"]) {
            try test_invariant_shared_error()
        }

        Test("invariant-nested-error", tags: ["invariant"]) {
            try test_invariant_nested_error()
        }

        Test("invariant-unrestricted-errors", tags: ["invariant"]) {
            try test_invariant_unrestricted_errors()
        }

        Test("invariant-composition", tags: ["invariant"]) {
            try test_invariant_composition()
        }

        Test("invariance-rule-core", tags: ["invariant", "invariance"]) {
            try test_invariance_rule_core()
        }

        Test("invariance-length-catalog", tags: ["invariant", "invariance"]) {
            try test_invariance_length_catalog()
        }

        Test("invariance-range-catalog", tags: ["invariant", "invariance"]) {
            try test_invariance_range_catalog()
        }

        Test("invariance-collection-catalog", tags: ["invariant", "invariance"]) {
            try test_invariance_collection_catalog()
        }

        Test("invariance-required-construction", tags: ["invariant", "invariance"]) {
            try test_invariance_required_and_construction()
        }

        Test("invariance-refinement-field-projection", tags: ["invariant", "invariance"]) {
            try test_invariance_field_projection()
        }

        Test("invariance-refinement-unordered-ranges", tags: ["invariant", "invariance"]) {
            try test_invariance_unordered_ranges()
        }

        Test("invariance-refinement-text-finite", tags: ["invariant", "invariance"]) {
            try test_invariance_text_and_finite()
        }

        Test("invariance-refinement-collection-count", tags: ["invariant", "invariance"]) {
            try test_invariance_collection_count()
        }

        Test("invariance-expansion-decimal", tags: ["invariant", "invariance"]) {
            try test_invariance_expansion_decimal()
        }

        Test("invariance-expansion-sign", tags: ["invariant", "invariance"]) {
            try test_invariance_expansion_sign()
        }

        Test("invariance-expansion-collections", tags: ["invariant", "invariance"]) {
            try test_invariance_expansion_collections()
        }

        Test("invariance-expansion-values", tags: ["invariant", "invariance"]) {
            try test_invariance_expansion_values()
        }

        Test("invariance-expansion-fields-and-sum", tags: ["invariant", "invariance"]) {
            try test_invariance_expansion_fields_and_sum()
        }

        Test("invariance-expansion-patterns-and-dates", tags: ["invariant", "invariance"]) {
            try test_invariance_expansion_patterns_dates()
        }

        Test("invariance-expansion-reconstruction", tags: ["invariant", "invariance"]) {
            try test_invariance_expansion_reconstruction()
        }
    }
}
