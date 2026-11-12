/// A value whose initializer is the only way to establish its invariant.
///
/// A `Self` can only be produced through `init(_:)`, so the existence of a
/// value is itself the proof that its invariant holds. That single throwing
/// initializer is the boundary where a looser `Raw` is parsed into the
/// guaranteed type; every later use relies on the guarantee instead of
/// rechecking it.
///
/// ## Parse, don't validate
///
/// Validation returns a verdict: a `Bool`, a thrown error, an optional kept
/// apart from the value. Callers can forget it, place it too late, apply it to
/// the wrong value, or keep using the loose value afterwards. Parsing returns
/// a type. There is no separate validation path to keep correct and no way to
/// hold an unchecked value under a checked name: construction either succeeds,
/// and the guarantee is carried by the value, or fails and no value is
/// produced.
///
/// ## Guaranteed invariance
///
/// The guarantee is encoded in the type rather than in a comment, a naming
/// convention, or a review habit. A signature that accepts the invariant type
/// needs no further checks; one that accepts `Raw` may assume nothing.
/// Construct once at the edge where loose data enters, then pass the invariant
/// type inward, rather than threading loose values through the program and
/// repeating validation at each step.
///
/// ## Loose in acceptance, strict in return
///
/// `Raw` is deliberately permissive -- typically a primitive such as `String`
/// or `Int`, or an optional of one -- so that decoding and interop accept what
/// the outside world actually provides, and callers are not forced to shape a
/// value before they can hand it over. Strictness is concentrated in the
/// returned `Self`. `Raw` should stay the loosest form that still carries the
/// data; narrowing it (non-optional, pre-trimmed, pre-split) pushes work back
/// onto callers and weakens the boundary.
///
/// This split also keeps failures well located: decoding incompatibilities
/// belong to `Raw`'s own conformance, while `Error` is reserved for the
/// transition from an already established `Raw` value into the invariant
/// guarantee, so the two are not confused.
///
/// `CodableInvariant` specializes this: it decodes `Raw` and constructs through
/// `init(_:)`, so a decoded value is never weaker than a constructed one.
public protocol Invariant<Raw> {
    /// The loose representation accepted at the boundary.
    associatedtype Raw

    /// The typed failure of parsing `Raw` into `Self`.
    ///
    /// Defaults to `Never`, meaning construction cannot fail for this type.
    associatedtype Error: Swift.Error = Never

    /// Parses `raw` into a guaranteed value, or throws `Error` without
    /// producing one.
    init(_ raw: Raw) throws(Error)
}