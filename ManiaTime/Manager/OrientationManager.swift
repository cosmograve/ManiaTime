import UIKit
import Combine

@MainActor
final class OrientationManager {

    static let shared = OrientationManager()

    private(set) var mask: UIInterfaceOrientationMask = [.landscapeLeft, .landscapeRight]

    private init() {}

    func forceLandscape() {
        mask = [.landscapeLeft, .landscapeRight]

        if #available(iOS 16.0, *) {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}

