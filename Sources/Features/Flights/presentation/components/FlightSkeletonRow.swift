import SharedKernel
import SwiftUI

struct FlightSkeletonRow: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: ShowcaseLayout.Space.md) {
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.badge)
                    .fill(.primary.opacity(0.16))
                    .frame(width: ShowcaseLayout.Skeleton.ListRow.primaryLineWidth, height: ShowcaseLayout.Skeleton.ListRow.primaryLineHeight)
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.badge)
                    .fill(.primary.opacity(0.10))
                    .frame(width: ShowcaseLayout.Skeleton.ListRow.secondaryLineWidth, height: ShowcaseLayout.Skeleton.ListRow.secondaryLineHeight)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: ShowcaseLayout.Space.md) {
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.badge)
                    .fill(.primary.opacity(0.16))
                    .frame(width: ShowcaseLayout.Skeleton.ListRow.trailingShortWidth, height: ShowcaseLayout.Skeleton.ListRow.trailingShortHeight)
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.pill)
                    .fill(.primary.opacity(0.10))
                    .frame(width: ShowcaseLayout.Skeleton.ListRow.pillWidth, height: ShowcaseLayout.Skeleton.ListRow.pillHeight)
            }
        }
        .padding(ShowcaseLayout.Inset.row)
        .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.row))
        .overlay {
            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.row)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: ShowcaseLayout.Line.stroke)
        }
        .overlay {
            SkeletonShimmer()
                .clipShape(.rect(cornerRadius: ShowcaseLayout.Radius.row))
        }
        .redacted(reason: .placeholder)
    }
}
