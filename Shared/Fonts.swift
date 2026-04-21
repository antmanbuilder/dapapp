import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppFont {
    static func display(size: CGFloat) -> Font {
        #if canImport(UIKit)
        if let _ = UIFont(name: "BebasNeue-Regular", size: size) {
            return .custom("BebasNeue-Regular", size: size)
        }
        return .system(size: size, weight: .heavy, design: .rounded)
        #else
        return .custom("BebasNeue-Regular", size: size)
        #endif
    }
}
