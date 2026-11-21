import SwiftUI
import UIKit

/// iOS has no Armenian system strings, so "Back", "Edit" and the search "Cancel" would show in English.
/// These replace them with Armenian controls.
extension View {
    /// Armenian back button for pushed screens; the swipe-back gesture keeps working (see `SwipeBackEnabler`).
    func armenianBackButton() -> some View { modifier(ArmenianBackButton()) }

    /// Dismisses the keyboard on scroll, on tapping outside text inputs, and via a "Պատրաստ է" keyboard button.
    func keyboardDismissable() -> some View { modifier(KeyboardDismissable()) }
}

extension UIApplication {
    /// Resigns the current first responder to dismiss the keyboard cleanly.
    static func dismissKeyboard() {
        shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct KeyboardDismissable: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
            .background(KeyboardTapDismisser().frame(width: 0, height: 0).accessibilityHidden(true))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Պատրաստ է") { UIApplication.dismissKeyboard() }
                        .fontWeight(.semibold)
                }
            }
    }
}

/// Non-interfering tap recognizer on the window that dismisses the keyboard when tapping outside text inputs.
private struct KeyboardTapDismisser: UIViewRepresentable {
    func makeUIView(context: Context) -> Probe { Probe() }
    func updateUIView(_ uiView: Probe, context: Context) {}

    final class Probe: UIView, UIGestureRecognizerDelegate {
        private weak var installedOn: UIView?
        private lazy var tap: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            return recognizer
        }()

        override func didMoveToWindow() {
            super.didMoveToWindow()
            installedOn?.removeGestureRecognizer(tap)
            guard let target = window else { installedOn = nil; return }
            target.addGestureRecognizer(tap)
            installedOn = target
        }

        deinit { installedOn?.removeGestureRecognizer(tap) }

        @objc private func handleTap() {
            window?.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var current = touch.view
            while let view = current {
                if view is UITextField || view is UITextView || view is UISearchBar || view is UIControl {
                    return false
                }
                current = view.superview
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}

private struct ArmenianBackButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden()
            .background(SwipeBackEnabler().frame(width: 0, height: 0).accessibilityHidden(true))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward").fontWeight(.semibold)
                            Text("Հետ")
                        }
                    }
                }
            }
    }
}

/// Armenian replacement for `EditButton`.
struct ArmenianEditButton: View {
    @Binding var editMode: EditMode

    var body: some View {
        Button(editMode.isEditing ? "Պատրաստ է" : "Խմբագրել") {
            withAnimation { editMode = editMode.isEditing ? .inactive : .active }
        }
        .fontWeight(editMode.isEditing ? .semibold : .regular)
    }
}

enum ArmenianChrome {
    /// UIKit-level labels SwiftUI does not expose. Call once at launch.
    static func apply() {
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = "Չեղարկել"
    }
}

/// Re-enables swipe-back on the enclosing navigation controller, which UIKit turns off when the back button is hidden.
/// Uses a shared delegate object rather than conforming `UINavigationController` to the protocol retroactively.
private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Probe { Probe() }
    func updateUIViewController(_ probe: Probe, context: Context) {}

    final class Probe: UIViewController {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.interactivePopGestureRecognizer?.delegate = SwipeBackDelegate.shared
        }
    }
}

private final class SwipeBackDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = SwipeBackDelegate()

    /// Only when there is a screen to go back to, so the root never half-pops.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var responder: UIResponder? = gestureRecognizer.view
        while let current = responder, !(current is UINavigationController) { responder = current.next }
        return ((responder as? UINavigationController)?.viewControllers.count ?? 0) > 1
    }
}
