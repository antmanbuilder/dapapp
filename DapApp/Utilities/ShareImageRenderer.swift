import SwiftUI
import UIKit

enum ShareImageRenderer {
    @MainActor
    static func renderCard(result: DapResult) -> UIImage? {
        let view = ShareCardView(result: result)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage
    }
}
