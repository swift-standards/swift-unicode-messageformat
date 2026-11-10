extension Message {

    public struct Functions: Sendable {

        public var handlers: [String: Handler]

        public init(_ handlers: [String: Handler]) {
            self.handlers = handlers
        }
    }
}

extension Message.Functions {

    public static let `default` = Self([
        "string": .string,
        "number": .number,
        "integer": .integer,
        "offset": .offset,
    ])

    public func adding(_ name: String, _ handler: Message.Handler) -> Self {
        var copy = self
        copy.handlers[name] = handler
        return copy
    }
}
