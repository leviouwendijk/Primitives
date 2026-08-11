@inline(__always)
internal func capitalized_case_word(
    _ value: String
) -> String {
    guard let first = value.first else {
        return value
    }

    return String(first).uppercased()
        + value.dropFirst().lowercased()
}
