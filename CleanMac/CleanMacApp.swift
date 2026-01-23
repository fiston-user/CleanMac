import SwiftUI

@main
struct CleanMacApp: App {
    @StateObject private var appManager = AppManager()
    @StateObject private var systemMonitor = SystemMonitor()
    @StateObject private var menuBarController: MenuBarController
    
    init() {
        let monitor = SystemMonitor()
        _systemMonitor = StateObject(wrappedValue: monitor)
        _menuBarController = StateObject(wrappedValue: MenuBarController(systemMonitor: monitor))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appManager)
                .environmentObject(systemMonitor)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
