/// An ordered conjunction: every contained rule must adhere.
public struct Invariance<Value>: Sendable {
    public let rules: [InvarianceRule<Value>]

    public init(_ rules: [InvarianceRule<Value>]) {
        self.rules = rules
    }

    public func violations(
        for value: Value
    ) -> [InvarianceViolation] {
        rules.flatMap { rule in
            rule.violations(for: value)
        }
    }

    public func require(
        _ value: Value
    ) throws(InvarianceFailure) {
        let found = violations(for: value)
        guard let first = found.first else {
            return
        }
        throw InvarianceFailure(first, remaining: Array(found.dropFirst()))
    }
}
