extension Message {

    public init(parsing source: String) throws(Message.Error) {
        var parser = Message.Parser(source)
        let parsed = try parser.message()
        try Self.validate(parsed.declarations, parsed.body)
        self.source = source
        self.declarations = parsed.declarations
        self.body = parsed.body
    }
}

extension Message: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        do throws(Message.Error) {
            try self.init(parsing: value)
        } catch {
            preconditionFailure("Invalid message \"\(value)\": \(error)")
        }
    }
}

extension Message: CustomStringConvertible {

    public var description: String { source }
}
