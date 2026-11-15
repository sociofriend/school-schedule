import SwiftUI
import UIKit

/// SwiftUI wrapper over the system `UICalendarView` with dot decorations.
struct MonthCalendarView: UIViewRepresentable {
    @Binding var selection: Date
    let markedDays: Set<DateComponents>

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = .current
        view.fontDesign = .rounded
        view.delegate = context.coordinator
        let selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        selectionBehavior.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: selection)
        view.selectionBehavior = selectionBehavior
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UICalendarView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        guard coordinator.markedDays != markedDays else { return }
        let changed = Array(coordinator.markedDays.symmetricDifference(markedDays))
        coordinator.markedDays = markedDays
        view.reloadDecorations(forDateComponents: changed, animated: true)
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: MonthCalendarView
        var markedDays: Set<DateComponents>

        init(parent: MonthCalendarView) {
            self.parent = parent
            self.markedDays = parent.markedDays
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let key = DateComponents(year: dateComponents.year, month: dateComponents.month, day: dateComponents.day)
            return markedDays.contains(key) ? .default(color: .tintColor, size: .small) : nil
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents, let date = Calendar.current.date(from: dateComponents) else { return }
            parent.selection = date
        }
    }
}
