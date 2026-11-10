extension Message.Evaluation {

    mutating func select(_ matcher: Message.Matcher) -> Message.Pattern {
        var matches: [[String]] = []
        for (position, selector) in zip(matcher.selectors.indices, matcher.selectors) {
            guard case .value(let resolved) = variable(selector), let select = resolved.select else {
                errors.append(.badSelector(selector))
                matches.append([])
                continue
            }
            var keys: [String] = []
            for variant in matcher.variants {
                if case .literal(let key) = variant.keys[position], !keys.contains(key) {
                    keys.append(key)
                }
            }
            guard let matched = select(keys, &errors) else {
                errors.append(.badSelector(selector))
                matches.append([])
                continue
            }
            matches.append(matched)
        }
        var best: Message.Variant?
        for variant in matcher.variants where Self.matches(variant.keys, matches) {
            guard let current = best else {
                best = variant
                continue
            }
            if Self.better(variant.keys, than: current.keys, matches) {
                best = variant
            }
        }
        return best?.pattern ?? Message.Pattern([])
    }

    static func matches(_ keys: [Message.Key], _ matches: [[String]]) -> Bool {
        zip(keys, matches).allSatisfy { key, matched in
            switch key {
            case .catchAll: true
            case .literal(let text): matched.contains(text)
            }
        }
    }

    static func better(_ keys: [Message.Key], than other: [Message.Key], _ matches: [[String]]) -> Bool {
        for ((first, second), matched) in zip(zip(keys, other), matches) {
            switch (first, second) {
            case (.catchAll, .catchAll):
                continue

            case (.catchAll, .literal):
                return false

            case (.literal, .catchAll):
                return true

            case (.literal(let a), .literal(let b)):
                if a == b {
                    continue
                }
                let rankA = matched.firstIndex(of: a) ?? matched.endIndex
                let rankB = matched.firstIndex(of: b) ?? matched.endIndex
                return rankA < rankB
            }
        }
        return false
    }
}
