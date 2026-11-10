public import BCP_47
public import Unicode_CLDR

extension Message.Handler {

    public struct Input: Sendable {

        public let name: String

        public let operand: Message.Resolved?

        public let fallback: String?

        public let options: [String: Message.Resolved.Option]

        public let locale: BCP47.LanguageTag

        public let direction: CLDR.Direction?
    }
}
