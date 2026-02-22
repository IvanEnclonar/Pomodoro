import SwiftUI

// Intercepts window close to hide instead of destroy
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
    
    var body: some Scene {
        WindowGroup {
            ContentView(timerManager: timerManager)
                .onAppear {
                    // Capture the window and set our delegate
                    DispatchQueue.main.async {
                        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                            WindowDelegate.shared.mainWindow = window
                            window.delegate = WindowDelegate.shared
                        }
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        
        #if os(macOS)
        Settings {
            SettingsView(timerManager: timerManager)
        }
        
        MenuBarExtra {
            // Dropdown Menu Items
            Button("Show Window") {
                WindowDelegate.shared.showWindow()
            }
            .keyboardShortcut("o")
            
            Divider()
            
            Button(timerManager.timerState == .running ? "Pause Timer" : "Start Timer") {
                if timerManager.timerState == .running {
                    timerManager.pause()
                } else {
                    timerManager.start()
                }
            }
            .keyboardShortcut("s")
            
            Button("Skip Session") {
                timerManager.skip()
            }
            .keyboardShortcut("k")
            
            Divider()
            
            Button("Quit Pomodoro") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(timerManager.timeString)
                    .monospacedDigit()
            }
        }
        #endif
    }
}
