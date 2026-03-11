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

public func trackForMemoryLeaks(
    _ instance: AnyObject,
    token: MemoryLeakToken,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    token.register(WeakBox(instance, sourceLocation: sourceLocation))
}
