import AppKit
import SwiftUI
import Combine

@MainActor
class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    
    let systemMonitor: SystemMonitor
    
    init(systemMonitor: SystemMonitor) {
        self.systemMonitor = systemMonitor
        setupStatusItem()
        setupPopover()
        observeDiskUsage()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "internaldrive", accessibilityDescription: "CleanMac")
            button.imagePosition = .imageLeft
            updateStatusItemTitle()
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 380)
        popover?.behavior = .transient
        popover?.animates = true
        
        let menuBarView = MenuBarView(
            systemMonitor: systemMonitor,
            onEmptyTrash: { [weak self] in
                self?.emptyTrash()
            },
            onOpenApp: { [weak self] in
                self?.openMainApp()
            }
        )
        
        popover?.contentViewController = NSHostingController(rootView: menuBarView)
    }
    
    private func observeDiskUsage() {
        systemMonitor.$diskUsage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemTitle()
            }
            .store(in: &cancellables)
    }
    
    private func updateStatusItemTitle() {
        let percentage = Int(systemMonitor.diskUsage.usedPercentage)
        statusItem?.button?.title = " \(percentage)%"
    }
    
    @objc private func togglePopover() {
        if let popover = popover, let button = statusItem?.button {
            if popover.isShown {
                closePopover()
            } else {
                systemMonitor.updateStats()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                setupEventMonitor()
            }
        }
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }
    
    private func closePopover() {
        popover?.performClose(nil)
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
    
    private func emptyTrash() {
        closePopover()
        
        let script = """
        tell application "Finder"
            empty trash
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            systemMonitor.updateStats()
        }
    }
    
    private func openMainApp() {
        closePopover()
        NSApp.activate(ignoringOtherApps: true)
        
        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            for window in NSApp.windows {
                if !window.title.isEmpty || window.contentViewController != nil {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
    }
}
