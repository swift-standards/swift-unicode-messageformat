import Cardinal

extension Message {

    struct Parser {

        let scalars: [Unicode.Scalar]

        var position: Int

        init(_ source: String) {
            self.scalars = Self.scalars(source)
            self.position = 0
        }
    }
}

extension Message.Parser {

    static func scalars(_ text: String) -> [Unicode.Scalar] {
        var scalars: [Unicode.Scalar] = []
        var bytes = text.utf8.makeIterator()
        var decoder = Unicode.UTF8()
        while case .scalarValue(let scalar) = decoder.decode(&bytes) {
            scalars.append(scalar)
        }
        return scalars
    }

    var peek: Unicode.Scalar? {
        position < scalars.count ? scalars[position] : nil
    }

    var failure: Message.Error {
        .syntax(Cardinal(UInt(position)))
    }

    func starts(with text: String) -> Bool {
        var index = position
        for scalar in Self.scalars(text) {
            guard index < scalars.count, scalars[index] == scalar else {
                return false
            }
            index += 1
        }
        return true
    }

    mutating func expect(_ scalar: Unicode.Scalar) throws(Message.Error) {
        guard peek == scalar else {
            throw failure
        }
        position += 1
    }

    static func isWhitespace(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x20, 0x09, 0x0D, 0x0A, 0x3000: true
        default: false
        }
    }

    static func isBidi(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x061C, 0x200E, 0x200F, 0x2066...0x2069: true
        default: false
        }
    }

    static func isNameStart(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        switch value {
        case 0x41...0x5A, 0x61...0x7A, 0x2B, 0x5F: return true
        case 0xA1...0x61B, 0x61D...0x167F, 0x1681...0x1FFF, 0x200B...0x200D, 0x2010...0x2027: return true
        case 0x2030...0x205E, 0x2060...0x2065, 0x206A...0x2FFF, 0x3001...0xD7FF: return true
        case 0xE000...0xFDCF, 0xFDF0...0xFFFD: return true
        case 0x10000...0x10FFFF: return value & 0xFFFE != 0xFFFE
        default: return false
        }
    }

    static func isNameCharacter(_ scalar: Unicode.Scalar) -> Bool {
        isNameStart(scalar) || (0x30...0x39).contains(scalar.value) || scalar == "-" || scalar == "."
    }

    @discardableResult
    mutating func skipOptional() -> Bool {
        var whitespace = false
        while let scalar = peek, Self.isWhitespace(scalar) || Self.isBidi(scalar) {
            whitespace = whitespace || Self.isWhitespace(scalar)
            position += 1
        }
        return whitespace
    }
}

extension Message.Parser {

    mutating func message() throws(Message.Error) -> (declarations: [Message.Declaration], body: Message.Body) {
        skipOptional()
        guard peek == "." || starts(with: "{{") else {
            position = 0
            let pattern = try self.pattern(quoted: false)
            return ([], .pattern(pattern))
        }
        var declarations: [Message.Declaration] = []
        while true {
            if starts(with: ".input") {
                position += 6
                skipOptional()
                let expression = try placeholderExpression()
                guard case .variable(let name) = expression.operand else {
                    throw failure
                }
                declarations.append(.input(name, expression))
            } else if starts(with: ".local") {
                position += 6
                guard skipOptional() else {
                    throw failure
                }
                let name = try variable()
                skipOptional()
                try expect("=")
                skipOptional()
                declarations.append(.local(name, try placeholderExpression()))
            } else {
                break
            }
            skipOptional()
        }
        let body: Message.Body
        if starts(with: "{{") {
            body = .pattern(try quotedPattern())
        } else if starts(with: ".match") {
            body = .matcher(try matcher())
        } else {
            throw failure
        }
        skipOptional()
        guard position == scalars.count else {
            throw failure
        }
        return (declarations, body)
    }

    mutating func quotedPattern() throws(Message.Error) -> Message.Pattern {
        try expect("{")
        try expect("{")
        let pattern = try self.pattern(quoted: true)
        try expect("}")
        try expect("}")
        return pattern
    }

    mutating func pattern(quoted: Bool) throws(Message.Error) -> Message.Pattern {
        var elements: [Message.Pattern.Element] = []
        var text = ""
        func flush() {
            if !text.isEmpty {
                elements.append(.text(text))
                text = ""
            }
        }
        while let scalar = peek {
            switch scalar {
            case "\\":
                text.unicodeScalars.append(try escaped(allowing: ["\\", "{", "|", "}"]))

            case "{":
                flush()
                elements.append(try placeholder())

            case "}":
                guard quoted else {
                    throw failure
                }
                flush()
                return Message.Pattern(elements)

            case "\u{0}":
                throw failure

            default:
                text.unicodeScalars.append(scalar)
                position += 1
            }
        }
        guard !quoted else {
            throw failure
        }
        flush()
        return Message.Pattern(elements)
    }

    mutating func escaped(allowing allowed: Set<Unicode.Scalar>) throws(Message.Error) -> Unicode.Scalar {
        try expect("\\")
        guard let scalar = peek, allowed.contains(scalar) else {
            throw failure
        }
        position += 1
        return scalar
    }

    mutating func placeholder() throws(Message.Error) -> Message.Pattern.Element {
        let start = position
        try expect("{")
        skipOptional()
        if peek == "#" || peek == "/" {
            position = start
            return .markup(try markup())
        }
        position = start
        return .expression(try placeholderExpression())
    }

    mutating func placeholderExpression() throws(Message.Error) -> Message.Expression {
        try expect("{")
        skipOptional()
        var operand: Message.Operand?
        var function: Message.Function?
        if peek == "$" {
            operand = .variable(try variable())
        } else if peek == ":" {
            function = try self.function()
        } else {
            operand = .literal(try literal())
        }
        var attributes: [Message.Attribute] = []
        while true {
            let mark = position
            let whitespace = skipOptional()
            if peek == ":", function == nil, attributes.isEmpty, whitespace {
                function = try self.function()
            } else if peek == "@", whitespace {
                attributes.append(try attribute())
            } else {
                position = mark
                break
            }
        }
        skipOptional()
        try expect("}")
        return Message.Expression(operand: operand, function: function, attributes: attributes)
    }

    mutating func markup() throws(Message.Error) -> Message.Markup {
        try expect("{")
        skipOptional()
        let closing = peek == "/"
        position += 1
        let name = try identifier()
        var options: [Message.Option] = []
        var attributes: [Message.Attribute] = []
        while true {
            let mark = position
            let whitespace = skipOptional()
            if peek == "@", whitespace {
                attributes.append(try attribute())
            } else if let scalar = peek, Self.isNameStart(scalar), whitespace, attributes.isEmpty {
                options.append(try option())
            } else {
                position = mark
                break
            }
        }
        skipOptional()
        var kind: Message.Markup.Kind = closing ? .close : .open
        if !closing, peek == "/" {
            position += 1
            kind = .standalone
        }
        try expect("}")
        return Message.Markup(kind: kind, name: name, options: options, attributes: attributes)
    }

    mutating func function() throws(Message.Error) -> Message.Function {
        try expect(":")
        let name = try identifier()
        var options: [Message.Option] = []
        while true {
            let mark = position
            let whitespace = skipOptional()
            guard whitespace, let scalar = peek, Self.isNameStart(scalar) else {
                position = mark
                break
            }
            options.append(try option())
        }
        return Message.Function(name: name, options: options)
    }

    mutating func option() throws(Message.Error) -> Message.Option {
        let name = try identifier()
        skipOptional()
        try expect("=")
        skipOptional()
        if peek == "$" {
            return Message.Option(name: name, value: .variable(try variable()))
        }
        return Message.Option(name: name, value: .literal(try literal()))
    }

    mutating func attribute() throws(Message.Error) -> Message.Attribute {
        try expect("@")
        let name = try identifier()
        let mark = position
        skipOptional()
        guard peek == "=" else {
            position = mark
            return Message.Attribute(name: name, value: nil)
        }
        position += 1
        skipOptional()
        return Message.Attribute(name: name, value: try literal())
    }

    mutating func variable() throws(Message.Error) -> String {
        try expect("$")
        return try self.name()
    }

    mutating func identifier() throws(Message.Error) -> String {
        let first = try name()
        guard peek == ":" else {
            return first
        }
        position += 1
        return first + ":" + (try name())
    }

    mutating func name() throws(Message.Error) -> String {
        if let scalar = peek, Self.isBidi(scalar) {
            position += 1
        }
        guard let first = peek, Self.isNameStart(first) else {
            throw failure
        }
        var name = String.UnicodeScalarView()
        while let scalar = peek, Self.isNameCharacter(scalar) {
            name.append(scalar)
            position += 1
        }
        if let scalar = peek, Self.isBidi(scalar) {
            position += 1
        }
        return String(name)
    }

    mutating func literal() throws(Message.Error) -> String {
        if peek == "|" {
            position += 1
            var value = String.UnicodeScalarView()
            while let scalar = peek, scalar != "|" {
                switch scalar {
                case "\\":
                    value.append(try escaped(allowing: ["\\", "{", "|", "}"]))

                case "\u{0}":
                    throw failure

                default:
                    value.append(scalar)
                    position += 1
                }
            }
            try expect("|")
            return String(value)
        }
        var value = String.UnicodeScalarView()
        while let scalar = peek, Self.isNameCharacter(scalar) {
            value.append(scalar)
            position += 1
        }
        guard !value.isEmpty else {
            throw failure
        }
        return String(value)
    }

    mutating func matcher() throws(Message.Error) -> Message.Matcher {
        position += 6
        var selectors: [String] = []
        while true {
            let mark = position
            let whitespace = skipOptional()
            guard whitespace, peek == "$" else {
                position = mark
                break
            }
            selectors.append(try variable())
        }
        guard !selectors.isEmpty, skipOptional() else {
            throw failure
        }
        var variants: [Message.Variant] = [try variant()]
        while true {
            let mark = position
            skipOptional()
            guard let scalar = peek, scalar == "*" || scalar == "|" || Self.isNameCharacter(scalar) else {
                position = mark
                break
            }
            variants.append(try variant())
        }
        return Message.Matcher(selectors: selectors, variants: variants)
    }

    mutating func variant() throws(Message.Error) -> Message.Variant {
        var keys: [Message.Key] = [try key()]
        while true {
            let mark = position
            let whitespace = skipOptional()
            guard whitespace, let scalar = peek, scalar == "*" || scalar == "|" || Self.isNameCharacter(scalar) else {
                position = mark
                break
            }
            keys.append(try key())
        }
        skipOptional()
        return Message.Variant(keys: keys, pattern: try quotedPattern())
    }

    mutating func key() throws(Message.Error) -> Message.Key {
        if peek == "*" {
            position += 1
            return .catchAll
        }
        return .literal(try literal())
    }
}
