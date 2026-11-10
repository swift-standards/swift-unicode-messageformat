extension Message {

    public struct Output: Sendable, Hashable {

        public let parts: [Part]

        public let errors: [Message.Error]
    }
}

extension Message.Output {

    public var text: String {
        parts.map(\.text).joined()
    }
}
