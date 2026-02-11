import UIKit

@MainActor
final class OrientationManager {

    static let shared = OrientationManager()

    private(set) var mask: UIInterfaceOrientationMask = .portrait

    private init() {}

    func forceAll() {
        set(mask: .all, fallback: .portrait)
    }

    func forceLandscape() {
        set(mask: [.landscapeLeft, .landscapeRight], fallback: .landscapeRight)
    }

    private func set(mask: UIInterfaceOrientationMask, fallback: UIInterfaceOrientation) {
        self.mask = mask

        if #available(iOS 16.0, *) {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
            scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIDevice.current.setValue(fallback.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
