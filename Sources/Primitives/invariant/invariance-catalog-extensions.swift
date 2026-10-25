import Foundation

// MARK: - Numeric sign guarantees

public struct InvarianceSignViolation<Number: Sendable>: InvarianceReason {
    public enum Requirement: Sendable {
        case positive
        case nonnegative
        case nonzero
    }

    public let actual: Number
    public let requirement: Requirement

    public init(actual: Number, requirement: Requirement) {
        self.actual = actual
        self.requirement = requirement
    }

    public var code: InvarianceCode { .custom("number.sign") }
    public var message: String { "Value does not satisfy the required numeric sign." }
}

public struct InvarianceNumberRules<Number: Comparable & AdditiveArithmetic & Sendable>: Sendable {
    public init() {}

    public var positive: InvarianceRule<Number> {
        InvarianceRule { value in
            value > .zero ? [] : [
                InvarianceViolation(
                    InvarianceSignViolation(
                        actual: value,
                        requirement: .positive
                    )
                )
            ]
        }
    }

    public var nonnegative: InvarianceRule<Number> {
        InvarianceRule { value in
            value >= .zero ? [] : [
                InvarianceViolation(
                    InvarianceSignViolation(
                        actual: value,
                        requirement: .nonnegative
                    )
                )
            ]
        }
    }

    public var nonzero: InvarianceRule<Number> {
        InvarianceRule { value in
            (value < .zero || value > .zero) ? [] : [
                InvarianceViolation(
                    InvarianceSignViolation(
                        actual: value,
                        requirement: .nonzero
                    )
                )
            ]
        }
    }
}

public extension InvarianceNumberRules where Number: BinaryFloatingPoint {
    var finite: InvarianceRule<Number> {
        InvarianceRule { value in
            value.isFinite ? [] : [
                InvarianceViolation(
                    InvarianceNonfiniteNumber(actual: value)
                )
            ]
        }
    }
}

public extension InvarianceNumberRules where Number == Decimal {
    var nonzero: InvarianceRule<Decimal> {
        InvarianceRule { value in
            (!value.isNaN && value != .zero) ? [] : [
                InvarianceViolation(
                    InvarianceSignViolation(actual: value, requirement: .nonzero)
                )
            ]
        }
    }

    var finite: InvarianceRule<Decimal> {
        InvarianceRule { value in
            value.isNaN ? [
                InvarianceViolation(
                    InvarianceNonfiniteNumber(actual: value)
                )
            ] : []
        }
    }
}

public extension InvarianceRule where Value: Comparable & AdditiveArithmetic & Sendable {
    static var number: InvarianceNumberRules<Value> { .init() }
}

// MARK: - Decimal precision and NaN-aware ranges

public struct InvarianceDecimalScaleExceeded: InvarianceReason {
    public let maximum: UInt
    public let actual: UInt
    public let value: Decimal

    public init(maximum: UInt, actual: UInt, value: Decimal) {
        self.maximum = maximum
        self.actual = actual
        self.value = value
    }

    public var code: InvarianceCode { .custom("decimal.scale_exceeded") }
    public var message: String { "Decimal requires \(actual) places; maximum is \(maximum)." }
}

public struct InvarianceDecimalRules: Sendable {
    public init() {}

    public var finite: InvarianceRule<Decimal> {
        InvarianceNumberRules<Decimal>().finite
    }

    public var scale: ScaleRules { .init() }

    public struct ScaleRules: Sendable {
        public init() {}

        public func max(_ maximum: UInt) -> InvarianceRule<Decimal> {
            InvarianceRule { value in
                guard !value.isNaN else {
                    return [
                        InvarianceViolation(
                            InvarianceNonfiniteNumber(actual: value)
                        )
                    ]
                }
                // Decimal's finite exponent is bounded, so any larger scale suffices.
                guard maximum < 128 else { return [] }
                var input = value
                var rounded = Decimal()
                NSDecimalRound(&rounded, &input, Int(maximum), .plain)
                guard rounded != value else { return [] }
                var required: UInt = 0
                for scale in 0...127 {
                    var attempt = Decimal()
                    var candidate = value
                    NSDecimalRound(&attempt, &candidate, scale, .plain)
                    if attempt == value {
                        required = UInt(scale)
                        break
                    }
                }
                return [
                    InvarianceViolation(
                        InvarianceDecimalScaleExceeded(
                            maximum: maximum,
                            actual: required,
                            value: value
                        )
                    )
                ]
            }
        }
    }
}

public extension InvarianceRule where Value == Decimal {
    static var decimal: InvarianceDecimalRules { .init() }
}

public extension InvarianceRangeRules where Value == Decimal {
    func min(_ minimum: Decimal) -> InvarianceRule<Decimal> {
        InvarianceRule { value in
            if value.isNaN || minimum.isNaN {
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
            return value < minimum ? [
                InvarianceViolation(
                    InvarianceBelowMinimum(
                        minimum: minimum,
                        actual: value
                    )
                )
            ] : []
        }
    }

    func max(_ maximum: Decimal) -> InvarianceRule<Decimal> {
        InvarianceRule { value in
            if value.isNaN || maximum.isNaN {
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
            return value > maximum ? [
                InvarianceViolation(
                    InvarianceAboveMaximum(
                        maximum: maximum,
                        actual: value
                    )
                )
            ] : []
        }
    }

    func min_max(
        _ minimum: Decimal,
        _ maximum: Decimal
    ) throws(InvarianceRuleConfigurationError<Decimal>) -> InvarianceRule<Decimal> {
        guard !minimum.isNaN && !maximum.isNaN else {
            throw .incomparable_bounds(
                minimum: minimum,
                maximum: maximum
            )
        }
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

// MARK: - Equality, membership, and field relationships

public struct InvarianceUnexpectedValue<Value: Sendable>: InvarianceReason {
    public let expected: Value
    public let actual: Value

    public init(expected: Value, actual: Value) {
        self.expected = expected
        self.actual = actual
    }

    public var code: InvarianceCode { .custom("value.not_equal") }
}

public struct InvarianceValueNotAllowed<Value: Hashable & Sendable>: InvarianceReason {
    public let actual: Value
    public let allowed: Set<Value>

    public init(actual: Value, allowed: Set<Value>) {
        self.actual = actual
        self.allowed = allowed
    }

    public var code: InvarianceCode { .custom("value.not_allowed") }
}

public struct InvarianceValueRules<Value: Equatable & Sendable>: Sendable {
    public init() {}

    public func equal(to expected: Value) -> InvarianceRule<Value> {
        InvarianceRule { value in
            value == expected ? [] : [
                InvarianceViolation(
                    InvarianceUnexpectedValue(
                        expected: expected,
                        actual: value
                    )
                )
            ]
        }
    }
}

public extension InvarianceValueRules where Value: Hashable {
    func one_of(_ allowed: Set<Value>) -> InvarianceRule<Value> {
        InvarianceRule { value in
            allowed.contains(value) ? [] : [
                InvarianceViolation(
                    InvarianceValueNotAllowed(
                        actual: value,
                        allowed: allowed
                    )
                )
            ]
        }
    }
}

public extension InvarianceRule where Value: Equatable & Sendable {
    static var value: InvarianceValueRules<Value> { .init() }
}

public struct InvarianceFieldsUnequal<Field: Equatable & Sendable>: InvarianceReason {
    public let left_name: String
    public let right_name: String
    public let left: Field
    public let right: Field

    public init(left_name: String, right_name: String, left: Field, right: Field) {
        self.left_name = left_name
        self.right_name = right_name
        self.left = left
        self.right = right
    }

    public var code: InvarianceCode { .custom("fields.not_equal") }
}

public struct InvarianceFieldsRules<Root>: Sendable {
    public init() {}

    public func equal<Field: Equatable & Sendable>(
        _ left: KeyPath<Root, Field> & Sendable,
        _ right: KeyPath<Root, Field> & Sendable,
        named left_name: String,
        and right_name: String
    ) -> InvarianceRule<Root> {
        InvarianceRule { root in
            let a = root[keyPath: left]
            let b = root[keyPath: right]
            return a == b ? [] : [
                InvarianceViolation(
                    InvarianceFieldsUnequal(
                        left_name: left_name,
                        right_name: right_name,
                        left: a,
                        right: b
                    )
                )
            ]
        }
    }
}

public extension InvarianceRule {
    static var fields: InvarianceFieldsRules<Value> { .init() }
}

// MARK: - Collection element rules

public struct InvarianceMissingElement<Element: Hashable & Sendable>: InvarianceReason {
    public let required: Element
    public init(required: Element) { self.required = required }
    public var code: InvarianceCode { .custom("elements.missing") }
}

public struct InvarianceDisallowedElement<Element: Hashable & Sendable>: InvarianceReason {
    public let actual: Element
    public let allowed: Set<Element>
    public init(actual: Element, allowed: Set<Element>) {
        self.actual = actual
        self.allowed = allowed
    }
    public var code: InvarianceCode { .custom("elements.disallowed") }
}

public extension InvarianceElementsRules {
    func each(_ rules: [InvarianceRule<Value.Element>]) -> InvarianceRule<Value> {
        InvarianceRule { collection in
            collection.enumerated().flatMap { index, element in
                rules.flatMap { rule in
                    rule.violations(for: element).map {
                        $0.prepending(.index(index))
                    }
                }
            }
        }
    }
}

public extension InvarianceElementsRules where Value.Element: Hashable {
    var unique: InvarianceRule<Value> { unique(by: { $0 }) }

    func contains(_ required: Value.Element) -> InvarianceRule<Value> {
        InvarianceRule { collection in
            collection.contains(required) ? [] : [
                InvarianceViolation(
                    InvarianceMissingElement(required: required)
                )
            ]
        }
    }

    func all(in allowed: Set<Value.Element>) -> InvarianceRule<Value> {
        InvarianceRule { collection in
            collection.enumerated().compactMap { index, element in
                allowed.contains(element) ? nil : InvarianceViolation(
                    InvarianceDisallowedElement(
                        actual: element,
                        allowed: allowed
                    ),
                    path: [.index(index)]
                )
            }
        }
    }
}

// MARK: - Decimal collection totals

public struct InvarianceSumMismatch: InvarianceReason {
    public let expected: Decimal
    public let actual: Decimal
    public init(expected: Decimal, actual: Decimal) {
        self.expected = expected
        self.actual = actual
    }
    public var code: InvarianceCode { .custom("sum.mismatch") }
}

public struct InvarianceSumRules<Value: Collection & Sendable>: Sendable
where Value.Element == Decimal {
    public init() {}

    public func equal(to expected: Decimal) -> InvarianceRule<Value> {
        InvarianceRule { collection in
            var total: Decimal = 0
            for item in collection { total += item }
            if total.isNaN {
                return [InvarianceViolation(InvarianceNonfiniteNumber(actual: total))]
            }
            return total == expected ? [] : [
                InvarianceViolation(
                    InvarianceSumMismatch(
                        expected: expected,
                        actual: total
                    )
                )
            ]
        }
    }
}

public extension InvarianceRule where Value: Collection & Sendable, Value.Element == Decimal {
    static var sum: InvarianceSumRules<Value> { .init() }
}

// MARK: - Patterns and dates

public struct InvariancePatternMismatch: InvarianceReason {
    public let pattern: String
    public let actual: String
    public init(pattern: String, actual: String) {
        self.pattern = pattern
        self.actual = actual
    }
    public var code: InvarianceCode { .custom("text.pattern_mismatch") }
}

public extension InvarianceTextRules {
    func matches(
        _ pattern: String
    ) throws -> InvarianceRule<String> {
        _ = try NSRegularExpression(pattern: pattern)
        return InvarianceRule { value in
            // The pattern was checked during construction; recompile to avoid
            // sharing potentially non-Sendable Foundation regex state.
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return [
                    InvarianceViolation(
                        InvariancePatternMismatch(pattern: pattern, actual: value)
                    )
                ]
            }
            let range = NSRange(value.startIndex..<value.endIndex, in: value)
            return regex.firstMatch(in: value, range: range) == nil ? [
                InvarianceViolation(
                    InvariancePatternMismatch(pattern: pattern, actual: value)
                )
            ] : []
        }
    }
}

public struct InvarianceDateRules: Sendable {
    public init() {}
    public var range: InvarianceRangeRules<Date> { .init() }
}

public extension InvarianceRule where Value == Date {
    static var date: InvarianceDateRules { .init() }
}
