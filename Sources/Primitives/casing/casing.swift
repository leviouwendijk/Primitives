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
    case screamingsnake
    case camelsnake
    case pascalsnake

    case kebab
    case train
    case screamingkebab

    case dot
    case path

    case flat
    case upperflat

    case lower
    case upper
    case title
    case sentence
}
