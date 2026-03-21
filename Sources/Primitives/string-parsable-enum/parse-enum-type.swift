public func parseEnum<E>(
    _ string: String,
    as _: E.Type = E.self
) throws(EnumParsingError) -> E
where E: RawRepresentable & CaseIterable, E.RawValue == String {
    guard let value = E(rawValue: string) else {
        throw EnumParsingError(
            enumName: String(describing: E.self),
            provided: string,
            cases: E.allCases.map(\.rawValue).joined(separator: "\n")
        )
    }
    return value
}

public func parseRawEnum<E>(
    _ string: String,
    as _: E.Type = E.self
) -> E?
where E: RawRepresentable, E.RawValue == String {
    E(rawValue: string)
}
