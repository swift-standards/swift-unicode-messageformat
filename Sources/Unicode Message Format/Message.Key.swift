extension Message {

    public enum Key: Sendable, Hashable {
        case literal(String)
        case catchAll
    }
}
