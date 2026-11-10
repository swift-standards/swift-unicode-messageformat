extension Message {

    public struct Matcher: Sendable, Hashable {

        public let selectors: [String]

        public let variants: [Variant]

        public init(selectors: [String], variants: [Variant]) {
            self.selectors = selectors
            self.variants = variants
        }
    }
}
