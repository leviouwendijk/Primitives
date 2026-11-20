import Primitives

private struct CustomNegative: InvarianceReason {
    let actual: Int
    var code: InvarianceCode { .custom("nonpositive") }
    var message: String { "Expected a positive number." }
}

private struct TestRecord: Sendable {
    let id: Int
}

private struct RuleBasedName: Invariant {
    typealias Error = InvarianceFailure

    static let invariance = Invariance<String>([
        .length.min(3),
        .length.max(16),
    ])

    let value: String

    init(_ raw: String) throws(Error) {
        try Self.invariance.require(raw)
        self.value = raw
    }
}

func test_invariance_rule_core() throws {
    let positive = InvarianceRule<Int>.predicate(
        where: { $0 > 0 },
        on_failure: { InvarianceViolation(CustomNegative(actual: $0)) }
    ).at(.field("number"))

    let even = InvarianceRule<Int> { value in
        value.isMultiple(of: 2) ? [] : [
            InvarianceViolation(CustomNegative(actual: value))
        ]
    }
    let specification = Invariance<Int>([positive, even])
    let issues = specification.violations(for: -3)

    try expect(issues.count == 2, "collect violations in rule order")
    try expect(issues[0].path == [.field("number")], "preserve semantic path")
    try expect(issues[0].code == .custom("nonpositive"), "preserve stable code")
    try expect(issues[0].message == "Expected a positive number.", "preserve message")
    let reason = issues[0].reason as? CustomNegative
    try expect(reason?.actual == -3, "preserve typed raw failure evidence")

    var failed: InvarianceFailure?
    do {
        try specification.require(-3)
    } catch {
        failed = error
    }
    try expect(failed?.violations.count == 2, "typed error contains all violations")
    try specification.require(2)
}

func test_invariance_length_catalog() throws {
    let spec = Invariance<String>([
        .length.min(3),
        .length.max(16),
    ])
    try expect(spec.violations(for: "abc").isEmpty, "minimum is inclusive")
    try expect(spec.violations(for: String(repeating: "a", count: 16)).isEmpty,
               "maximum is inclusive")
    let short = spec.violations(for: "ab")
    let long = spec.violations(for: String(repeating: "a", count: 17))
    try expect((short.first?.reason as? InvarianceLengthTooShort)?.actual == 2,
               "typed short length evidence")
    try expect((long.first?.reason as? InvarianceLengthTooLong)?.maximum == 16,
               "typed maximum evidence")

    let combined = try InvarianceRule<String>.length.min_max(3, 16)
    try expect(combined.violations(for: "abc").isEmpty, "combined rule passes")
    try expect(combined.violations(for: "ab").count == 1, "combined rule fails")
    try expect(InvarianceRule<String>.length.max(1)
        .violations(for: "👨‍👩‍👦").isEmpty, "length uses grapheme clusters")

    var invalid: InvarianceRuleConfigurationError<UInt>?
    do {
        _ = try InvarianceRule<String>.length.min_max(16, 3)
    } catch {
        invalid = error
    }
    if case .inverted_bounds(let minimum, let maximum) = invalid {
        try expect(minimum == 16 && maximum == 3, "invalid config preserves bounds")
    } else {
        try expect(false, "inverted bounds must reject rule construction")
    }
}

func test_invariance_range_catalog() throws {
    let spec = Invariance<Int>([
        .range.min(0),
        .range.max(100),
    ])
    try expect(spec.violations(for: 0).isEmpty, "minimum is inclusive")
    try expect(spec.violations(for: 100).isEmpty, "maximum is inclusive")
    try expect((spec.violations(for: -1).first?.reason
                as? InvarianceBelowMinimum<Int>)?.actual == -1,
               "minimum preserves typed evidence")
    try expect((spec.violations(for: 101).first?.reason
                as? InvarianceAboveMaximum<Int>)?.maximum == 100,
               "maximum preserves typed evidence")

    let combined = try InvarianceRule<Int>.range.min_max(0, 100)
    try expect(combined.violations(for: 50).isEmpty, "combined range passes")
    var invalid: InvarianceRuleConfigurationError<Int>?
    do {
        _ = try InvarianceRule<Int>.range.min_max(100, 0)
    } catch {
        invalid = error
    }
    if case .inverted_bounds(let minimum, let maximum) = invalid {
        try expect(minimum == 100 && maximum == 0, "typed inverted bounds")
    } else {
        try expect(false, "reversed range must reject construction")
    }
}

func test_invariance_collection_catalog() throws {
    let spec = Invariance<[TestRecord]>([
        .elements.nonempty,
        .elements.unique(by: \.id),
    ])
    let empty = spec.violations(for: [])
    try expect(empty.count == 1 && empty[0].code == .empty_collection,
               "empty collection has a canonical reason")
    try expect(spec.violations(for: [.init(id: 1), .init(id: 2)]).isEmpty,
               "distinct keys pass")
    let duplicate = spec.violations(for: [
        .init(id: 2), .init(id: 3), .init(id: 2), .init(id: 2),
    ])
    try expect(duplicate.count == 2, "report every duplicate after first")
    try expect(duplicate[0].path == [.index(2)], "duplicate positional path")
    try expect(duplicate[1].path == [.index(3)], "second duplicate path")
    let reason = duplicate[0].reason as? InvarianceDuplicateElement<Int>
    try expect(reason?.key == 2 && reason?.first_index == 0
               && reason?.duplicate_index == 2, "duplicate evidence preserved")
}

func test_invariance_required_and_construction() throws {
    let required = InvarianceRule<Int?>.required()
    try expect(required.violations(for: nil).first?.code == .missing_value,
               "nil reports missing value")
    try expect(required.violations(for: 0).isEmpty,
               "present zero is not missing")

    let name = try RuleBasedName("ledger")
    try expect(name.value == "ledger", "invariant constructs from adhering input")
    var failure: InvarianceFailure?
    do {
        _ = try RuleBasedName("ab")
    } catch {
        failure = error
    }
    try expect(failure?.first.code == .length_below_minimum,
               "invariant constructor propagates canonical reason")
}
