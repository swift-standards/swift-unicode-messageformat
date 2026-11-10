extension Message {

    public struct Markup: Sendable, Hashable {

        public let kind: Kind

        public let name: String

        public let options: [Option]

        public let attributes: [Attribute]

        public init(kind: Kind, name: String, options: [Option], attributes: [Attribute]) {
            self.kind = kind
            self.name = name
            self.options = options
            self.attributes = attributes
        }
    }
}
