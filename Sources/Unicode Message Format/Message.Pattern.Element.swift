extension Message.Pattern {

    public enum Element: Sendable, Hashable {
        case text(String)
        case expression(Message.Expression)
        case markup(Message.Markup)
    }
}
