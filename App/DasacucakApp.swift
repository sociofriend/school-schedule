import SwiftUI

@main
struct DasacucakApp: App {
    @State private var environment = AppEnvironment()

    init() { ArmenianChrome.apply() }

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
                .environment(\.locale, .armenian)
        }
    }
}
