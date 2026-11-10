extension Message {

    public enum Operand: Sendable, Hashable {
        case literal(String)
        case variable(String)
    }
}
