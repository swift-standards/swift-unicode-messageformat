import Unicode_Message_Format

extension Conformance {

    static func test(formats: Bool, selects: Bool) -> Message.Handler {
        Message.Handler { input, errors in
            resolve(input, &errors, formats: formats, selects: selects)
        }
    }

    static func resolve(
        _ input: Message.Handler.Input,
        _ errors: inout [Message.Error],
        formats: Bool,
        selects: Bool
    ) -> Message.Resolved? {
        let tests: Set<String> = ["test:function", "test:select", "test:format"]
        var value: CLDR.Number.Decimal
        var places = 0
        var failsFormat = false
        var failsSelect = false
        if let operand = input.operand, let function = operand.function, tests.contains(function),
            case .number(let decimal) = operand.value
        {
            value = decimal
            places = operand.options["decimalPlaces"]?.value == .string("1") ? 1 : 0
            failsFormat = operand.options["failsFormat"] != nil
            failsSelect = operand.options["failsSelect"] != nil
        } else {
            switch input.operand?.value {
            case .number(let decimal):
                value = decimal

            case .string(let text):
                do throws(CLDR.Number.Decimal.Error) {
                    value = try CLDR.Number.Decimal(text)
                } catch {
                    errors.append(.badOperand(input.name))
                    return nil
                }

            case .none:
                errors.append(.badOperand(input.name))
                return nil
            }
        }
        if let option = input.options["decimalPlaces"] {
            switch option.value.text {
            case "0": places = 0
            case "1": places = 1

            default:
                errors.append(.badOption("decimalPlaces"))
                return nil
            }
        }
        if let option = input.options["fails"] {
            switch option.value.text {
            case "always":
                failsFormat = true
                failsSelect = true

            case "format":
                failsFormat = true

            case "select":
                failsSelect = true

            case "never":
                break

            default:
                errors.append(.badOption("fails"))
            }
        }
        var options: [String: Message.Resolved.Option] = ["decimalPlaces": .init(.string(String(places)), isLiteral: false)]
        if failsFormat {
            options["failsFormat"] = .init(.string("true"), isLiteral: false)
        }
        if failsSelect {
            options["failsSelect"] = .init(.string("true"), isLiteral: false)
        }
        let one = value.integerDigits == [1] && value.fractionDigits.allSatisfy { $0 == 0 } && !value.isNegative
        let decimalPlaces = places
        let failing = failsFormat
        let refusing = failsSelect
        let number = value
        let format: @Sendable (inout [Message.Error]) -> Message.Formatted? = { errors in
            guard !failing else {
                errors.append(.badOption("fails"))
                return nil
            }
            return .string(text(number, places: decimalPlaces))
        }
        let select: @Sendable ([String], inout [Message.Error]) -> [String]? = { keys, _ in
            guard !refusing else {
                return nil
            }
            guard one else {
                return []
            }
            let preferred = decimalPlaces == 1 ? ["1.0", "1"] : ["1"]
            return preferred.filter { keys.contains($0) }
        }
        return Message.Resolved(
            value: .number(value),
            function: input.name,
            options: options,
            format: formats ? format : nil,
            select: selects ? select : nil
        )
    }

    static func text(_ number: CLDR.Number.Decimal, places: Int) -> String {
        var text = number.isNegative ? "-" : ""
        text += number.integerDigits.isEmpty ? "0" : number.integerDigits.map(String.init).joined()
        if places == 1 {
            text += "." + String(number.fractionDigits.first ?? 0)
        }
        return text
    }

    static let functions = Message.Functions.default
        .adding("test:function", test(formats: true, selects: true))
        .adding("test:select", test(formats: false, selects: true))
        .adding("test:format", test(formats: true, selects: false))
}
