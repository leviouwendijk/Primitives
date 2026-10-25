public enum InvarianceCode: Hashable, Sendable {
    case length_below_minimum
    case length_above_maximum
    case below_minimum
    case above_maximum
    case empty_collection
    case duplicate_element
    case missing_value
    case unordered_comparison
    case nonfinite_number
    case blank_text
    case collection_below_minimum
    case collection_above_maximum
    case custom(String)
}

/// A typed explanation of an unmet requirement.
public protocol InvarianceReason: Swift.Error, Sendable {
    var code: InvarianceCode { get }
    var message: String { get }
}

public extension InvarianceReason {
    var message: String {
        String(describing: code)
    }
}

/// A semantic path, independent of source ranges and any serialization format.
public enum InvariancePathComponent: Hashable, Sendable {
    case field(String)
    case index(Int)
}

public struct InvarianceViolation: Swift.Error, Sendable {
    public let reason: any InvarianceReason
    public let path: [InvariancePathComponent]

    public init(
        _ reason: any InvarianceReason,
        path: [InvariancePathComponent] = []
    ) {
        self.reason = reason
        self.path = path
    }

    public var code: InvarianceCode {
        reason.code
    }

    public var message: String {
        reason.message
    }

    public func prepending(
        _ component: InvariancePathComponent
    ) -> Self {
        Self(reason, path: [component] + path)
    }
}

/// An impossible-to-empty collection of violations.
public struct InvarianceFailure: Swift.Error, Sendable {
    public let first: InvarianceViolation
    public let remaining: [InvarianceViolation]

    public init(
        _ first: InvarianceViolation,
        remaining: [InvarianceViolation] = []
    ) {
        self.first = first
        self.remaining = remaining
    }

    public var violations: [InvarianceViolation] {
        [first] + remaining
    }
}
