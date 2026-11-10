import Unicode_CLDR

extension Message.Evaluation {

    mutating func format(_ pattern: Message.Pattern, _ isolation: Message.Isolation) -> [Message.Part] {
        let direction = CLDR.direction(in: locale)
        var parts: [Message.Part] = []
        for element in pattern.elements {
            switch element {
            case .text(let text):
                parts.append(.text(text))

            case .markup(let markup):
                parts.append(self.markup(markup))

            case .expression(let expression):
                let source = Self.source(of: expression)
                let part: Message.Part
                var placeholderDirection: CLDR.Direction?
                var isolated = false
                switch self.expression(expression, input: nil) {
                case .fallback(let fallback):
                    part = .fallback(fallback)

                case .value(let resolved):
                    placeholderDirection = resolved.direction
                    isolated = resolved.isolated
                    if let format = resolved.format, let formatted = format(&errors) {
                        part = .value(formatted, direction: resolved.direction, id: resolved.id)
                    } else {
                        if resolved.format == nil {
                            errors.append(.notFormattable(source))
                        }
                        part = .fallback(source)
                    }
                }
                guard isolation == .default else {
                    parts.append(part)
                    continue
                }
                switch placeholderDirection {
                case .leftToRight where direction == .leftToRight && !isolated:
                    parts.append(part)

                case .leftToRight:
                    parts.append(contentsOf: [.isolation("\u{2066}"), part, .isolation("\u{2069}")])

                case .rightToLeft:
                    parts.append(contentsOf: [.isolation("\u{2067}"), part, .isolation("\u{2069}")])

                case .none:
                    parts.append(contentsOf: [.isolation("\u{2068}"), part, .isolation("\u{2069}")])
                }
            }
        }
        return parts
    }

    mutating func markup(_ markup: Message.Markup) -> Message.Part {
        var options: [String: String] = [:]
        var id: String?
        for (name, option) in self.options(markup.options, input: nil) {
            switch name {
            case "u:dir":
                errors.append(.badOption(name))

            case "u:id":
                id = option.value.text

            default:
                options[name] = option.value.text
            }
        }
        return .markup(markup.kind, markup.name, options: options, id: id)
    }
}
