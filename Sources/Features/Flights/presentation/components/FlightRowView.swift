import SharedKernel
import SwiftUI

struct FlightRowView: View {
    let flight: Flight
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.number)
                    .font(.headline)
                Text(AppStrings.localized("flights.route", flight.origin, flight.destination))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(OperationalTimeFormatter.hourMinute(
                    from: flight.scheduledDeparture,
                    timeZoneIdentifier: flight.departureTimeZoneIdentifier
                ))
                    .font(.subheadline.monospacedDigit())
                statusBadge(flight.status)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func statusBadge(_ status: Flight.Status) -> some View {
        let presentation = FlightStatusPresentation(status: status)

        return Text(presentation.title)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(presentation.tint.color.opacity(0.15))
            .foregroundStyle(presentation.tint.color)
            .clipShape(.rect(cornerRadius: 6))
    }
}
