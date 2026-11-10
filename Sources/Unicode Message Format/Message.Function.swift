extension Message {

    public struct Function: Sendable, Hashable {

        public let name: String

        public let options: [Option]

        public init(name: String, options: [Option]) {
            self.name = name
            self.options = options
        }
    }
}
