import CoreImage
import CoreVideo

final class FrameEncoder {

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let colorSpace = CGColorSpaceCreateDeviceRGB()

    /// JPEG compression quality 0.0–1.0
    var jpegQuality: CGFloat = 0.5

    /// Downscale factor (0.5 = half resolution)
    var scaleFactor: CGFloat = 0.5

    /// Encodes a CVPixelBuffer to JPEG Data, downscaled by `scaleFactor`.
    func encode(_ pixelBuffer: CVPixelBuffer) -> Data? {
        var image = CIImage(cvPixelBuffer: pixelBuffer)

        if scaleFactor != 1.0 {
            image = image.transformed(by: CGAffineTransform(
                scaleX: scaleFactor,
                y: scaleFactor
            ))
        }

        return ciContext.jpegRepresentation(
            of: image,
            colorSpace: colorSpace,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: jpegQuality]
        )
    }
}
