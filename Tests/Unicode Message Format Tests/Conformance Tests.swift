import RFC_8259
import Testing
import Unicode_Message_Format

enum `Conformance Tests` {}

extension `Conformance Tests` {
    @Suite struct Test {
        @Suite struct Unit {}
    }
}

extension `Conformance Tests`.Test.Unit {

    @Test(arguments: Conformance.suites.map { $0.name })
    func `every test of the CLDR 49 conformance suite passes`(name: String) throws {
        let json = try #require(Conformance.suites.first { $0.name == name }?.json)
        let root = try RFC_8259.Decode.parse([Byte](utf8: json))
        let defaults = root["defaultTestProperties"]?.object ?? RFC_8259.Object()
        let tests = try #require(root["tests"]?.array)
        var count = 0
        for test in tests {
            func property(_ key: String) -> RFC_8259.Value? {
                test[key] ?? defaults[key]
            }
            let source = try #require(property("src")?.string)
            let comment = Comment(rawValue: name + ": " + source)
            let expectedErrors = (property("expErrors")?.array.map { Array($0) } ?? []).compactMap { $0["type"]?.string }.sorted()
            count += 1
            let message: Message
            do throws(Message.Error) {
                message = try Message(parsing: source)
            } catch {
                #expect([Conformance.type(of: error)] == expectedErrors, comment)
                continue
            }
            var arguments: [String: Message.Value] = [:]
            for parameter in property("params")?.array.map({ Array($0) }) ?? [] {
                guard let parameterName = parameter["name"]?.string, let raw = parameter["value"],
                    let value = try Conformance.value(raw)
                else {
                    continue
                }
                arguments[parameterName] = value
            }
            let locale = try BCP47.LanguageTag(property("locale")?.string ?? "en-US")
            let isolation: Message.Isolation = property("bidiIsolation")?.string == "default" ? .default : .disabled
            let output = message.format(arguments, in: locale, functions: Conformance.functions, isolation: isolation)
            if let expected = property("exp")?.string {
                #expect(output.text == expected, comment)
            }
            #expect(output.errors.map(Conformance.type(of:)).sorted() == expectedErrors, comment)
            if let parts = property("expParts")?.array.map({ Array($0) }) {
                let actual = output.parts.map(Conformance.fields(of:))
                #expect(actual.count == parts.count, comment)
                for (expected, found) in zip(parts.map(Conformance.expected), actual) {
                    #expect(expected.allSatisfy { found[$0.key] == $0.value }, comment)
                }
            }
        }
        #expect(count == tests.count)
    }

    @Test
    func `the conformance data carries the Unicode License v3 notice`() {
        #expect(Conformance.license.contains("COPYRIGHT AND PERMISSION NOTICE"))
        #expect(Conformance.license.contains("Unicode, Inc."))
    }
}
