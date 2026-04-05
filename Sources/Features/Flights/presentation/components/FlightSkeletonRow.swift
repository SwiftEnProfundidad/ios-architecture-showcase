import SharedKernel
import SwiftUI

struct FlightSkeletonRow: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: ShowcaseLayout.Space.md) {
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.badge)
                    .fill(.primary.opacity(0.16))
                    .frame(width: 78, height: 16)
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.badge)
                    .fill(.primary.opacity(0.10))
                    .frame(width: 120, height: 12)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: ShowcaseLayout.Space.md) {
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.badge)
                    .fill(.primary.opacity(0.16))
                    .frame(width: 48, height: 14)
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.pill)
                    .fill(.primary.opacity(0.10))
                    .frame(width: 72, height: 22)
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
