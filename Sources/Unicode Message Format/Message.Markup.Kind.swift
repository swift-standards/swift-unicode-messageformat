extension Message.Markup {

    public enum Kind: Sendable, Hashable, CaseIterable {
        case open
        case standalone
        case close
    }
}
