import Foundation

// Opt-in Invariant conformances for Primitives value types whose
// construction already establishes a guarantee.
//
// CodableInvariant is adopted only where the raw representation's wire
// format is identical to the previous hand-written coding (YearQuarter,
// PartialDate). TreeAddress, TreeTraversalLimits and Graph keep their own
// coding because their decoders surface construction errors unwrapped;
// DayOfMonth and NonBlankString keep theirs because their wire formats are
// keyed.

// MARK: - DayOfMonth

extension DayOfMonth: MutableInvariant {
    public typealias Raw = Int
    public typealias Error = DayOfMonthError

    public var raw: Int {
        value
    }
}

// MARK: - NonBlankString

extension NonBlankString: MutableInvariant {
    public typealias Raw = String
    public typealias Error = NonBlankStringError

    /// The normalized (trimmed) value, not the original input.
    public var raw: String {
        rawValue
    }
}

// MARK: - StringIdentifierValue

extension StringIdentifierValue: MutableInvariant {
    public typealias Raw = String
    public typealias Error = StringIdentifierValidationError

    public var raw: String {
        rawValue
    }
}

// MARK: - YearQuarter

extension YearQuarter: CodableInvariant {
    public typealias Error = YearQuarterError

    public struct Raw: Sendable, Hashable, Codable {
        public var year: Int
        public var quarter: Int

        public init(
            year: Int,
            quarter: Int
        ) {
            self.year = year
            self.quarter = quarter
        }
    }

    public init(
        _ raw: Raw
    ) throws(YearQuarterError) {
        try self.init(
            year: raw.year,
            quarter: raw.quarter
        )
    }

    public var raw: Raw {
        .init(
            year: year,
            quarter: quarter
        )
    }
}

// MARK: - PartialDate

extension PartialDate: CodableInvariant {
    public typealias Error = DateSpecificationError

    public struct Raw: Sendable, Hashable, Codable {
        public var year: Int?
        public var month: Int?
        public var day: Int?

        public init(
            year: Int? = nil,
            month: Int? = nil,
            day: Int? = nil
        ) {
            self.year = year
            self.month = month
            self.day = day
        }
    }

    public init(
        _ raw: Raw
    ) throws(DateSpecificationError) {
        try self.init(
            year: raw.year,
            month: raw.month,
            day: raw.day
        )
    }

    public var raw: Raw {
        .init(
            year: year,
            month: month,
            day: day
        )
    }
}

// MARK: - TreeAddress

extension TreeAddress: MutableInvariant {
    public struct Raw: Sendable, Hashable, Codable {
        public var root: Int
        public var descendants: [Int]

        public init(
            root: Int,
            descendants: [Int] = []
        ) {
            self.root = root
            self.descendants = descendants
        }
    }

    public init(
        _ raw: Raw
    ) throws(TreeAddress.Error) {
        try self.init(
            root: raw.root,
            descendants: raw.descendants
        )
    }

    public var raw: Raw {
        .init(
            root: root,
            descendants: descendants
        )
    }
}

// MARK: - TreeTraversalLimits

extension TreeTraversalLimits: MutableInvariant {
    public typealias Raw = Int?
    public typealias Error = TreeTraversalLimitError

    public init(
        _ raw: Int?
    ) throws(TreeTraversalLimitError) {
        try self.init(
            maximum_depth: raw
        )
    }

    public var raw: Int? {
        maximum_depth
    }
}

// MARK: - Graph

extension Graph: MutableInvariant {
    public typealias Error = GraphValidationError<NodeID, EdgeID>

    public struct Raw {
        public var nodes: [Node]
        public var edges: [Edge]

        public init(
            nodes: [Node] = [],
            edges: [Edge] = []
        ) {
            self.nodes = nodes
            self.edges = edges
        }
    }

    public init(
        _ raw: Raw
    ) throws(GraphValidationError<NodeID, EdgeID>) {
        try self.init(
            nodes: raw.nodes,
            edges: raw.edges
        )
    }

    public var raw: Raw {
        .init(
            nodes: nodes,
            edges: edges
        )
    }
}

extension Graph.Raw: Sendable where NodeID: Sendable, NodeValue: Sendable, EdgeID: Sendable, EdgeValue: Sendable {}
extension Graph.Raw: Equatable where NodeValue: Equatable, EdgeValue: Equatable {}
