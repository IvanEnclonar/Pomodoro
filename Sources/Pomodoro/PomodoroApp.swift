import SwiftUI

// Intercepts window close to hide instead of destroy
@MainActor
class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()
    weak var mainWindow: NSWindow?
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil) // Hide instead of close
        return false         // Prevent actual close/destroy
    }
    
    func showWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

@main
struct PomodoroApp: App {
    @StateObject private var timerManager = TimerManager()

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    var body: some Scene {
        Window("Pomodoro", id: "main") {
            ContentView(timerManager: timerManager)
                .paperTheme()
                .onAppear {
                    // Capture the window and set our delegate
                    DispatchQueue.main.async {
                        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                            WindowDelegate.shared.mainWindow = window
                            window.delegate = WindowDelegate.shared
                        }
                    }
                    // Start remote sync if configured
                    if timerManager.remoteControlEnabled {
                        SupabaseSync.shared.start(timerManager: timerManager)
                    }
                }
                .onChange(of: timerManager.remoteControlEnabled) { _, enabled in
                    if enabled {
                        SupabaseSync.shared.start(timerManager: timerManager)
                    } else {
                        SupabaseSync.shared.stop()
                    }
                }
        }
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 600)
        
        #if os(macOS)
        Settings {
            SettingsView(timerManager: timerManager)
                .paperTheme()
        }
        
        MenuBarExtra {
            MenuBarPopover(timerManager: timerManager)
                .paperTheme()
        } label: {
            MenuBarLabel(timerManager: timerManager)
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}
