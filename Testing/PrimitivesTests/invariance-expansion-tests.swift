import Foundation
import Primitives

func test_invariance_expansion_decimal() throws {
    let precision = Invariance<Decimal>([.decimal.scale.max(2)])
    guard let exact = Decimal(string: "12.340"),
          let excessive = Decimal(string: "12.345") else {
        try expect(false, "decimal test fixture initialization")
        return
    }
    try expect(precision.violations(for: exact).isEmpty, "numeric scale permits trailing zeroes")
    let issue = precision.violations(for: excessive)
    try expect(issue.count == 1, "excess decimal precision is rejected")
    try expect(issue.first?.reason is InvarianceDecimalScaleExceeded, "precision evidence is typed")
    let nan = Invariance<Decimal>([.range.max(100)]).violations(for: .nan)
    try expect(nan.first?.code == .unordered_comparison, "Decimal NaN must fail even a max-only range")
    try expect(Invariance<Decimal>([.decimal.finite]).violations(for: .nan).count == 1, "Decimal NaN is nonfinite")
    do {
        _ = try InvarianceRule<Decimal>.range.min_max(.nan, 10)
        try expect(false, "NaN bound is not valid configuration")
    } catch InvarianceRuleConfigurationError<Decimal>.incomparable_bounds {}
}

func test_invariance_expansion_sign() throws {
    try expect(Invariance<Int>([.number.positive]).violations(for: 0).count == 1, "positive excludes zero")
    try expect(Invariance<Int>([.number.nonnegative]).violations(for: 0).isEmpty, "nonnegative includes zero")
    try expect(Invariance<Int>([.number.nonzero]).violations(for: -1).isEmpty, "nonzero permits negatives")
    try expect(Invariance<Double>([.number.nonzero]).violations(for: .nan).count == 1, "NaN cannot satisfy nonzero")
    try expect(Invariance<Decimal>([.number.nonzero]).violations(for: .nan).count == 1, "Decimal NaN cannot satisfy nonzero")
}

func test_invariance_expansion_collections() throws {
    let rules = Invariance<[Int]>([
        .elements.unique,
        .elements.each([.range.min(0)]),
        .elements.contains(3),
        .elements.all(in: [0, 3, 4])
    ])
    let violations = rules.violations(for: [-1, 3, 3])
    try expect(violations.count == 3, "duplicate, element range, and disallowed element")
    try expect(violations[0].path == [.index(2)], "duplicate index")
    try expect(violations[1].path == [.index(0)], "element-wise diagnostic index")
    try expect(violations[2].path == [.index(0)], "membership diagnostic index")
}

func test_invariance_expansion_values() throws {
    try expect(Invariance<String>([.value.equal(to: "EUR")]).violations(for: "USD").count == 1, "typed equality")
    try expect(Invariance<String>([.value.one_of(["EUR", "USD"])]).violations(for: "JPY").count == 1, "typed membership")
}

private struct InvarianceExpansionPair: Sendable {
    let debit: Decimal
    let credit: Decimal
}

func test_invariance_expansion_fields_and_sum() throws {
    let rules = Invariance<InvarianceExpansionPair>([
        .fields.equal(\.debit, \.credit, named: "debit", and: "credit")
    ])
    let result = rules.violations(for: .init(debit: 9, credit: 10))
    try expect(result.first?.reason is InvarianceFieldsUnequal<Decimal>, "typed field mismatch")
    try expect(Invariance<[Decimal]>([.sum.equal(to: 3)]).violations(for: [1, 2]).isEmpty, "decimal sum")
    try expect(Invariance<[Decimal]>([.sum.equal(to: 3)]).violations(for: [1, 1]).count == 1, "decimal sum mismatch")
}

func test_invariance_expansion_patterns_dates() throws {
    let regex = try InvarianceRule<String>.text.matches("^[A-Z]{3}$")
    try expect(regex.violations(for: "EUR").isEmpty, "matching text")
    try expect(regex.violations(for: "eur").count == 1, "nonmatching text")
    let jan = Date(timeIntervalSince1970: 0)
    let feb = Date(timeIntervalSince1970: 60 * 60 * 24 * 31)
    try expect(Invariance<Date>([.date.range.min(jan)]).violations(for: feb).isEmpty, "date range")
}

private struct InvarianceExpansionPositive: MutableInvariant {
    enum Error: Swift.Error { case not_positive }
    struct Raw { var number: Int }
    let number: Int
    var raw: Raw { .init(number: number) }

    init(_ raw: Raw) throws(Error) {
        guard raw.number > 0 else { throw .not_positive }
        self.number = raw.number
    }
}

func test_invariance_expansion_reconstruction() throws {
    var value = try InvarianceExpansionPositive(.init(number: 2))
    do {
        try value.update { $0.number = -1 }
        try expect(false, "invalid updates must throw")
    } catch InvarianceExpansionPositive.Error.not_positive {}
    try expect(value.number == 2, "failed update leaves original intact")
    try value.update { $0.number = 3 }
    try expect(value.number == 3, "valid update reconstructs")
    let new_value = try value.updating { $0.number = 4 }
    try expect(value.number == 3 && new_value.number == 4, "nonmutating reconstruction is independent")
}
