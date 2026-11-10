extension Message.Evaluation {

    enum Outcome: Sendable {
        case value(Message.Resolved)
        case fallback(String)
    }
}
