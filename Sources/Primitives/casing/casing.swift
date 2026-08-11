public enum Casing:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case camel
    case pascal
    case snake
    case kebab
}
