import Primitives

// MARK: - Example 1: Nonthrowing Invariant

public struct AlwaysValid: Invariant {
    public let number: Int

    public init(_ raw: Int) {
        self.number = raw
    }
}

// MARK: - Example 2: Shared Typed Error

public enum SharedInvariantError: Swift.Error {
    case num_required
}

public struct TestType: Invariant {
    public typealias Error = SharedInvariantError

    public let num: Int

    public struct Raw {
        public let number: Int?

        public init(
            number: Int? = nil
        ) {
            self.number = number
        }
    }

    public init(_ raw: Raw) throws(Error) {
        guard let num = raw.number else {
            throw .num_required
        }

        self.num = num
    }
}

// MARK: - Example 3: Nested Typed Error

public struct PositiveNumber: Invariant {
    public enum Error: Swift.Error {
        case negative
    }

    public let number: Int

    public init(_ raw: Int) throws(Error) {
        guard raw >= 0 else {
            throw .negative
        }

        self.number = raw
    }
}

// MARK: - Example 4: Unrestricted Errors

public enum MissingNumberError: Swift.Error {
    case missing
}

public enum NegativeNumberError: Swift.Error {
    case negative
}

public struct UnrestrictedNumber: Invariant {
    public let number: Int

    public init(_ raw: Int?) throws {
        guard let raw else {
            throw MissingNumberError.missing
        }

        guard raw >= 0 else {
            throw NegativeNumberError.negative
        }

        self.number = raw
    }
}
