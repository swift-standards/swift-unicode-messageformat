extension Message {

    public struct Handler: Sendable {

        public let resolve: @Sendable (Input, inout [Message.Error]) -> Resolved?

        public init(_ resolve: @escaping @Sendable (Input, inout [Message.Error]) -> Resolved?) {
            self.resolve = resolve
        }
    }
}
