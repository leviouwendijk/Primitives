internal func tokenize_identifier(
    _ value: String,
    separators: Separators
) -> [String] {
    guard !value.isEmpty else {
        return []
    }

    let scalars = Array(
        value.unicodeScalars
    )

    var tokens: [String] = []
    var current: [UnicodeScalar] = []

    @inline(__always)
    func kind(
        at index: Int
    ) -> ScalarKind? {
        guard scalars.indices.contains(index) else {
            return nil
        }

        return classify(
            scalars[index],
            separators: separators
        )
    }

    func flush() {
        guard !current.isEmpty else {
            return
        }

        tokens.append(
            String(
                String.UnicodeScalarView(
                    current
                )
            )
        )

        current.removeAll(
            keepingCapacity: true
        )
    }

    for index in scalars.indices {
        let scalar = scalars[index]
        let currentKind = classify(
            scalar,
            separators: separators
        )
        let previousKind = kind(
            at: index - 1
        )
        let nextKind = kind(
            at: index + 1
        )

        switch currentKind {
        case .separator:
            flush()

        case .other:
            current.append(
                scalar
            )

        case .digit:
            if previousKind == .upper || previousKind == .lower {
                flush()
            }

            current.append(
                scalar
            )

            if nextKind == .upper || nextKind == .lower {
                flush()
            }

        case .lower:
            if
                previousKind == .upper,
                current.count >= 2,
                current[current.count - 2].properties.isUppercase
            {
                let last = current.removeLast()
                flush()
                current.append(
                    last
                )
            }

            current.append(
                scalar
            )

        case .upper:
            if
                previousKind == .lower ||
                previousKind == .digit ||
                previousKind == .separator
            {
                flush()
            }

            current.append(
                scalar
            )
        }
    }

    flush()
    return tokens
}
