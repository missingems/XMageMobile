import SwiftUI

extension Font {
    static func cardTitle(fixedSize size: Double) -> Font {
        .custom("Planewalker-Bold", fixedSize: size)
    }

    static func cardTitle(size: Double, relativeTo style: Font.TextStyle) -> Font {
        .custom("Planewalker-Bold", size: size, relativeTo: style)
    }
}
