extension Message.Resolved {

    public struct Option: Sendable, Hashable {

        public let value: Message.Value

        public let isLiteral: Bool

        public init(_ value: Message.Value, isLiteral: Bool) {
            self.value = value
            self.isLiteral = isLiteral
        }
    }
}
