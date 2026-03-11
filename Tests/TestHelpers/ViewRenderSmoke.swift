import CoreGraphics
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

enum ViewRenderSmokeError: Error {
    case missingImage
    case encodingFailed
}

@MainActor
func renderedPNG<Content: View>(
    from view: Content,
    size: CGSize = CGSize(width: 390, height: 844),
    colorScheme: ColorScheme = .light
) throws -> Data {
    let content = view
        .environment(\.colorScheme, colorScheme)
        .frame(width: size.width, height: size.height)

    let renderer = ImageRenderer(content: content)
    renderer.scale = 2
    renderer.proposedSize = ProposedViewSize(size)

    guard let cgImage = renderer.cgImage else {
        throw ViewRenderSmokeError.missingImage
    }

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        data,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw ViewRenderSmokeError.encodingFailed
    }

    CGImageDestinationAddImage(destination, cgImage, nil)

    guard CGImageDestinationFinalize(destination) else {
        throw ViewRenderSmokeError.encodingFailed
    }

    return data as Data
}
