import SwiftUI

public struct ScreenBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public func body(content: Content) -> some View {
        content
            .background(gradient.ignoresSafeArea())
    }

    private var gradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.07, green: 0.10, blue: 0.18),
                    Color(red: 0.03, green: 0.04, blue: 0.08),
                    .black
                ]
                : [
                    Color(red: 0.93, green: 0.96, blue: 1.0),
                    Color(red: 0.98, green: 0.98, blue: 1.0),
                    .white
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackgroundModifier())
    }
}
