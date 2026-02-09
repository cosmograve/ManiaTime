
import SwiftUI
import UIKit

enum AppFont {

    enum Family {
        static let Regular = "JustMeAgainDownHere"
    }

    enum Weight {
        case regular
    }

    static func regular(size: CGFloat, weight: Weight) -> Font {
        let name: String
        switch weight {
        case .regular: name = Family.Regular
        }

        return Font(uiFont: makeUIFont(name: name, size: size))
    }

    private static func makeUIFont(name: String, size: CGFloat) -> UIFont {
        if let custom = UIFont(name: name, size: size) {
            return custom
        }

        return UIFont.systemFont(ofSize: size, weight: .regular)
    }
}

extension Font {
    init(uiFont: UIFont) {
        self = Font(uiFont as CTFont)
    }
}

//Text("Hello")
//    .font(AppFont.poppins(size: 20, weight: .medium))
//
//Text("Subtitle")
//    .font(AppFont.poppins(size: 13, weight: .regular))
