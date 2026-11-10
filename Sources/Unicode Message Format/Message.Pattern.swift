extension Message {

    public struct Pattern: Sendable, Hashable {

        public let elements: [Element]

        public init(_ elements: [Element]) {
            self.elements = elements
        }
    }
}
