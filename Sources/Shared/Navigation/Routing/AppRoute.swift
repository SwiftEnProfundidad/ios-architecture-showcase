
public enum AppRoute: Sendable, Equatable, Hashable {
    case primaryDetail(contextID: String)
    case secondaryAttachment(contextID: String)
}
