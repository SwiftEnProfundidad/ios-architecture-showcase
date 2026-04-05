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
                ? ShowcaseScreenPalette.screenDarkGradient
                : ShowcaseScreenPalette.screenLightGradient,
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
