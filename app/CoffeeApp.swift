import SwiftUI
import AppKit
import Combine

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}

class IconCache {
    static let shared = IconCache()
    let activeIcon: NSImage
    let inactiveIcon: NSImage
    
    init() {
        let size = NSSize(width: 20, height: 20)
        if let img = NSImage(named: "Coffee Icon.png") {
            self.activeIcon = img.resized(to: size)
        } else {
            self.activeIcon = NSImage()
        }
        
        if let img = NSImage(named: "8Icon-iOS-Dark-1024x1024@1x.png") {
            self.inactiveIcon = img.resized(to: size)
        } else {
            self.inactiveIcon = NSImage()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = UpdaterManager.shared // Start Sparkle securely
        
        setupPopover()
        
        let isMenuBarMode = UserDefaults.standard.bool(forKey: "isMenuBarMode")
        if isMenuBarMode {
            enableMenuBarMode()
        }
        
        // Observe UserDefaults for changes to isMenuBarMode
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        
        // Observe SleepManager to update icon
        SleepManager.shared.$isPreventingSleep
            .receive(on: RunLoop.main)
            .sink { [weak self] isPreventing in
                self?.updateIcon(isPreventing: isPreventing)
            }
            .store(in: &cancellables)
    }
    
    @objc func defaultsChanged() {
        let isMenuBarMode = UserDefaults.standard.bool(forKey: "isMenuBarMode")
        if isMenuBarMode && statusItem == nil {
            enableMenuBarMode()
        } else if !isMenuBarMode && statusItem != nil {
            disableMenuBarMode()
        }
    }
    
    func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 350)
        popover.behavior = .transient
        // Use the shared SleepManager instance
        popover.contentViewController = NSHostingController(rootView: ContentView().environmentObject(SleepManager.shared))
        self.popover = popover
    }
    
    func enableMenuBarMode() {
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Safely close the main window
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                if window.identifier?.rawValue == "main" {
                    window.close()
                }
            }
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            updateIcon(isPreventing: SleepManager.shared.isPreventingSleep)
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    func disableMenuBarMode() {
        if popover?.isShown == true {
            popover?.close()
        }
        
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(sender)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                // Explicitly bringing the popover window to front without activating the whole SwiftUI app lifecycle
                popover?.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    func updateIcon(isPreventing: Bool) {
        statusItem?.button?.image = isPreventing ? IconCache.shared.activeIcon : IconCache.shared.inactiveIcon
    }
}

@main
struct CoffeeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(SleepManager.shared)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
        }
    }
}
