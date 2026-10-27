/// Evidence that a raw value cannot construct an invariant-bearing type.
public struct InvarianceConstructionFailed<Target: Invariant>: InvarianceReason
where Target.Error: Sendable {
    public let error: Target.Error

    public init(
        error: Target.Error
    ) {
        self.error = error
    }

    public var code: InvarianceCode { .custom("construction.failed") }
    public var message: String { "Value cannot construct \(Target.self): \(error)" }
}
