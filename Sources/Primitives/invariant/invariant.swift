public protocol Invariant<Raw> {
    associatedtype Raw
    associatedtype Error: Swift.Error = Never

    init(_ raw: Raw) throws(Error)
}
