public struct Message: Sendable, Hashable {

    public let source: String

    public let declarations: [Declaration]

    public let body: Body
}
