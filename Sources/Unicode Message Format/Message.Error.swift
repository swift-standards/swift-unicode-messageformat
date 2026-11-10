public import Cardinal

extension Message {

    public enum Error: Swift::Error, Sendable, Hashable {
        case syntax(Cardinal)
        case variantKeyMismatch
        case missingFallbackVariant
        case missingSelectorAnnotation(String)
        case duplicateDeclaration(String)
        case duplicateOptionName(String)
        case duplicateVariant
        case unresolvedVariable(String)
        case unknownFunction(String)
        case badSelector(String)
        case badOperand(String)
        case badOption(String)
        case badVariantKey(String)
        case unsupportedOperation(String)
        case notFormattable(String)
    }
}
