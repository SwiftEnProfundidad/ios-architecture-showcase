#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

public struct QRCodeView: UIViewRepresentable {
    public let payload: String

    public init(payload: String) {
        self.payload = payload
    }

    public func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityLabel = payload
        return imageView
    }

    public func updateUIView(_ imageView: UIImageView, context: Context) {
        imageView.image = generateQRCode(from: payload)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
#endif

#if canImport(SwiftUI) && !canImport(UIKit)
import SwiftUI

public struct QRCodeView: View {
    public let payload: String

    public init(payload: String) {
        self.payload = payload
    }

    public var body: some View {
        Image(systemName: "qrcode")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.primary)
            .accessibilityLabel(payload)
    }
}
#endif
