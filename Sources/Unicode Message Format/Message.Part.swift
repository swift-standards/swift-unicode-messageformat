public import Unicode_CLDR

extension Message {

    public enum Part: Sendable, Hashable {
        case text(String)
        case value(Formatted, direction: CLDR.Direction?, id: String?)
        case markup(Markup.Kind, String, options: [String: String], id: String?)
        case fallback(String)
        case isolation(Unicode.Scalar)
    }
}

extension Message.Part {

    public var text: String {
        switch self {
        case .text(let text): text
        case .value(let formatted, _, _): formatted.text
        case .markup: ""
        case .fallback(let source): "{" + source + "}"
        case .isolation(let scalar): String(scalar)
        }
    }
}
