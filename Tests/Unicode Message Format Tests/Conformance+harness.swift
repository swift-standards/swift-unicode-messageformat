import RFC_8259
import Unicode_Message_Format

extension Conformance {

    static let suites: [(name: String, json: String)] = [
        ("syntax", Conformance.syntax),
        ("syntax-errors", Conformance.syntaxErrors),
        ("data-model-errors", Conformance.dataModelErrors),
        ("fallback", Conformance.fallback),
        ("pattern-selection", Conformance.patternSelection),
        ("bidi", Conformance.bidi),
        ("u-options", Conformance.uOptions),
        ("functions/string", Conformance.string),
        ("functions/number", Conformance.number),
        ("functions/integer", Conformance.integer),
        ("functions/offset", Conformance.offset),
    ]

    static func type(of error: Message.Error) -> String {
        switch error {
        case .syntax: "syntax-error"
        case .variantKeyMismatch: "variant-key-mismatch"
        case .missingFallbackVariant: "missing-fallback-variant"
        case .missingSelectorAnnotation: "missing-selector-annotation"
        case .duplicateDeclaration: "duplicate-declaration"
        case .duplicateOptionName: "duplicate-option-name"
        case .duplicateVariant: "duplicate-variant"
        case .unresolvedVariable: "unresolved-variable"
        case .unknownFunction: "unknown-function"
        case .badSelector: "bad-selector"
        case .badOperand: "bad-operand"
        case .badOption: "bad-option"
        case .badVariantKey: "bad-variant-key"
        case .unsupportedOperation: "unsupported-operation"
        case .notFormattable: "not-formattable"
        }
    }

    static func fields(of part: Message.Part) -> [String: String] {
        switch part {
        case .text(let text):
            return ["type": "text", "value": text]

        case .value(let formatted, let direction, let id):
            var fields: [String: String]
            switch formatted {
            case .string(let text):
                fields = ["type": "string", "value": text]

            case .number(let parts):
                fields = ["type": "number", "value": formatted.text, "parts": parts.map(numberField).joined(separator: "|")]
            }
            if let direction {
                fields["dir"] = direction == .leftToRight ? "ltr" : "rtl"
            }
            if let id {
                fields["id"] = id
            }
            return fields

        case .markup(let kind, let name, let options, let id):
            var fields = ["type": "markup", "kind": "\(kind)", "name": name]
            if !options.isEmpty {
                fields["options"] = options.sorted { $0.key < $1.key }.map { $0.key + "=" + $0.value }.joined(separator: ";")
            }
            if let id {
                fields["id"] = id
            }
            return fields

        case .fallback(let source):
            return ["type": "fallback", "source": source]

        case .isolation(let scalar):
            return ["type": "bidiIsolation", "value": String(scalar)]
        }
    }

    static func numberField(_ part: CLDR.Number.Part) -> String {
        switch part {
        case .integer(let text): "integer:" + text
        case .group(let text): "group:" + text
        case .decimal(let text): "decimal:" + text
        case .fraction(let text): "fraction:" + text
        case .minusSign(let text): "minusSign:" + text
        case .plusSign(let text): "plusSign:" + text
        case .literal(let text): "literal:" + text
        case .infinity(let text): "infinity:" + text
        case .nan(let text): "nan:" + text
        }
    }

    static func expected(_ part: RFC_8259.Value) -> [String: String] {
        var fields: [String: String] = [:]
        for (key, value) in part.object ?? RFC_8259.Object() where key != "locale" {
            switch key {
            case "parts":
                let parts = value.array.map { Array($0) } ?? []
                fields[key] = parts.map { ($0["type"]?.string ?? "") + ":" + ($0["value"]?.string ?? "") }.joined(separator: "|")

            case "options":
                let options = value.object.map { Array($0) } ?? []
                fields[key] = options.sorted { $0.key < $1.key }.map { $0.key + "=" + ($0.value.string ?? "") }.joined(separator: ";")

            default:
                fields[key] = value.string ?? value.description
            }
        }
        return fields
    }

    static func value(_ json: RFC_8259.Value) throws(CLDR.Number.Decimal.Error) -> Message.Value? {
        if let text = json.string {
            return .string(text)
        }
        if let number = json.number {
            return .number(try CLDR.Number.Decimal(number.description))
        }
        return nil
    }
}

extension Conformance {

    static func total() throws(RFC_8259.Error) -> Int {
        var total = 0
        for suite in suites {
            let root = try RFC_8259.Decode.parse([Byte](utf8: suite.json))
            total += root["tests"]?.array.map { Array($0).count } ?? 0
        }
        return total
    }
}
