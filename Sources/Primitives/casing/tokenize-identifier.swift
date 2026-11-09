internal func tokenize_identifier(
    _ value: String,
    separators: Separators
) -> [String] {
    tokenize_identifier_segments(value, separators: separators).compactMap {
        $0.kind == .component ? $0.text : nil
    }
}

internal func tokenize_identifier_segments(
    _ value: String,
    separators: Separators
) -> [Case.Segment] {
    let scalars = Array(value.unicodeScalars)
    guard !scalars.isEmpty else { return [] }

    var offsets = [Int](repeating: 0, count: scalars.count + 1)
    for index in scalars.indices {
        offsets[index + 1] = offsets[index] + String(scalars[index]).utf8.count
    }

    var result: [Case.Segment] = []
    var current: [UnicodeScalar] = []
    var beginning: Int?

    func kind(_ index: Int) -> ScalarKind? {
        guard scalars.indices.contains(index) else { return nil }
        return classify(scalars[index], separators: separators)
    }

    func flush(_ end: Int) {
        guard let start = beginning, !current.isEmpty else { return }
        result.append(.init(
            kind: .component,
            text: String(String.UnicodeScalarView(current)),
            utf8: offsets[start]..<offsets[end]
        ))
        beginning = nil
        current.removeAll(keepingCapacity: true)
    }

    func append(_ scalar: UnicodeScalar, at index: Int) {
        if current.isEmpty { beginning = index }
        current.append(scalar)
    }

    for index in scalars.indices {
        let scalar = scalars[index]
        let previous = kind(index - 1)
        let next = kind(index + 1)
        switch classify(scalar, separators: separators) {
        case .separator:
            flush(index)
            result.append(.init(
                kind: .separator,
                text: String(scalar),
                utf8: offsets[index]..<offsets[index + 1]
            ))
        case .other:
            append(scalar, at: index)
        case .digit:
            if previous == .upper || previous == .lower { flush(index) }
            append(scalar, at: index)
            if next == .upper || next == .lower { flush(index + 1) }
        case .lower:
            if previous == .upper,
               current.count >= 2,
               current[current.count - 2].properties.isUppercase {
                let carried = current.removeLast()
                flush(index - 1)
                append(carried, at: index - 1)
            }
            append(scalar, at: index)
        case .upper:
            if previous == .lower || previous == .digit || previous == .separator {
                flush(index)
            }
            append(scalar, at: index)
        }
    }
    flush(scalars.count)
    return result
}
