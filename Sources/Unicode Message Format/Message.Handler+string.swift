extension Message.Handler {

    public static let string = Self { input, errors in
        if input.fallback != nil {
            return Message.Resolved(value: nil, function: input.name, format: { _ in nil }, select: { _, _ in [] })
        }
        guard let value = input.operand?.value else {
            errors.append(.badOperand(input.name))
            return nil
        }
        let text = value.text
        return Message.Resolved(
            value: .string(text),
            function: input.name,
            format: { _ in .string(text) },
            select: { keys, _ in keys.filter { $0 == text } }
        )
    }
}
