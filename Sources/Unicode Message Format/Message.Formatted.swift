public import Unicode_CLDR

extension Message {

    public enum Formatted: Sendable, Hashable {
        case string(String)
        case number([CLDR.Number.Part])
    }
}

extension Message.Formatted {

    public var text: String {
        switch self {
        case .string(let text): text
        case .number(let parts): parts.map(\.text).joined()
        }
    }
}
