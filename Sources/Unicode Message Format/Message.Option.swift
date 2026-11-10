extension Message {

    public struct Option: Sendable, Hashable {

        public let name: String

        public let value: Operand

        public init(name: String, value: Operand) {
            self.name = name
            self.value = value
        }
    }
}
