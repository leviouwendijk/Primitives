/// String length is measured in Swift extended grapheme clusters (`String.count`).
public struct InvarianceLengthRules: Sendable {
    public init() {}

    public func min(_ minimum: UInt) -> InvarianceRule<String> {
        InvarianceRule { value in
            let actual = UInt(value.count)
            guard actual < minimum else { return [] }
            return [
                InvarianceViolation(
                    InvarianceLengthTooShort(
                        minimum: minimum,
                        actual: actual
                    )
                )
            ]
        }
    }

    public func max(_ maximum: UInt) -> InvarianceRule<String> {
        InvarianceRule { value in
            let actual = UInt(value.count)
            guard actual > maximum else { return [] }
            return [
                InvarianceViolation(
                    InvarianceLengthTooLong(
                        maximum: maximum,
                        actual: actual
                    )
                )
            ]
        }
    }

    public func min_max(
        _ minimum: UInt,
        _ maximum: UInt
    ) throws(InvarianceRuleConfigurationError<UInt>) -> InvarianceRule<String> {
        guard minimum <= maximum else {
            throw .inverted_bounds(
                minimum: minimum,
                maximum: maximum
            )
        }
        let lower = min(minimum)
        let upper = max(maximum)
        return InvarianceRule { value in
            lower.violations(for: value) + upper.violations(for: value)
        }
    }
}

public extension InvarianceRule where Value == String {
    static var length: InvarianceLengthRules { .init() }
}

/// Whitespace is evaluated with Swift Character.isWhitespace. No normalization is applied.
public struct InvarianceTextRules: Sendable {
    public init() {}

    public var nonblank: InvarianceRule<String> {
        InvarianceRule { value in
            guard value.isEmpty || value.allSatisfy({ $0.isWhitespace }) else {
                return []
            }
            return [InvarianceViolation(InvarianceBlankText())]
        }
    }
}

public extension InvarianceRule where Value == String {
    static var text: InvarianceTextRules { .init() }
}

public struct InvarianceRangeRules<Value: Comparable & Sendable>: Sendable {
    public init() {}

    public func min(_ minimum: Value) -> InvarianceRule<Value> {
        InvarianceRule { value in
            if value < minimum {
                return [
                    InvarianceViolation(
                        InvarianceBelowMinimum(
                            minimum: minimum,
                            actual: value
                        )
                    )
                ]
            }
            if value >= minimum { return [] }
            return [
                InvarianceViolation(
                    InvarianceUnorderedComparison(
                        actual: value,
                        bound: minimum,
                        side: .minimum
                    )
                )
            ]
        }
    }

    public func max(_ maximum: Value) -> InvarianceRule<Value> {
        InvarianceRule { value in
            if value > maximum {
                return [
                    InvarianceViolation(
                        InvarianceAboveMaximum(
                            maximum: maximum,
                            actual: value
                        )
                    )
                ]
            }
            if value <= maximum { return [] }
            return [
                InvarianceViolation(
                    InvarianceUnorderedComparison(
                        actual: value,
                        bound: maximum,
                        side: .maximum
                    )
                )
            ]
        }
    }

    public func min_max(
        _ minimum: Value,
        _ maximum: Value
    ) throws(InvarianceRuleConfigurationError<Value>) -> InvarianceRule<Value> {
        if minimum > maximum {
            throw .inverted_bounds(
                minimum: minimum,
                maximum: maximum
            )
        }
        guard minimum <= maximum else {
            throw .incomparable_bounds(
                minimum: minimum,
                maximum: maximum
            )
        }
        let lower = min(minimum)
        let upper = max(maximum)
        return InvarianceRule { value in
            lower.violations(for: value) + upper.violations(for: value)
        }
    }
}

public extension InvarianceRule where Value: Comparable & Sendable {
    static var range: InvarianceRangeRules<Value> { .init() }
}

public struct InvarianceElementsCountRules<Value: Collection & Sendable>: Sendable
where Value.Element: Sendable {
    public init() {}

    public func min(_ minimum: UInt) -> InvarianceRule<Value> {
        InvarianceRule { value in
            let actual = UInt(value.count)
            guard actual < minimum else { return [] }
            return [
                InvarianceViolation(
                    InvarianceCollectionTooSmall(
                        minimum: minimum,
                        actual: actual
                    )
                )
            ]
        }
    }

    public func max(_ maximum: UInt) -> InvarianceRule<Value> {
        InvarianceRule { value in
            let actual = UInt(value.count)
            guard actual > maximum else { return [] }
            return [
                InvarianceViolation(
                    InvarianceCollectionTooLarge(
                        maximum: maximum,
                        actual: actual
                    )
                )
            ]
        }
    }

    public func min_max(
        _ minimum: UInt,
        _ maximum: UInt
    ) throws(InvarianceRuleConfigurationError<UInt>) -> InvarianceRule<Value> {
        guard minimum <= maximum else {
            throw .inverted_bounds(
                minimum: minimum,
                maximum: maximum
            )
        }
        let lower = min(minimum)
        let upper = max(maximum)
        return InvarianceRule { value in
            lower.violations(for: value) + upper.violations(for: value)
        }
    }
}

public struct InvarianceElementsRules<Value: Collection & Sendable>: Sendable
where Value.Element: Sendable {
    public init() {}

    public var nonempty: InvarianceRule<Value> {
        InvarianceRule { value in
            value.isEmpty
                ? [InvarianceViolation(InvarianceEmptyCollection())]
                : []
        }
    }

    public var count: InvarianceElementsCountRules<Value> { .init() }

    /// Index diagnostics are zero-based offsets, irrespective of Collection.Index.
    public func unique<Key: Hashable & Sendable>(
        by key: @escaping @Sendable (Value.Element) -> Key
    ) -> InvarianceRule<Value> {
        InvarianceRule { value in
            var first_seen: [Key: Int] = [:]
            var violations: [InvarianceViolation] = []
            for (index, element) in value.enumerated() {
                let selected = key(element)
                if let first = first_seen[selected] {
                    violations.append(
                        InvarianceViolation(
                            InvarianceDuplicateElement(
                                key: selected,
                                first_index: first,
                                duplicate_index: index
                            ),
                            path: [.index(index)]
                        )
                    )
                } else {
                    first_seen[selected] = index
                }
            }
            return violations
        }
    }
}

public extension InvarianceRule where Value: Collection & Sendable, Value.Element: Sendable {
    static var elements: InvarianceElementsRules<Value> { .init() }
}

public extension InvarianceRule {
    static func required<Wrapped>() -> Self where Value == Wrapped? {
        Self { value in
            value == nil ? [InvarianceViolation(InvarianceMissingValue())] : []
        }
    }
}
