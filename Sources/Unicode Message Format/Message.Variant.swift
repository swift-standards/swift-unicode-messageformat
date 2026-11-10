extension Message {

    public struct Variant: Sendable, Hashable {

        public let keys: [Key]

        public let pattern: Pattern

        public init(keys: [Key], pattern: Pattern) {
            self.keys = keys
            self.pattern = pattern
        }
    }
}
