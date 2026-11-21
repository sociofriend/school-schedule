import SwiftUI
import UIKit

/// iOS has no Armenian system strings, so "Back", "Edit" and the search "Cancel" would show in English.
/// These replace them with Armenian controls.
extension View {
    /// Armenian back button for pushed screens; the swipe-back gesture keeps working (see `SwipeBackEnabler`).
    func armenianBackButton() -> some View { modifier(ArmenianBackButton()) }
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
