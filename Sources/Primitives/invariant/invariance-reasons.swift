/// Incorrect rule parameters are distinct from a value violating a valid rule.
public enum InvarianceRuleConfigurationError<Bound: Sendable>: Swift.Error, Sendable {
    case inverted_bounds(minimum: Bound, maximum: Bound)
    case incomparable_bounds(minimum: Bound, maximum: Bound)
}

public struct InvarianceLengthTooShort: InvarianceReason {
    public let minimum: UInt
    public let actual: UInt

    public init(minimum: UInt, actual: UInt) {
        self.minimum = minimum
        self.actual = actual
    }

    public var code: InvarianceCode { .length_below_minimum }
    public var message: String { "Length \(actual) is below minimum \(minimum)." }
}

public struct InvarianceLengthTooLong: InvarianceReason {
    public let maximum: UInt
    public let actual: UInt

    public init(maximum: UInt, actual: UInt) {
        self.maximum = maximum
        self.actual = actual
    }

    public var code: InvarianceCode { .length_above_maximum }
    public var message: String { "Length \(actual) exceeds maximum \(maximum)." }
}

public struct InvarianceBelowMinimum<Bound: Sendable>: InvarianceReason {
    public let minimum: Bound
    public let actual: Bound

    public init(minimum: Bound, actual: Bound) {
        self.minimum = minimum
        self.actual = actual
    }

    public var code: InvarianceCode { .below_minimum }
    public var message: String { "Value is below the specified minimum." }
}

public struct InvarianceAboveMaximum<Bound: Sendable>: InvarianceReason {
    public let maximum: Bound
    public let actual: Bound

    public init(maximum: Bound, actual: Bound) {
        self.maximum = maximum
        self.actual = actual
    }

    public var code: InvarianceCode { .above_maximum }
    public var message: String { "Value exceeds the specified maximum." }
}

public struct InvarianceEmptyCollection: InvarianceReason {
    public init() {}

    public var code: InvarianceCode { .empty_collection }
    public var message: String { "The collection must not be empty." }
}

public struct InvarianceDuplicateElement<Key: Hashable & Sendable>: InvarianceReason {
    public let key: Key
    public let first_index: Int
    public let duplicate_index: Int

    public init(key: Key, first_index: Int, duplicate_index: Int) {
        self.key = key
        self.first_index = first_index
        self.duplicate_index = duplicate_index
    }

    public var code: InvarianceCode { .duplicate_element }
    public var message: String {
        "Duplicate element at index \(duplicate_index); first at \(first_index)."
    }
}

public struct InvarianceMissingValue: InvarianceReason {
    public init() {}

    public var code: InvarianceCode { .missing_value }
    public var message: String { "A value is required." }
}

/// A comparison could not establish an order, for example with floating-point NaN.
public enum InvarianceBoundSide: Sendable, Hashable {
    case minimum
    case maximum
}

public struct InvarianceUnorderedComparison<Bound: Sendable>: InvarianceReason {
    public let actual: Bound
    public let bound: Bound
    public let side: InvarianceBoundSide

    public init(
        actual: Bound,
        bound: Bound,
        side: InvarianceBoundSide
    ) {
        self.actual = actual
        self.bound = bound
        self.side = side
    }

    public var code: InvarianceCode { .unordered_comparison }
    public var message: String { "The value and the specified bound cannot be ordered." }
}

public struct InvarianceNonfiniteNumber<Number: Sendable>: InvarianceReason {
    public let actual: Number

    public init(actual: Number) {
        self.actual = actual
    }

    public var code: InvarianceCode { .nonfinite_number }
    public var message: String { "The number must be finite." }
}

public struct InvarianceBlankText: InvarianceReason {
    public init() {}

    public var code: InvarianceCode { .blank_text }
    public var message: String { "Text must contain a non-whitespace character." }
}

public struct InvarianceCollectionTooSmall: InvarianceReason {
    public let minimum: UInt
    public let actual: UInt

    public init(minimum: UInt, actual: UInt) {
        self.minimum = minimum
        self.actual = actual
    }

    public var code: InvarianceCode { .collection_below_minimum }
    public var message: String { "Collection count \(actual) is below minimum \(minimum)." }
}

public struct InvarianceCollectionTooLarge: InvarianceReason {
    public let maximum: UInt
    public let actual: UInt

    public init(maximum: UInt, actual: UInt) {
        self.maximum = maximum
        self.actual = actual
    }

    public var code: InvarianceCode { .collection_above_maximum }
    public var message: String { "Collection count \(actual) exceeds maximum \(maximum)." }
}
