import CoreImage
import CoreImage.CIFilterBuiltins
import SharedKernel
import SwiftUI

public struct QRCodeView: View {
    public let payload: String

    public init(payload: String) {
        self.payload = payload
    }

    public var body: some View {
        Group {
            if let cgImage = generateQRCode(from: payload) {
                Image(decorative: cgImage, scale: 1, orientation: .up)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                ContentUnavailableView(
                    AppStrings.localized("boardingpass.error.title"),
                    systemImage: "qrcode.viewfinder",
                    description: Text(AppStrings.localized("boardingpass.error.load"))
                )
            }
        }
        .accessibilityHidden(true)
    }

    private func generateQRCode(from string: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        filter.message = data
        let context = CIContext()
        guard let outputImage = filter.outputImage else {
            return nil
        }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return context.createCGImage(scaled, from: scaled.extent)
    }
}
