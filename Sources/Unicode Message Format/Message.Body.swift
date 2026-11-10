extension Message {

    public enum Body: Sendable, Hashable {
        case pattern(Pattern)
        case matcher(Matcher)
    }
}
