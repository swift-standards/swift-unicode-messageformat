import Unicode_CLDR

extension Message.Evaluation {

    mutating func variable(_ name: String) -> Outcome {
        if let outcome = memo[name] {
            return outcome
        }
        let outcome: Outcome
        if let declaration = message.declarations.first(where: { $0.name == name }) {
            let input: String? =
                switch declaration {
                case .input(let name, _): name
                case .local: nil
                }
            switch expression(declaration.expression, input: input) {
            case .value(let resolved): outcome = .value(resolved)
            case .fallback: outcome = .fallback("$" + name)
            }
        } else {
            outcome = argument(name)
        }
        memo[name] = outcome
        return outcome
    }

    mutating func argument(_ name: String) -> Outcome {
        guard let value = arguments[name] else {
            errors.append(.unresolvedVariable(name))
            return .fallback("$" + name)
        }
        switch value {
        case .string(let text):
            return .value(Message.Resolved(value: value, format: { _ in .string(text) }))

        case .number(let decimal):
            let locale = self.locale
            let format = Message.Handler.defaultFormat
            return .value(
                Message.Resolved(
                    value: value,
                    direction: CLDR.direction(in: locale),
                    format: { _ in .number(decimal.formattedParts(format, in: locale)) }
                )
            )
        }
    }

    static func source(of expression: Message.Expression) -> String {
        switch expression.operand {
        case .literal(let text):
            var escaped = ""
            for character in text {
                if character == "\\" || character == "|" {
                    escaped.append("\\")
                }
                escaped.append(character)
            }
            return "|" + escaped + "|"

        case .variable(let name):
            return "$" + name

        case .none:
            return ":" + (expression.function?.name ?? "")
        }
    }

    mutating func expression(_ expression: Message.Expression, input: String?) -> Outcome {
        let source = Self.source(of: expression)
        var operand: Outcome?
        switch expression.operand {
        case .literal(let text):
            operand = .value(Message.Resolved(value: .string(text), format: { _ in .string(text) }))

        case .variable(let name):
            operand = name == input ? argument(name) : variable(name)

        case .none:
            operand = nil
        }
        guard let function = expression.function else {
            switch operand {
            case .value(let resolved): return .value(resolved)
            case .fallback, .none: return .fallback(source)
            }
        }
        guard let handler = functions.handlers[function.name] else {
            errors.append(.unknownFunction(function.name))
            return .fallback(source)
        }
        var resolvedOperand: Message.Resolved?
        var fallback: String?
        switch operand {
        case .fallback(let representation):
            fallback = representation

        case .value(let resolved):
            resolvedOperand = resolved

        case .none:
            resolvedOperand = nil
        }
        var options = self.options(function.options, input: input)
        var direction: CLDR.Direction?? = .none
        var isolated = false
        if let option = options.removeValue(forKey: "u:dir") {
            switch option.value {
            case .string("ltr"):
                direction = .some(.leftToRight)
                isolated = true

            case .string("rtl"):
                direction = .some(.rightToLeft)
                isolated = true

            case .string("auto"):
                direction = .some(nil)
                isolated = true

            case .string("inherit"):
                break

            default:
                errors.append(.badOption("u:dir"))
            }
        }
        var id: String?
        if let option = options.removeValue(forKey: "u:id") {
            id = option.value.text
        }
        let call = Message.Handler.Input(
            name: function.name,
            operand: resolvedOperand,
            fallback: fallback,
            options: options,
            locale: locale,
            direction: nil
        )
        guard var resolved = handler.resolve(call, &errors) else {
            return .fallback(source)
        }
        if case .some(let override) = direction {
            resolved.direction = override
        }
        if isolated {
            resolved.isolated = true
        }
        if let id {
            resolved.id = id
        }
        return .value(resolved)
    }

    mutating func options(_ options: [Message.Option], input: String?) -> [String: Message.Resolved.Option] {
        var resolved: [String: Message.Resolved.Option] = [:]
        for option in options {
            switch option.value {
            case .literal(let text):
                resolved[option.name] = Message.Resolved.Option(.string(text), isLiteral: true)

            case .variable(let name):
                let outcome = name == input ? argument(name) : variable(name)
                guard case .value(let value) = outcome, let unwrapped = value.value else {
                    errors.append(.badOption(option.name))
                    continue
                }
                resolved[option.name] = Message.Resolved.Option(unwrapped, isLiteral: false)
            }
        }
        return resolved
    }
}
