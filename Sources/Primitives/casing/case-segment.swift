public extension Case {
    /// Lossless identifier segmentation. Ranges are zero-based, half-open UTF-8 offsets.
    /// Boundaries may be Unicode-scalar boundaries within a grapheme; consumers that
    /// render Characters must intersect these with their Character boundaries.
    struct Segment: Sendable, Codable, Hashable {
        public enum Kind: String, Sendable, Codable, Hashable {
            case component
            case separator
        }

        public let kind: Kind
        public let text: String
        public let utf8: Range<Int>
    }

    static func segments(
        _ source: String,
        separators: Separators = .common
    ) -> [Segment] {
        tokenize_identifier_segments(source, separators: separators)
    }
}
