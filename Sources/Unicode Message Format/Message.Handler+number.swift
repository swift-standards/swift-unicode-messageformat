import Cardinal
import Unicode_CLDR

extension Message.Handler {

    public static let number = Self { input, errors in
        numeric(input, &errors, integer: false)
    }

    public static let integer = Self { input, errors in
        numeric(input, &errors, integer: true)
    }

    static let numericFunctions: Set<String> = ["number", "integer", "offset"]

    static let defaultFormat = CLDR.Number.Format(rounding: .halfExpand)

    static func decimal(_ input: Input, _ errors: inout [Message.Error]) -> CLDR.Number.Decimal? {
        switch input.operand?.value {
        case .number(let decimal):
            return decimal

        case .string(let text):
            do throws(CLDR.Number.Decimal.Error) {
                return try CLDR.Number.Decimal(text)
            } catch {
                errors.append(.badOperand(input.name))
                return nil
            }

        case .none:
            errors.append(.badOperand(input.name))
            return nil
        }
    }

    static func inherited(_ input: Input) -> [String: Message.Resolved.Option] {
        guard let operand = input.operand, let function = operand.function, numericFunctions.contains(function) else {
            return [:]
        }
        return operand.options
    }

    static func numeric(_ input: Input, _ errors: inout [Message.Error], integer: Bool) -> Message.Resolved? {
        guard var value = decimal(input, &errors) else {
            return nil
        }
        var options = inherited(input)
        let selectFromOperand = options["select"] != nil
        if integer {
            for name in ["minimumFractionDigits", "maximumFractionDigits", "minimumSignificantDigits"] {
                options.removeValue(forKey: name)
            }
            value = value.rounded(CLDR.Number.Format(maximumFractionDigits: 0, rounding: .halfExpand), in: input.locale)
        }
        for (name, option) in input.options {
            options[name] = option
        }
        var selectable = true
        if let select = input.options["select"], !select.isLiteral {
            errors.append(.badOption("select"))
            selectable = false
            options.removeValue(forKey: "select")
        } else if input.options["select"] == nil, selectFromOperand {
            errors.append(.badOption("select"))
            selectable = false
        }
        let accepted: Set<String> =
            integer
            ? ["select", "signDisplay", "useGrouping", "minimumIntegerDigits", "maximumSignificantDigits"]
            : [
                "select", "signDisplay", "useGrouping", "minimumIntegerDigits", "minimumFractionDigits",
                "maximumFractionDigits", "minimumSignificantDigits", "maximumSignificantDigits", "trailingZeroDisplay",
                "roundingPriority", "roundingIncrement", "roundingMode",
            ]
        var format = defaultFormat
        if integer {
            format.maximumFractionDigits = 0
        }
        var kind: CLDR.Plural.Kind? = .cardinal
        for (name, option) in options where accepted.contains(name) {
            guard apply(name, option.value.text, to: &format, kind: &kind) else {
                errors.append(.badOption(name))
                options.removeValue(forKey: name)
                continue
            }
        }
        return resolved(value, input, options: options, format: format, kind: selectable ? kind : nil, selectable: selectable)
    }

    static func resolved(
        _ value: CLDR.Number.Decimal,
        _ input: Input,
        options: [String: Message.Resolved.Option],
        format: CLDR.Number.Format,
        kind: CLDR.Plural.Kind?,
        selectable: Bool
    ) -> Message.Resolved {
        let locale = input.locale
        let exactOnly = options["select"]?.value == .string("exact")
        let plain = ["minimumFractionDigits", "minimumIntegerDigits", "minimumSignificantDigits", "maximumSignificantDigits"]
            .allSatisfy { options[$0] == nil }
        let select: @Sendable ([String], inout [Message.Error]) -> [String]? = { keys, errors in
            let rounded = value.rounded(format, in: locale)
            let exact = rounded.isZero && rounded.fractionDigits.isEmpty && plain ? "0" : rounded.description
            let keyword = exactOnly ? nil : "\(CLDR.plural(rounded, kind ?? .cardinal, in: locale))"
            var exactMatches: [String] = []
            var keywordMatches: [String] = []
            for key in keys {
                if isNumberLiteral(key) {
                    if key == exact {
                        exactMatches.append(key)
                    }
                } else if CLDR.Plural.Category.allCases.contains(where: { "\($0)" == key }) {
                    if key == keyword {
                        keywordMatches.append(key)
                    }
                } else {
                    errors.append(.badVariantKey(key))
                }
            }
            return exactMatches + keywordMatches
        }
        return Message.Resolved(
            value: .number(value),
            function: input.name,
            options: options,
            direction: CLDR.direction(in: locale),
            format: { _ in .number(value.formattedParts(format, in: locale)) },
            select: selectable ? select : nil
        )
    }

    static func isNumberLiteral(_ text: String) -> Bool {
        do throws(CLDR.Number.Decimal.Error) {
            _ = try CLDR.Number.Decimal(text)
            return true
        } catch {
            return false
        }
    }

    static func digits(_ text: String) -> Cardinal? {
        guard (1...2).contains(text.count), text.allSatisfy({ $0.isASCII && $0.isNumber }), text.count == 1 || text.first != "0",
            let value = UInt(text)
        else {
            return nil
        }
        return Cardinal(value)
    }

    static func apply(_ name: String, _ text: String, to format: inout CLDR.Number.Format, kind: inout CLDR.Plural.Kind?) -> Bool {
        switch name {
        case "select":
            switch text {
            case "plural": kind = .cardinal
            case "ordinal": kind = .ordinal
            case "exact": kind = nil
            default: return false
            }

        case "signDisplay":
            guard let sign = CLDR.Number.Format.Sign.allCases.first(where: { "\($0)" == text }) else {
                return false
            }
            format.sign = sign

        case "useGrouping":
            guard let grouping = CLDR.Number.Format.Grouping.allCases.first(where: { "\($0)" == text }) else {
                return false
            }
            format.grouping = grouping

        case "trailingZeroDisplay":
            guard let zeros = CLDR.Number.Format.TrailingZeros.allCases.first(where: { "\($0)" == text }) else {
                return false
            }
            format.trailingZeros = zeros

        case "roundingPriority":
            guard let priority = CLDR.Number.Format.Priority.allCases.first(where: { "\($0)" == text }) else {
                return false
            }
            format.priority = priority

        case "roundingMode":
            guard let rounding = CLDR.Number.Format.Rounding.allCases.first(where: { "\($0)" == text }) else {
                return false
            }
            format.rounding = rounding

        case "roundingIncrement":
            let increments: Set<String> = ["1", "2", "5", "10", "20", "25", "50", "100", "200", "250", "500", "1000", "2000", "2500", "5000"]
            guard increments.contains(text), let value = UInt(text) else {
                return false
            }
            format.increment = Cardinal(value)

        default:
            guard let value = digits(text) else {
                return false
            }
            switch name {
            case "minimumIntegerDigits": format.minimumIntegerDigits = value
            case "minimumFractionDigits": format.minimumFractionDigits = value
            case "maximumFractionDigits": format.maximumFractionDigits = value
            case "minimumSignificantDigits": format.minimumSignificantDigits = value
            default: format.maximumSignificantDigits = value
            }
        }
        return true
    }
}
