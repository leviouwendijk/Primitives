import Primitives

private struct InvarianceRefinementAccount: Sendable {
    struct Profile: Sendable {
        let name: String
    }

    let profile: Profile
    let amounts: [Int]
    let balance: Double
}

func test_invariance_field_projection() throws {
    let rules = Invariance<InvarianceRefinementAccount>([
        .field(\.profile, named: "profile", rules: [
            .field(\.name, named: "name", rules: [
                .text.nonblank,
                .length.min(3)
            ])
        ]),
        .field(\.amounts, named: "amounts", rules: [
            .elements.count.min(2),
            .elements.unique(by: { $0 })
        ])
    ])

    let issues = rules.violations(
        for: .init(
            profile: .init(name: "  "),
            amounts: [1, 1],
            balance: 0
        )
    )
    try expect(issues.count == 3, "nested field projection preserves all violations")
    try expect(
        issues[0].path == [.field("profile"), .field("name")],
        "nested field path is source independent"
    )
    try expect(
        issues[1].path == [.field("profile"), .field("name")],
        "second child violation retains the same nested path"
    )
    try expect(
        issues[2].path == [.field("amounts"), .index(1)],
        "element paths remain relative to their named field"
    )
    let valid = InvarianceRefinementAccount(
        profile: .init(name: "ledger"),
        amounts: [1, 2],
        balance: 10
    )
    try rules.require(valid)
}

func test_invariance_unordered_ranges() throws {
    let minimum = InvarianceRule<Double>.range.min(0)
    let maximum = InvarianceRule<Double>.range.max(100)
    try expect(
        minimum.violations(for: .nan).first?.code == .unordered_comparison,
        "NaN must not silently pass minimum"
    )
    try expect(
        maximum.violations(for: .nan).first?.code == .unordered_comparison,
        "NaN must not silently pass maximum"
    )
    let reason = minimum.violations(for: .nan).first?.reason
        as? InvarianceUnorderedComparison<Double>
    try expect(
        reason?.side == .minimum && reason?.actual.isNaN == true,
        "unordered reason preserves the original numeric evidence"
    )
    try expect(
        minimum.violations(for: -.infinity).first?.code == .below_minimum,
        "negative infinity has an ordinary below-minimum ordering"
    )
    try expect(
        maximum.violations(for: .infinity).first?.code == .above_maximum,
        "positive infinity has an ordinary above-maximum ordering"
    )
    try expect(minimum.violations(for: 0).isEmpty, "minimum remains inclusive")
    try expect(maximum.violations(for: 100).isEmpty, "maximum remains inclusive")
    try expect(
        InvarianceRule<Int>.range.min(0).violations(for: -1).first?.code == .below_minimum,
        "integer range semantics remain unchanged"
    )

    do {
        _ = try InvarianceRule<Double>.range.min_max(.nan, 100)
        try expect(false, "unordered bounds must be rejected during construction")
    } catch InvarianceRuleConfigurationError<Double>.incomparable_bounds(
        let minimum,
        let maximum
    ) {
        try expect(minimum.isNaN && maximum == 100, "invalid bounds preserve evidence")
    }
    do {
        _ = try InvarianceRule<Double>.range.min_max(100, 0)
        try expect(false, "reversed bounds must be rejected")
    } catch InvarianceRuleConfigurationError<Double>.inverted_bounds(
        let minimum,
        let maximum
    ) {
        try expect(minimum == 100 && maximum == 0, "reversed bounds remain typed")
    }
}

func test_invariance_text_and_finite() throws {
    let text = Invariance<String>([
        .text.nonblank,
        .length.max(16)
    ])
    try expect(text.violations(for: "").first?.code == .blank_text, "empty text is blank")
    try expect(
        text.violations(for: " \t\n").first?.code == .blank_text,
        "whitespace-only text is blank"
    )
    try expect(text.violations(for: "  a ").isEmpty, "nonblank rule does not trim or mutate")

    let finite = InvarianceRule<Double>.number.finite
    try expect(finite.violations(for: 10).isEmpty, "finite values pass")
    try expect(finite.violations(for: .nan).first?.code == .nonfinite_number, "NaN is not finite")
    let infinite = finite.violations(for: .infinity).first?.reason
        as? InvarianceNonfiniteNumber<Double>
    try expect(infinite?.actual == .infinity, "nonfinite reason retains typed value")
}

func test_invariance_collection_count() throws {
    let counts = Invariance<[Int]>([
        .elements.count.min(2),
        .elements.count.max(3)
    ])
    try expect(counts.violations(for: [1, 2]).isEmpty, "lower count inclusive")
    try expect(counts.violations(for: [1, 2, 3]).isEmpty, "upper count inclusive")
    let short = counts.violations(for: [1]).first?.reason as? InvarianceCollectionTooSmall
    try expect(short?.actual == 1 && short?.minimum == 2, "count minimum retains integers")
    let long = counts.violations(for: [1, 2, 3, 4]).first?.reason
        as? InvarianceCollectionTooLarge
    try expect(long?.actual == 4 && long?.maximum == 3, "count maximum retains integers")
    let combined = try InvarianceRule<[Int]>.elements.count.min_max(2, 3)
    try expect(combined.violations(for: [1, 2]).isEmpty, "combined count passes")
    do {
        _ = try InvarianceRule<[Int]>.elements.count.min_max(3, 2)
        try expect(false, "inverted cardinality bounds must throw")
    } catch InvarianceRuleConfigurationError<UInt>.inverted_bounds(
        let minimum,
        let maximum
    ) {
        try expect(minimum == 3 && maximum == 2, "count config preserves bounds")
    }
}
