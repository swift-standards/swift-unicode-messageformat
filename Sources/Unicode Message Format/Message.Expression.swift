extension Message {

    public struct Expression: Sendable, Hashable {

        public let operand: Operand?

        public let function: Function?

        public let attributes: [Attribute]

        public init(operand: Operand?, function: Function?, attributes: [Attribute]) {
            self.operand = operand
            self.function = function
            self.attributes = attributes
        }
    }
}
