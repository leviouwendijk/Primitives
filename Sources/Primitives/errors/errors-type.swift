import Foundation

public typealias MultiError = Errors

public struct Errors: Error, Sendable {
    public let errors: [Error]

    public init(_ errors: [Error]) {
        self.errors = errors
    }
}
