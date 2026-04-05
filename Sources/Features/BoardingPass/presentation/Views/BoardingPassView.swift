import SharedKernel
import SwiftUI

public struct BoardingPassView<UseCase: BoardingPassGetting>: View {
    @Bindable var viewModel: BoardingPassViewModel<UseCase>
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: BoardingPassViewModel<UseCase>) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Group {
                if viewModel.isLoading {
                    boardingPassSkeleton
                        .accessibilityLabel(AppStrings.localized("boardingpass.loading"))
                } else if let pass = viewModel.boardingPass {
                    passContent(pass)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        AppStrings.localized("boardingpass.error.title"),
                        systemImage: "ticket.slash",
                        description: Text(error)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24)
                }
            }
        }
        .screenBackground()
        .navigationTitle(AppStrings.localized("boardingpass.navigationTitle"))
        .task {
            await viewModel.load()
        }
    }

    private func passContent(_ pass: BoardingPassData) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                passHeader(pass)
                qrCard(pass)
                passDetails(pass)
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
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
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func passDetails(_ pass: BoardingPassData) -> some View {
        VStack(spacing: 12) {
            detailRow(
                label: AppStrings.localized("boardingpass.seat"),
                value: pass.seat,
                icon: "chair"
            )
            detailRow(
                label: AppStrings.localized("boardingpass.gate"),
                value: pass.gate,
                icon: "door.right.hand.open"
            )
            detailRow(
                label: AppStrings.localized("boardingpass.boardingDeadline"),
                value: OperationalTimeFormatter.hourMinute(
                    from: pass.boardingDeadline,
                    timeZoneIdentifier: pass.boardingTimeZoneIdentifier
                ),
                icon: "clock.badge.exclamationmark"
            )
        }
        .padding(20)
        .background(.thinMaterial, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: 1)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            AppStrings.localized("shared.accessibility.labelValue", label, value)
        )
    }

    private func qrCard(_ pass: BoardingPassData) -> some View {
        VStack(spacing: 16) {
            QRCodeView(payload: pass.qrPayload)
                .frame(width: 220, height: 220)
                .padding(18)
                .background(.white, in: .rect(cornerRadius: 20))
                .accessibilityLabel(AppStrings.localized("boardingpass.qr.accessibility"))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.thinMaterial, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: 1)
        }
    }

    private var boardingPassSkeleton: some View {
        ScrollView {
            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.thinMaterial)
                    .frame(height: 104)
                RoundedRectangle(cornerRadius: 24)
                    .fill(.thinMaterial)
                    .frame(height: 278)
                RoundedRectangle(cornerRadius: 24)
                    .fill(.thinMaterial)
                    .frame(height: 144)
            }
            .redacted(reason: .placeholder)
            .frame(maxWidth: 640)
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .accessibilityHidden(true)
        }
    }

}
