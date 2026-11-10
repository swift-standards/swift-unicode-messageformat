extension Message {

    public enum Isolation: Sendable, Hashable, CaseIterable {
        case `default`
        case disabled
    }
}
