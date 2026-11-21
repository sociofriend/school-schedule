import SwiftUI
import UIKit

/// iOS has no Armenian system strings, so "Back", "Edit" and the search "Cancel" would show in English.
/// These replace them with Armenian controls.
extension View {
    /// Armenian back button for pushed screens; the swipe-back gesture keeps working.
    func armenianBackButton() -> some View { modifier(ArmenianBackButton()) }
}

private struct ArmenianBackButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden()
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

/// Keeps swipe-back working when the system back button is hidden.
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
