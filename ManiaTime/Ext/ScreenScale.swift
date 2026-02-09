import SwiftUI

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

struct ScreenScale {
    let s: CGFloat

    init(size: CGSize, reference: CGSize = CGSize(width: 390, height: 844)) {
        let w = size.width / reference.width
        let h = size.height / reference.height
        self.s = min(w, h).clamped(to: 0.85...1.35)
    }

    func v(_ value: CGFloat) -> CGFloat { value * s }
}
