import Unicode_CLDR

extension Message.Handler {

    public static let offset = Self { input, errors in
        guard let value = decimal(input, &errors) else {
            return nil
        }
        let add = input.options["add"]
        let subtract = input.options["subtract"]
        guard (add == nil) != (subtract == nil), let option = add ?? subtract, let amount = digits(option.value.text) else {
            errors.append(.badOption(add != nil && subtract != nil ? "add" : add != nil ? "add" : "subtract"))
            return nil
        }
        let step = Int(clamping: amount)
        let shifted = value.adding(subtract != nil ? -step : step)
        let options = inherited(input)
        var format = defaultFormat
        var kind: CLDR.Plural.Kind? = .cardinal
        for (name, option) in options {
            _ = apply(name, option.value.text, to: &format, kind: &kind)
        }
        return resolved(shifted, input, options: options, format: format, kind: kind, selectable: true)
    }
}
