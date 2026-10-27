/// Evidence that a raw value cannot construct an invariant-bearing type.
public struct InvarianceConstructionFailed<Target: Invariant>: InvarianceReason
where Target.Error: Sendable {
    public let error: Target.Error

    public init(
        error: Target.Error
    ) {
        self.error = error
    }

    public var code: InvarianceCode { .custom("construction.failed") }
    public var message: String { "Value cannot construct \(Target.self): \(error)" }
}

public extension InvarianceRule {
    /// Adheres when the value constructs `Target`, reusing that type's own
    /// guarantee instead of restating it as rules.
    static func constructs<Target: Invariant>(
        _ target: Target.Type
    ) -> Self where Target.Raw == Value, Target.Error: Sendable {
        Self { value in
            do throws(Target.Error) {
                _ = try Target(
                    value
                )
                return []
            } catch {
                return [
                    InvarianceViolation(
                        InvarianceConstructionFailed<Target>(
                            error: error
                        )
                    )
                ]
            }
        }
    }

    /// Applies `rules` only to a present value; `nil` adheres.
    /// Combine with `.required()` when absence is itself a violation.
    static func when_present<Wrapped>(
        _ rules: [InvarianceRule<Wrapped>]
    ) -> Self where Value == Wrapped? {
        Self { value in
            guard let value else {
                return []
            }

            return rules.flatMap { rule in
                rule.violations(
                    for: value
                )
            }
        }
    }
}
