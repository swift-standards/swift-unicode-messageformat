extension Message {

    public enum Declaration: Sendable, Hashable {
        case input(String, Expression)
        case local(String, Expression)
    }
}

extension Message.Declaration {

    public var name: String {
        switch self {
        case .input(let name, _), .local(let name, _): name
        }
    }

    public var expression: Message.Expression {
        switch self {
        case .input(_, let expression), .local(_, let expression): expression
        }
    }
}
