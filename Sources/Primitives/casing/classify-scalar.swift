@inline(__always)
internal func classify(
    _ scalar: UnicodeScalar,
    separators: Separators
) -> ScalarKind {
    if separators.contains(scalar) {
        return .separator
    }

    if scalar.properties.isUppercase {
        return .upper
    }

    if scalar.properties.isLowercase {
        return .lower
    }

    if scalar.properties.numericType == .decimal {
        return .digit
    }

    return .other
}
