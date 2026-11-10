extension Message {

    static func validate(_ declarations: [Message.Declaration], _ body: Message.Body) throws(Message.Error) {
        var declared: Set<String> = []
        var used: Set<String> = []
        for declaration in declarations {
            let expression = declaration.expression
            try uniqueOptions(expression.function?.options ?? [])
            var references = Self.variables(in: expression)
            if case .input(let name, _) = declaration {
                references.remove(name)
            }
            let name = declaration.name
            guard !declared.contains(name), !used.contains(name), !references.contains(name) else {
                throw .duplicateDeclaration(name)
            }
            used.formUnion(references)
            declared.insert(name)
        }
        switch body {
        case .pattern(let pattern):
            try validate(pattern)

        case .matcher(let matcher):
            for selector in matcher.selectors {
                try annotated(selector, declarations)
            }
            var seen: [[Message.Key]] = []
            var fallback = false
            for variant in matcher.variants {
                guard variant.keys.count == matcher.selectors.count else {
                    throw .variantKeyMismatch
                }
                if variant.keys.allSatisfy({ $0 == .catchAll }) {
                    fallback = true
                }
                guard !seen.contains(variant.keys) else {
                    throw .duplicateVariant
                }
                seen.append(variant.keys)
                try validate(variant.pattern)
            }
            guard fallback else {
                throw .missingFallbackVariant
            }
        }
    }

    static func validate(_ pattern: Message.Pattern) throws(Message.Error) {
        for element in pattern.elements {
            switch element {
            case .text:
                continue

            case .expression(let expression):
                try uniqueOptions(expression.function?.options ?? [])

            case .markup(let markup):
                try uniqueOptions(markup.options)
            }
        }
    }

    static func uniqueOptions(_ options: [Message.Option]) throws(Message.Error) {
        var names: Set<String> = []
        for option in options {
            guard names.insert(option.name).inserted else {
                throw .duplicateOptionName(option.name)
            }
        }
    }

    static func variables(in expression: Message.Expression) -> Set<String> {
        var names: Set<String> = []
        if case .variable(let name) = expression.operand {
            names.insert(name)
        }
        for option in expression.function?.options ?? [] {
            if case .variable(let name) = option.value {
                names.insert(name)
            }
        }
        return names
    }

    static func annotated(_ name: String, _ declarations: [Message.Declaration]) throws(Message.Error) {
        var current = name
        var visited: Set<String> = []
        while visited.insert(current).inserted {
            guard let declaration = declarations.last(where: { $0.name == current }) else {
                break
            }
            if declaration.expression.function != nil {
                return
            }
            guard case .variable(let next) = declaration.expression.operand, case .local = declaration else {
                break
            }
            current = next
        }
        throw .missingSelectorAnnotation(name)
    }
}
