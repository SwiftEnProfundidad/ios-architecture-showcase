import SharedKernel
import SwiftUI

struct SkeletonShimmer: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                let cycle = ShowcaseLayout.Skeleton.Shimmer.cycleDuration
                let phase = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: cycle) / cycle
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
                .frame(width: max(width * ShowcaseLayout.Skeleton.Shimmer.highlightWidthRatio, ShowcaseLayout.Skeleton.Shimmer.minHighlightWidth))
                .rotationEffect(.degrees(ShowcaseLayout.Skeleton.Shimmer.rotationDegrees))
                .offset(x: (phase * width * ShowcaseLayout.Skeleton.Shimmer.offsetPhaseMultiplier) - width * ShowcaseLayout.Skeleton.Shimmer.offsetBaseMultiplier)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
