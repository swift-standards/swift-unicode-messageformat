public import Unicode_CLDR

extension Message {

    public enum Value: Sendable, Hashable {
        case string(String)
        case number(CLDR.Number.Decimal)
    }
}

extension Message.Value {

    public init(_ value: some BinaryInteger) {
        self = .number(CLDR.Number.Decimal(value))
    }

    public init?(_ value: Double) {
        guard let decimal = CLDR.Number.Decimal(value) else {
            return nil
        }
        self = .number(decimal)
    }

    public var text: String {
        switch self {
        case .string(let text): text
        case .number(let decimal): decimal.description
        }
    }
}

extension Message.Value: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Message.Value: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) {
        self = .number(CLDR.Number.Decimal(value))
    }
}
