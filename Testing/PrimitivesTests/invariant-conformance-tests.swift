import Foundation
import Primitives

private func construct_invariant<Value: Invariant>(
    _ type: Value.Type,
    from raw: Value.Raw
) throws(Value.Error) -> Value {
    try type.init(raw)
}

private struct InvariantBridgeRecord: Sendable {
    let day: Int
}

func test_invariant_primitive_conformances() throws {
    let day = try construct_invariant(DayOfMonth.self, from: 31)
    try expect(day.raw == 31, "DayOfMonth constructs through Invariant")
    do {
        _ = try construct_invariant(DayOfMonth.self, from: 32)
        try expect(false, "DayOfMonth rejects an out-of-range day")
    } catch DayOfMonthError.outOfRange(32) {}

    let name = try construct_invariant(NonBlankString.self, from: "  ledger  ")
    try expect(name.raw == "ledger", "NonBlankString raw is the normalized value")

    let identifier = try construct_invariant(StringIdentifierValue.self, from: "invoice-1")
    try expect(identifier.raw == "invoice-1", "StringIdentifierValue constructs through Invariant")

    let quarter = try construct_invariant(YearQuarter.self, from: .init(year: 2026, quarter: 3))
    let next_quarter = try quarter.updating { $0.quarter = 4 }
    try expect(next_quarter.label == "2026Q4", "YearQuarter reconstructs through its raw value")
    try expect(quarter.label == "2026Q3", "nonmutating reconstruction leaves the original intact")
    do {
        _ = try quarter.updating { $0.quarter = 5 }
        try expect(false, "YearQuarter rejects quarter 5")
    } catch YearQuarterError.invalidQuarter(5) {}

    let partial = try construct_invariant(PartialDate.self, from: .init(year: 2026, month: 2))
    try expect(partial.precision == .month, "PartialDate constructs month precision")
    let coarse = try partial.updating { $0.month = nil }
    try expect(coarse.precision == .year, "PartialDate coarsens through reconstruction")
    do {
        _ = try partial.updating { $0.day = 30 }
        try expect(false, "February 30 must be rejected")
    } catch DateSpecificationError.invalidPartialDate {}

    var tree_address = try TreeAddress(root: 0, descendants: [1, 2])
    do {
        try tree_address.update { $0.descendants.append(-1) }
        try expect(false, "negative descendant must be rejected")
    } catch TreeAddress.Error.negative_descendant(2, -1) {}
    try expect(tree_address.descendants == [1, 2], "failed TreeAddress update leaves the value intact")
    try tree_address.update { $0.descendants.append(3) }
    try expect(tree_address.descendants == [1, 2, 3], "valid TreeAddress update reconstructs")

    do {
        _ = try construct_invariant(TreeTraversalLimits.self, from: -1)
        try expect(false, "negative traversal depth must be rejected")
    } catch TreeTraversalLimitError.negative_maximum_depth(-1) {}
    let unlimited = try construct_invariant(TreeTraversalLimits.self, from: nil)
    try expect(unlimited.raw == nil, "unlimited traversal round trips through raw")

    typealias G = Graph<String, String, String, String>
    let graph = try G(nodes: [.init(id: "A", value: "a")], edges: [])
    let extended = try graph.updating { raw in
        raw.nodes.append(.init(id: "B", value: "b"))
        raw.edges.append(.init(id: "ab", source: "A", destination: "B", value: "call"))
    }
    try expect(extended.edges.map(\.id) == ["ab"], "Graph reconstructs with full revalidation")
    do {
        _ = try graph.updating { raw in
            raw.edges.append(.init(id: "bad", source: "A", destination: "Z", value: "call"))
        }
        try expect(false, "dangling edge must be rejected")
    } catch GraphValidationError<String, String>.unknown_destination("bad", "Z") {}
}

func test_codable_invariant_coding() throws {
    let quarter = try YearQuarter(year: 2026, quarter: 3)
    let quarter_data = try JSONEncoder().encode(quarter)
    let quarter_object = try JSONDecoder().decode(JSONValue.self, from: quarter_data).objectValue
    try expect(quarter_object == ["year": .int(2026), "quarter": .int(3)], "YearQuarter wire format is unchanged")
    try expect(try JSONDecoder().decode(YearQuarter.self, from: quarter_data) == quarter, "YearQuarter round trips")
    try expect_construction_failure(
        YearQuarter.self,
        json: #"{"year":2026,"quarter":5}"#,
        underlying: YearQuarterError.self
    )

    let month = try PartialDate(year: 2026, month: 10)
    let month_data = try JSONEncoder().encode(month)
    let month_object = try JSONDecoder().decode(JSONValue.self, from: month_data).objectValue
    try expect(month_object == ["year": .int(2026), "month": .int(10)], "PartialDate omits absent components")
    try expect(try JSONDecoder().decode(PartialDate.self, from: month_data) == month, "PartialDate round trips")
    try expect(try JSONDecoder().decode(PartialDate.self, from: Data("{}".utf8)).isEmpty, "empty PartialDate decodes")
    try expect_construction_failure(
        PartialDate.self,
        json: #"{"month":3}"#,
        underlying: DateSpecificationError.self
    )
}

func test_invariance_construction_bridge() throws {
    let rules = Invariance<InvariantBridgeRecord>([
        .field(\.day, named: "day", rules: [.constructs(DayOfMonth.self)])
    ])
    try expect(rules.violations(for: .init(day: 12)).isEmpty, "constructible raw value adheres")
    let issues = rules.violations(for: .init(day: 40))
    try expect(issues.count == 1, "construction failure is one violation")
    try expect(issues.first?.path == [.field("day")], "construction failure keeps its field path")
    try expect(issues.first?.code == .custom("construction.failed"), "construction failure has a stable code")
    let reason = issues.first?.reason as? InvarianceConstructionFailed<DayOfMonth>
    try expect(reason?.error == .outOfRange(40), "construction failure preserves the typed error")

    let optional = Invariance<Int?>([.when_present([InvarianceRule<Int>.range.min(0)])])
    try expect(optional.violations(for: nil).isEmpty, "absent value adheres to when_present")
    try expect(optional.violations(for: 3).isEmpty, "present adhering value passes")
    try expect(optional.violations(for: -1).count == 1, "present violating value fails")

    try expect(
        Invariance<Int>([.number.positive]).violations(for: 0).first?.code == .custom("number.positive"),
        "positive has a distinct code"
    )
    try expect(
        Invariance<Int>([.number.nonzero]).violations(for: 0).first?.code == .custom("number.nonzero"),
        "nonzero has a distinct code"
    )
    try expect(
        Invariance<String>([.value.equal(to: "EUR")]).violations(for: "USD").first?.message
            == "Value does not equal the expected value.",
        "catalog reasons carry messages"
    )

    let currency = try InvarianceRule<String>.text.matches("^[A-Z]{3}$")
    try expect(
        currency.violations(for: "EUR").isEmpty && currency.violations(for: "USD").isEmpty,
        "compiled pattern is reused across evaluations"
    )
    try expect(
        currency.violations(for: "eu").first?.message == "Text does not match pattern ^[A-Z]{3}$.",
        "pattern mismatch has a message"
    )
}

private func expect_construction_failure<Value: Decodable, Failure: Error>(
    _ type: Value.Type,
    json: String,
    underlying: Failure.Type
) throws {
    do {
        _ = try JSONDecoder().decode(type, from: Data(json.utf8))
    } catch let error as DecodingError {
        guard case .dataCorrupted(let context) = error else {
            throw error
        }
        try expect(context.underlyingError is Failure, "decoding preserves the typed construction error")
        return
    }
    try expect(false, "invalid \(Value.self) must not decode")
}
