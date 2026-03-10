#if canImport(SwiftUI)
import SwiftUI

public struct FlightListView: View {
    @Bindable var viewModel: FlightListViewModel

    public init(viewModel: FlightListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .accessibilityLabel(String(localized: "flights.list.loading"))
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        String(localized: "flights.list.error.title"),
                        systemImage: "wifi.slash",
                        description: Text(error)
                    )
                } else {
                    flightList
                }
            }
            .navigationTitle(String(localized: "flights.list.navigationTitle"))
            .task {
                await viewModel.load()
            }
        }
    }

    private var flightList: some View {
        List(viewModel.flights, id: \.id.value) { flight in
            Button {
                Task { await viewModel.selectFlight(flight) }
            } label: {
                FlightRowView(flight: flight)
            }
            .accessibilityLabel(flightAccessibilityLabel(flight))
        }
    }

    private func flightAccessibilityLabel(_ flight: Flight) -> String {
        String(localized: "flights.row.accessibility \(flight.number) \(flight.origin) \(flight.destination) \(flight.status.rawValue)")
    }
}

private struct FlightRowView: View {
    let flight: Flight

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.number)
                    .font(.headline)
                Text("\(flight.origin) → \(flight.destination)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(flight.scheduledDeparture)
                    .font(.subheadline.monospacedDigit())
                statusBadge(flight.status)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: Flight.Status) -> some View {
        Text(status.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(.rect(cornerRadius: 6))
    }

    private func statusColor(_ status: Flight.Status) -> Color {
        switch status {
        case .onTime: .green
        case .boarding: .blue
        case .delayed: .orange
        case .departed: .gray
        case .cancelled: .red
        }
    }
}
#endif
