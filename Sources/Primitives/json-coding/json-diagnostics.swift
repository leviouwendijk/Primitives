public struct JSONDiagnostics:
    Sendable,
    Hashable
{
    public let issues: [JSONIssue]

    public init(
        _ issues: [JSONIssue] = []
    ) {
        self.issues = issues
    }

    public var isEmpty: Bool {
        issues.isEmpty
    }
}
