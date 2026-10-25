/// A separately constructible rule with diagnostic evaluation as its primitive.
public struct InvarianceRule<Value>: Sendable {
    private let evaluate: @Sendable (Value) -> [InvarianceViolation]

    public init(
        _ evaluate: @escaping @Sendable (Value) -> [InvarianceViolation]
    ) {
        self.evaluate = evaluate
    }

    public func violations(
        for value: Value
    ) -> [InvarianceViolation] {
        evaluate(value)
    }

    /// A predicate cannot silently discard why it failed.
    public static func predicate(
        where adheres: @escaping @Sendable (Value) -> Bool,
        on_failure: @escaping @Sendable (Value) -> InvarianceViolation
    ) -> Self {
        Self { value in
            adheres(value) ? [] : [on_failure(value)]
        }
    }

    /// Rebase a rule's relative diagnostics onto a field or positional index.
    public func at(
        _ component: InvariancePathComponent
    ) -> Self {
        Self { value in
            violations(for: value).map {
                $0.prepending(component)
            }
        }
    }
}

public extension InvarianceRule {
    /// Apply a child rule specification through a type-checked key path.
    /// The explicit name supplies a stable diagnostic field path without reflection.
    static func field<Field: Sendable>(
        _ key_path: KeyPath<Value, Field> & Sendable,
        named name: String,
        rules: [InvarianceRule<Field>]
    ) -> Self {
        Self { value in
            let child = value[keyPath: key_path]
            return rules.flatMap { rule in
                rule.violations(for: child).map {
                    $0.prepending(.field(name))
                }
            }
        }
    }
}
