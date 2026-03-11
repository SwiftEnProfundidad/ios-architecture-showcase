import SharedKernel
import SwiftUI

public struct FlightListView<ListExecutor: ListFlightsExecuting, SessionController: FlightListSessionControlling>: View {
    @Bindable var viewModel: FlightListViewModel<ListExecutor, SessionController>
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: FlightListViewModel<ListExecutor, SessionController>) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            content
        }
        .navigationTitle(AppStrings.localized("flights.list.navigationTitle"))
        .toolbar {
            ToolbarItem {
                Button(AppStrings.localized("flights.list.logout")) {
                    Task { await viewModel.logout() }
                }
                .accessibilityLabel(AppStrings.localized("flights.list.logout.accessibility"))
            }
        }
        .task {
            if viewModel.flights.isEmpty {
                await viewModel.load()
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isShowingInitialSkeleton {
            skeletonList
        } else if viewModel.flights.isEmpty, let error = viewModel.errorMessage {
            ContentUnavailableView(
                AppStrings.localized("flights.list.error.title"),
                systemImage: "wifi.slash",
                description: Text(error)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        } else {
            flightList
        }
    }

    private var flightList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
            if let staleMessage = viewModel.staleMessage {
                bannerRow(
                    message: staleMessage,
                    icon: "exclamationmark.triangle.fill",
                    tint: .orange
                )
            }

            if let errorMessage = viewModel.errorMessage, viewModel.flights.isEmpty == false {
                bannerRow(
                    message: errorMessage,
                    icon: "wifi.slash",
                    tint: .red
                )
            }

            ForEach(viewModel.flights, id: \.id.value) { flight in
                Button {
                    Task { await viewModel.selectFlight(flight) }
                } label: {
                    FlightRowView(flight: flight)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .accessibilityLabel(flightAccessibilityLabel(flight))
            }

            if viewModel.canLoadMorePages || viewModel.isLoadingNextPage {
                paginationFooter
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .onAppear {
                        Task { await viewModel.loadNextPage() }
                    }
            }
        }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }

    private func flightAccessibilityLabel(_ flight: Flight) -> String {
        AppStrings.localized(
            "flights.row.accessibility",
            flight.number,
            flight.origin,
            flight.destination,
            localizedStatus(flight.status)
        )
    }

    private func localizedStatus(_ status: Flight.Status) -> String {
        switch status {
        case .onTime:
            AppStrings.localized("flights.status.onTime")
        case .delayed:
            AppStrings.localized("flights.status.delayed")
        case .boarding:
            AppStrings.localized("flights.status.boarding")
        case .departed:
            AppStrings.localized("flights.status.departed")
        case .cancelled:
            AppStrings.localized("flights.status.cancelled")
        }
    }

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<8, id: \.self) { _ in
                    FlightSkeletonRow()
                        .padding(.horizontal, 16)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .topLeading) {
            Text(AppStrings.localized("flights.list.loading"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func bannerRow(message: String, icon: String, tint: Color) -> some View {
        Label(message, systemImage: icon)
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(tint.opacity(colorScheme == .dark ? 0.35 : 0.18), lineWidth: 1)
            }
            .padding(.horizontal, 16)
            .accessibilityLabel(message)
    }

    @ViewBuilder
    private var paginationFooter: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingNextPage {
                ProgressView()
                    .accessibilityLabel(AppStrings.localized("flights.list.loadingMore"))
            } else {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var screenBackground: some View {
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

private struct FlightRowView: View {
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
                Text(flight.formattedScheduledDeparture())
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
        Text(localizedStatus(status))
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

    private func localizedStatus(_ status: Flight.Status) -> String {
        switch status {
        case .onTime:
            AppStrings.localized("flights.status.onTime")
        case .delayed:
            AppStrings.localized("flights.status.delayed")
        case .boarding:
            AppStrings.localized("flights.status.boarding")
        case .departed:
            AppStrings.localized("flights.status.departed")
        case .cancelled:
            AppStrings.localized("flights.status.cancelled")
        }
    }
}

private struct FlightSkeletonRow: View {
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

private struct SkeletonShimmer: View {
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
