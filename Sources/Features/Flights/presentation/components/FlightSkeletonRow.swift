import SwiftUI

struct FlightSkeletonRow: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.primary.opacity(0.16))
                    .frame(width: 78, height: 16)
                RoundedRectangle(cornerRadius: 6)
                    .fill(.primary.opacity(0.10))
                    .frame(width: 120, height: 12)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.primary.opacity(0.16))
                    .frame(width: 48, height: 14)
                RoundedRectangle(cornerRadius: 999)
                    .fill(.primary.opacity(0.10))
                    .frame(width: 72, height: 22)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: 1)
        }
        .overlay {
            SkeletonShimmer()
                .clipShape(.rect(cornerRadius: 20))
        }
        .redacted(reason: .placeholder)
    }
}
