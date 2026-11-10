public import BCP_47

extension Message {

    struct Evaluation {

        let message: Message

        let arguments: [String: Value]

        let locale: BCP47.LanguageTag

        let functions: Functions

        var errors: [Message.Error]

        var memo: [String: Outcome]

        init(message: Message, arguments: [String: Value], locale: BCP47.LanguageTag, functions: Functions) {
            self.message = message
            self.arguments = arguments
            self.locale = locale
            self.functions = functions
            self.errors = []
            self.memo = [:]
        }
    }
}
