import SwiftUI
import UIKit

/// A transparent UIKit pan gesture layer that reliably coexists with a
/// parent ScrollView's own scroll gesture — SwiftUI's .simultaneousGesture
/// doesn't always negotiate this correctly, so we drop to UIKit for it.
struct SwipeGestureView: UIViewRepresentable {
    var onChanged: (CGFloat) -> Void
    var onEnded: (CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onChanged: (CGFloat) -> Void
        let onEnded: (CGFloat) -> Void

        init(onChanged: @escaping (CGFloat) -> Void, onEnded: @escaping (CGFloat) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            switch gesture.state {
            case .changed:
                onChanged(translation.x)
            case .ended, .cancelled, .failed:
                onEnded(translation.x)
            default:
                break
            }
        }

        // This is the key permission SwiftUI's API doesn't reliably grant:
        // explicitly tell UIKit our gesture and the ScrollView's gesture
        // can both recognize the same touch simultaneously.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        // Only actually begin our gesture if the motion is clearly
        // horizontal — vertical motion is left entirely to the ScrollView.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}
