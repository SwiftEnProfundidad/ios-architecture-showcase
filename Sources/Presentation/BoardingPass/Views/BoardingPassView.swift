#if canImport(SwiftUI)
import SwiftUI
import BoardingPass

public struct BoardingPassView: View {
    @Bindable var viewModel: BoardingPassViewModel

    public init(viewModel: BoardingPassViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .accessibilityLabel(String(localized: "boardingpass.loading"))
            } else if let pass = viewModel.boardingPass {
                passContent(pass)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    String(localized: "boardingpass.error.title"),
                    systemImage: "ticket.slash",
                    description: Text(error)
                )
            }
        }
        .navigationTitle(String(localized: "boardingpass.navigationTitle"))
        .task {
            await viewModel.load()
        }
    }

    private func passContent(_ pass: BoardingPassData) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                passHeader(pass)
                QRCodeView(payload: pass.qrPayload)
                    .frame(width: 200, height: 200)
                    .accessibilityLabel(String(localized: "boardingpass.qr.accessibility"))
                passDetails(pass)
            }
            .padding()
        }
    }

    private func passHeader(_ pass: BoardingPassData) -> some View {
        VStack(spacing: 8) {
            Text(pass.passengerName)
                .font(.title2.bold())
            Text(pass.flightID.value)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private func passDetails(_ pass: BoardingPassData) -> some View {
        VStack(spacing: 12) {
            detailRow(
                label: String(localized: "boardingpass.seat"),
                value: pass.seat,
                icon: "chair"
            )
            detailRow(
                label: String(localized: "boardingpass.gate"),
                value: pass.gate,
                icon: "door.right.hand.open"
            )
            detailRow(
                label: String(localized: "boardingpass.boardingDeadline"),
                value: pass.boardingDeadline,
                icon: "clock.badge.exclamationmark"
            )
        }
    }

    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}
#endif
