public import Unicode_CLDR

extension Message {

    public struct Resolved: Sendable {

        public var value: Value?

        public var function: String?

        public var options: [String: Option]

        public var direction: CLDR.Direction?

        public var isolated: Bool

        public var id: String?

        public var format: (@Sendable (inout [Message.Error]) -> Formatted?)?

        public var select: (@Sendable ([String], inout [Message.Error]) -> [String]?)?

        public init(
            value: Value?,
            function: String? = nil,
            options: [String: Option] = [:],
            direction: CLDR.Direction? = nil,
            isolated: Bool = false,
            id: String? = nil,
            format: (@Sendable (inout [Message.Error]) -> Formatted?)?,
            select: (@Sendable ([String], inout [Message.Error]) -> [String]?)? = nil
        ) {
            self.value = value
            self.function = function
            self.options = options
            self.direction = direction
            self.isolated = isolated
            self.id = id
            self.format = format
            self.select = select
        }
    }
}
