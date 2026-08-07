public func parseEnumSet<E>(
    _ strings: [String],
    as _: E.Type = E.self
) throws(EnumParsingError) -> Set<E>
where
    E: StringParsableEnum & Hashable
{
    var values = Set<E>()

    values.reserveCapacity(
        strings.count
    )

    for string in strings {
        values.insert(
            try E(parsing: string)
        )
    }

    return values
}
