import UIKit

struct ImageHelper {
    /// Reduces the image to at most `maxDimension` on its longest side
    /// before sending it to MLX to avoid Jetsam (OOM) terminations.
    static func resizeForMLX(image: UIImage, maxDimension: CGFloat = 2048.0) -> UIImage {
        let size = image.size
        let largestSide = max(size.width, size.height)

        guard largestSide > maxDimension else { return image }

        let ratio = maxDimension / largestSide
        let newSize = CGSize(width: (size.width * ratio).rounded(),
                             height: (size.height * ratio).rounded())

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized ?? image
    }
}
