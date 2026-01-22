import SwiftUI

@main
struct CleanMacApp: App {
    @StateObject private var appManager = AppManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
