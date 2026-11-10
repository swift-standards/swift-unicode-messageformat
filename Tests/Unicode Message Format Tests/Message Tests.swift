import Testing
import Unicode_Message_Format

enum `Message Tests` {}

extension `Message Tests` {
    @Suite struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension `Message Tests` {

    static let apps: Message = """
        .input {$count :number}
        .match $count
        one {{{$count} app}}
        *   {{{$count} apps}}
        """
}

extension `Message Tests`.Test.Unit {

    @Test
    func `the point of use reads as the issue sketches it`() {
        let apps = `Message Tests`.apps
        #expect(apps(["count": 3], in: .en) == "3 apps")
        #expect(apps(["count": 1], in: .en) == "1 app")
        #expect(apps(["count": 1234], in: .nl) == "1.234 apps")
    }

    @Test
    func `plural selection follows CLDR for the locale`() throws {
        let files: Message = """
            .input {$n :integer}
            .match $n
            0    {{нет файлов}}
            one  {{{$n} файл}}
            few  {{{$n} файла}}
            many {{{$n} файлов}}
            *    {{{$n} файла}}
            """
        #expect(files(["n": 0], in: .ru) == "нет файлов")
        #expect(files(["n": 21], in: .ru) == "21 файл")
        #expect(files(["n": 23], in: .ru) == "23 файла")
        #expect(files(["n": 25], in: .ru) == "25 файлов")
        let place = try Message(
            parsing:
                ".input {$n :number select=ordinal} .match $n one {{{$n}st}} two {{{$n}nd}} few {{{$n}rd}} * {{{$n}th}}"
        )
        #expect(place(["n": 1], in: .en) == "1st")
        #expect(place(["n": 22], in: .en) == "22nd")
        #expect(place(["n": 13], in: .en) == "13th")
    }

    @Test
    func `number options reach the CLDR formatter`() throws {
        let rounded = try Message(parsing: "{1234.5 :number maximumFractionDigits=0}")
        #expect(rounded(in: .en) == "1,235")
        let even = try Message(parsing: "{1234.5 :number maximumFractionDigits=0 roundingMode=halfEven}")
        #expect(even(in: .en) == "1,234")
        let signed = try Message(parsing: "{5 :number signDisplay=always minimumFractionDigits=1}")
        #expect(signed(in: .nl) == "+5,0")
        #expect(try Message(parsing: "{4.5 :integer}")(in: .en) == "5")
        #expect(try Message(parsing: "{-4.5 :integer}")(in: .en) == "-5")
        #expect(try Message(parsing: "{41 :offset add=1}")(in: .en) == "42")
    }

    @Test
    func `a user function is registered by name`() throws {
        let upper = Message.Handler { input, errors in
            guard let text = input.operand?.value?.text else {
                errors.append(.badOperand(input.name))
                return nil
            }
            let result = text.uppercased()
            return Message.Resolved(value: .string(result), function: input.name, format: { _ in .string(result) })
        }
        let functions = Message.Functions.default.adding("ns:upper", upper)
        let message = try Message(parsing: "Hello {$name :ns:upper}!")
        let output = message.format(["name": "world"], in: .en, functions: functions, isolation: .disabled)
        #expect(output.text == "Hello WORLD!")
        #expect(output.errors.isEmpty)
        #expect(message.format(["name": "world"], in: .en, isolation: .disabled).errors == [.unknownFunction("ns:upper")])
    }

    @Test
    func `placeholders are isolated by the default bidi strategy`() throws {
        let message = try Message(parsing: "{$name} has {$count :number} apps")
        #expect(message(["name": "Ada", "count": 3], in: .en) == "\u{2068}Ada\u{2069} has 3 apps")
        #expect(message(["name": "Ada", "count": 3], in: .ar) == "\u{2068}Ada\u{2069} has \u{2067}3\u{2069} apps")
        #expect(message.format(["name": "Ada", "count": 3], in: .ar, isolation: .disabled).text == "Ada has 3 apps")
    }

    @Test
    func `formatting to parts keeps markup and numbers apart`() throws {
        let message = try Message(parsing: "{#b}{$n :number}{/b} items")
        let output = message.format(["n": 1200], in: .en, isolation: .disabled)
        #expect(
            output.parts == [
                .markup(.open, "b", options: [:], id: nil),
                .value(.number([.integer("1"), .group(","), .integer("200")]), direction: .leftToRight, id: nil),
                .markup(.close, "b", options: [:], id: nil),
                .text(" items"),
            ]
        )
        #expect(output.text == "1,200 items")
    }
}

extension `Message Tests`.Test.`Edge Case` {

    @Test
    func `syntax errors carry the offset where parsing stopped`() {
        #expect(throws: Message.Error.syntax(1)) { try Message(parsing: "{") }
        #expect(throws: Message.Error.syntax(6)) { try Message(parsing: "hello }") }
        #expect(throws: Message.Error.syntax(6)) { try Message(parsing: ".local$x = {1} {{}}") }
    }

    @Test
    func `data model errors name what is wrong`() {
        #expect(throws: Message.Error.duplicateDeclaration("x")) {
            try Message(parsing: ".input {$x} .local $x = {1} {{}}")
        }
        #expect(throws: Message.Error.duplicateOptionName("a")) {
            try Message(parsing: "{1 :number a=1 a=2}")
        }
        #expect(throws: Message.Error.missingSelectorAnnotation("x")) {
            try Message(parsing: ".input {$x} .match $x * {{}}")
        }
        #expect(throws: Message.Error.missingFallbackVariant) {
            try Message(parsing: ".input {$x :string} .match $x a {{}}")
        }
        #expect(throws: Message.Error.variantKeyMismatch) {
            try Message(parsing: ".input {$x :string} .match $x a b {{}} * {{}}")
        }
        #expect(throws: Message.Error.duplicateVariant) {
            try Message(parsing: ".input {$x :string} .match $x a {{}} |a| {{}} * {{}}")
        }
    }

    @Test
    func `formatting never fails and reports what fell back`() throws {
        let message = try Message(parsing: "Hi {$name}, {$n :number}")
        let output = message.format([:], in: .en, isolation: .disabled)
        #expect(output.text == "Hi {$name}, {$n}")
        #expect(output.errors == [.unresolvedVariable("name"), .unresolvedVariable("n"), .badOperand("number")])
    }

    @Test
    func `attributes have no effect`() throws {
        let plain = try Message(parsing: "{1 :number}")
        let attributed = try Message(parsing: "{1 :number @translate=no @note}")
        #expect(plain.format(in: .en).parts == attributed.format(in: .en).parts)
    }

    @Test
    func `an invalid message literal stops the program`() async {
        await #expect(processExitsWith: .failure) {
            let message: Message = "{"
            _ = message
        }
    }

    @Test
    func `declarations resolve when first used and at most once`() throws {
        let counting = Message.Handler { input, errors in
            errors.append(.unsupportedOperation(input.name))
            return Message.Resolved(value: .string("x"), function: input.name, format: { _ in .string("x") })
        }
        let functions = Message.Functions.default.adding("ns:count", counting)
        let used = try Message(parsing: ".local $x = {1 :ns:count} {{{$x}{$x}}}")
        #expect(used.format(in: .en, functions: functions, isolation: .disabled).errors == [.unsupportedOperation("ns:count")])
        let unused = try Message(parsing: ".local $x = {1 :ns:missing} {{hi}}")
        #expect(unused.format(in: .en).errors.isEmpty)
    }

    @Test
    func `the conformance suites hold 416 tests`() throws {
        #expect(try Conformance.total() == 416)
    }
}
