import Primitives

private func construct<Value: Invariant>(
    _ type: Value.Type,
    from raw: Value.Raw
) throws(Value.Error) -> Value {
    try type.init(raw)
}

private func require_never_error<Value: Invariant>(
    _: Value.Type
) where Value.Error == Never {}

private func require_unrestricted_error<Value: Invariant>(
    _: Value.Type
) where Value.Error == any Swift.Error {}

private struct UniquePositiveNumbers: Invariant {
    enum Error: Swift.Error {
        case empty
        case duplicate(Int)
    }

    let numbers: [PositiveNumber]

    init(_ raw: [PositiveNumber]) throws(Error) {
        guard !raw.isEmpty else {
            throw .empty
        }

        var seen = Set<Int>()
        for number in raw {
            guard seen.insert(number.number).inserted else {
                throw .duplicate(number.number)
            }
        }

        self.numbers = raw
    }
}

func test_invariant_nonthrowing() throws {
    require_never_error(AlwaysValid.self)

    let value = construct(AlwaysValid.self, from: 42)
    try expect(value.number == 42, "nonthrowing invariant constructs without try")
}

func test_invariant_shared_error() throws {
    let value = try construct(TestType.self, from: .init(number: 0))
    try expect(value.num == 0, "shared typed error accepts a present number")

    do {
        _ = try construct(TestType.self, from: .init())
        try expect(false, "missing number must throw the shared error")
    } catch SharedInvariantError.num_required {}
}

func test_invariant_nested_error() throws {
    let value = try construct(PositiveNumber.self, from: 0)
    try expect(value.number == 0, "nested typed error accepts the lower bound")

    do {
        _ = try construct(PositiveNumber.self, from: -1)
        try expect(false, "negative number must throw the nested error")
    } catch PositiveNumber.Error.negative {}
}

func test_invariant_unrestricted_errors() throws {
    require_unrestricted_error(UnrestrictedNumber.self)

    let value = try construct(UnrestrictedNumber.self, from: 7)
    try expect(value.number == 7, "unrestricted invariant accepts a valid number")

    do {
        _ = try construct(UnrestrictedNumber.self, from: nil)
        try expect(false, "missing number must throw")
    } catch MissingNumberError.missing {}

    do {
        _ = try construct(UnrestrictedNumber.self, from: -1)
        try expect(false, "negative number must throw")
    } catch NegativeNumberError.negative {}
}

func test_invariant_composition() throws {
    let first = try PositiveNumber(1)
    let second = try PositiveNumber(2)

    let collection = try construct(
        UniquePositiveNumbers.self,
        from: [first, second]
    )
    try expect(
        collection.numbers.map(\.number) == [1, 2],
        "a collection can establish invariants over invariant-bearing elements"
    )

    do {
        _ = try construct(UniquePositiveNumbers.self, from: [])
        try expect(false, "empty collection must throw")
    } catch UniquePositiveNumbers.Error.empty {}

    do {
        _ = try construct(UniquePositiveNumbers.self, from: [first, first])
        try expect(false, "duplicate collection element must throw")
    } catch UniquePositiveNumbers.Error.duplicate(1) {}
}
