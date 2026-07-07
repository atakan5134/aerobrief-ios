import SwiftUI

@main
struct AeroBriefAIApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootFlowView()
                .environmentObject(settings)
        }
    }
}
