import SwiftUI

struct SkeletonShimmer: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 1.25) / 1.25
                let width = geometry.size.width
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: max(width * 0.35, 80))
                .rotationEffect(.degrees(18))
                .offset(x: (phase * width * 1.8) - width * 0.7)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
