import Testing
import Foundation

private final class WeakBox {
    weak var value: AnyObject?
    let typeName: String
    let sourceLocation: SourceLocation

    init(_ value: AnyObject, sourceLocation: SourceLocation) {
        self.value = value
        self.typeName = "\(type(of: value))"
        self.sourceLocation = sourceLocation
    }
}

public final class MemoryLeakToken {
    private var boxes: [WeakBox] = []
    private let lock = NSLock()

    public init() {}

    fileprivate func register(_ box: WeakBox) {
        lock.withLock { boxes.append(box) }
    }

    deinit {
        let snapshot = lock.withLock { boxes }
        for box in snapshot {
            #expect(
                box.value == nil,
                "Memory leak: \(box.typeName) was not deallocated",
                sourceLocation: box.sourceLocation
            )
        }
    }
}

private func registerMemoryLeaks(
    _ instances: AnyObject...,
    token: MemoryLeakToken,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for instance in instances {
        token.register(WeakBox(instance, sourceLocation: sourceLocation))
    }
}

public final class TrackedTestContext<Context> {
    public let context: Context
    private let leakAssertion: () -> Void

    public init(context: Context, leakAssertion: @escaping () -> Void) {
        self.context = context
        self.leakAssertion = leakAssertion
    }

    public func assertNoLeaks() {
    }

    deinit {
        leakAssertion()
    }
}

public func makeTrackedTestContext<Context>(
    _ context: Context,
    token: MemoryLeakToken
) -> TrackedTestContext<Context> {
    TrackedTestContext(
        context: context,
        leakAssertion: { withExtendedLifetime(token) {} }
    )
}

public func makeLeakTrackedTestContext<Context>(
    _ context: Context,
    trackedInstances: AnyObject...,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<Context> {
    makeLeakTrackedTestContext(
        context,
        trackedInstances: trackedInstances,
        sourceLocation: sourceLocation
    )
}

public func makeLeakTrackedTestContext<Context>(
    _ context: Context,
    trackedInstances: [AnyObject],
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<Context> {
    let token = MemoryLeakToken()
    for trackedInstance in trackedInstances {
        registerMemoryLeaks(trackedInstance, token: token, sourceLocation: sourceLocation)
    }
    return makeTrackedTestContext(context, token: token)
}

public func makeTestContext<Context>(
    _ context: Context
) -> TrackedTestContext<Context> {
    TrackedTestContext(context: context, leakAssertion: {})
}
