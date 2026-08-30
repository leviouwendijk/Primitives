import Foundation

public struct JSONCodingPath:
    Sendable,
    Hashable,
    CustomStringConvertible
{
    public enum Component:
        Sendable,
        Hashable
    {
        case key(String)
        case index(Int)
    }

    public let components: [Component]

    public init(
        _ components: [Component] = []
    ) {
        self.components = components
    }

    public var jsonPath: String {
        components.reduce(into: "$") {
            path,
            component in

            switch component {
            case .key(let key):
                if Self.isSimpleKey(key) {
                    path += ".\(key)"
                } else {
                    path += "[\"\(Self.escaped(key))\"]"
                }

            case .index(let index):
                path += "[\(index)]"
            }
        }
    }

    public var description: String {
        jsonPath
    }
}

extension JSONCodingPath {
    init(
        codingPath: [any CodingKey]
    ) {
        self.init(
            codingPath.map { key in
                if let index = key.intValue {
                    return .index(index)
                }

                return .key(
                    key.stringValue
                )
            }
        )
    }
}

private extension JSONCodingPath {
    static func isSimpleKey(
        _ value: String
    ) -> Bool {
        guard
            let first = value.first,
            first == "_" || first.isLetter
        else {
            return false
        }

        return value.dropFirst().allSatisfy {
            $0 == "_" || $0.isLetter || $0.isNumber
        }
    }

    static func escaped(
        _ value: String
    ) -> String {
        value
            .replacingOccurrences(
                of: "\\",
                with: "\\\\"
            )
            .replacingOccurrences(
                of: "\"",
                with: "\\\""
            )
    }
}
