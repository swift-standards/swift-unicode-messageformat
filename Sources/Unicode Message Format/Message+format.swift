public import BCP_47

extension Message {

    public func format(
        _ arguments: [String: Message.Value] = [:],
        in locale: BCP47.LanguageTag,
        functions: Message.Functions = .default,
        isolation: Message.Isolation = .default
    ) -> Message.Output {
        var evaluation = Message.Evaluation(message: self, arguments: arguments, locale: locale, functions: functions)
        let pattern: Message.Pattern
        switch body {
        case .pattern(let body): pattern = body
        case .matcher(let matcher): pattern = evaluation.select(matcher)
        }
        let parts = evaluation.format(pattern, isolation)
        return Message.Output(parts: parts, errors: evaluation.errors)
    }

    public func callAsFunction(_ arguments: [String: Message.Value] = [:], in locale: BCP47.LanguageTag) -> String {
        format(arguments, in: locale).text
    }
}
