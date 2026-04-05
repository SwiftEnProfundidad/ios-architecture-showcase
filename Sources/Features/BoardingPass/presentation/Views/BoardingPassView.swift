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
                    .padding(.horizontal, ShowcaseLayout.Inset.screenXWide)
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
            VStack(spacing: ShowcaseLayout.Space.hero) {
                passHeader(pass)
                qrCard(pass)
                passDetails(pass)
            }
            .frame(maxWidth: ShowcaseLayout.ContentWidth.detail)
            .padding(.horizontal, ShowcaseLayout.Inset.screenX)
            .padding(.vertical, ShowcaseLayout.Space.screen)
        }
    }

    private func passHeader(_ pass: BoardingPassData) -> some View {
        VStack(spacing: ShowcaseLayout.Space.sm) {
            Text(pass.passengerName)
                .font(.title2.bold())
            Text(pass.flightID.value)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(ShowcaseLayout.Inset.card)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.card)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: ShowcaseLayout.Line.stroke)
        }
        .accessibilityElement(children: .combine)
    }

    private func passDetails(_ pass: BoardingPassData) -> some View {
        VStack(spacing: ShowcaseLayout.Space.lg) {
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
        .padding(ShowcaseLayout.Inset.card)
        .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.card)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: ShowcaseLayout.Line.stroke)
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
        VStack(spacing: ShowcaseLayout.Inset.row) {
            QRCodeView(payload: pass.qrPayload)
                .frame(width: ShowcaseLayout.QR.side, height: ShowcaseLayout.QR.side)
                .padding(ShowcaseLayout.Inset.qrPadding)
                .background(.white, in: .rect(cornerRadius: ShowcaseLayout.Radius.qrCutout))
                .accessibilityLabel(AppStrings.localized("boardingpass.qr.accessibility"))
        }
        .frame(maxWidth: .infinity)
        .padding(ShowcaseLayout.Inset.card)
        .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.card)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: ShowcaseLayout.Line.stroke)
        }
    }

    private var boardingPassSkeleton: some View {
        ScrollView {
            VStack(spacing: ShowcaseLayout.Space.hero) {
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.card)
                    .fill(.thinMaterial)
                    .frame(height: ShowcaseLayout.Skeleton.BoardingPass.headerBlockHeight)
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.card)
                    .fill(.thinMaterial)
                    .frame(height: ShowcaseLayout.Skeleton.BoardingPass.qrBlockHeight)
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.card)
                    .fill(.thinMaterial)
                    .frame(height: ShowcaseLayout.Skeleton.BoardingPass.detailsBlockHeight)
            }
            .redacted(reason: .placeholder)
            .frame(maxWidth: ShowcaseLayout.ContentWidth.detail)
            .padding(.horizontal, ShowcaseLayout.Inset.screenX)
            .padding(.vertical, ShowcaseLayout.Space.screen)
            .accessibilityHidden(true)
        }
    }

}
