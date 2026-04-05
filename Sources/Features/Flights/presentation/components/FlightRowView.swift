import SharedKernel
import SwiftUI

struct FlightRowView: View {
    let flight: Flight
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: ShowcaseLayout.Space.xs) {
                Text(flight.number)
                    .font(.headline)
                Text(AppStrings.localized("flights.route", flight.origin, flight.destination))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: ShowcaseLayout.Space.xs) {
                Text(OperationalTimeFormatter.hourMinute(
                    from: flight.scheduledDeparture,
                    timeZoneIdentifier: flight.departureTimeZoneIdentifier
                ))
                    .font(.subheadline.monospacedDigit())
                statusBadge(flight.status)
            }
        }
        .padding(ShowcaseLayout.Inset.row)
        .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.row))
        .overlay {
            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.row)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: ShowcaseLayout.Line.stroke)
        }
        .accessibilityElement(children: .combine)
    }

    private func statusBadge(_ status: Flight.Status) -> some View {
        let presentation = FlightStatusPresentation(status: status)

        return Text(presentation.title)
            .font(.caption.bold())
            .padding(.horizontal, ShowcaseLayout.Inset.badgeHorizontal)
            .padding(.vertical, ShowcaseLayout.Inset.badgeVertical)
            .background(presentation.tint.color.opacity(0.15))
            .foregroundStyle(presentation.tint.color)
            .clipShape(.rect(cornerRadius: ShowcaseLayout.Radius.badge))
    }
}
