/// Opt-in reconstitution API for invariant value types with value-semantic raw data.
/// `raw` must be an independent representation: no shared mutable references.
/// Use immutable stored properties and preserve invariants in every other initializer.
public protocol MutableInvariant: Invariant {
    var raw: Raw { get }
}

public extension MutableInvariant {
    /// Produces a new guaranteed instance only after the candidate raw value passes construction.
    func updating(
        _ change: (inout Raw) -> Void
    ) throws(Error) -> Self {
        var candidate = raw
        change(&candidate)
        return try Self(candidate)
    }

    /// Atomic value replacement: on construction failure the existing value is unchanged.
    mutating func update(
        _ change: (inout Raw) -> Void
    ) throws(Error) {
        self = try updating(change)
    }
}
