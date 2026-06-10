import SwiftUI
import ServiceManagement

struct ContentView: View {
    @EnvironmentObject var sleepManager: SleepManager
    @AppStorage("activateOnLaunch") private var activateOnLaunch = false
    @AppStorage("isMenuBarMode") private var isMenuBarMode = false
    @Environment(\.openSettings) var openSettings
    @State private var showInlineSettings = false
    @StateObject private var updaterManager = UpdaterManager.shared
    
    // Timer options in seconds
    let timerOptions: [TimeInterval] = [
        0, // Indefinite
        15 * 60, // 15 mins
        30 * 60, // 30 mins
        60 * 60, // 1 hour
        2 * 60 * 60 // 2 hours
    ]
    
    var body: some View {
        VStack {
            if updaterManager.isDownloadingUpdate {
                VStack(spacing: 20) {
                    ProgressView("Downloading Update...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    
                    Text("Coffee is updating.\\nPlease wait, this cannot be cancelled.")
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if showInlineSettings {
                inlineSettingsView
            } else {
                mainContentView
            }
        }
        .padding(25)
        .frame(width: 280, height: 350)
        .onAppear {
            if activateOnLaunch {
                sleepManager.isPreventingSleep = true
            }
        }
    }
    
    var mainContentView: some View {
        VStack(spacing: 15) {
            // Header with Settings Button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        showInlineSettings = true
                    }
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Open Settings")
            }
            .padding(.top, -10)
            .padding(.trailing, -10)
            
            // Icon & Title
            VStack(spacing: 8) {
                Image(nsImage: NSImage(named: sleepManager.isPreventingSleep ? "Coffee Icon.png" : "8Icon-iOS-Dark-1024x1024@1x.png") ?? NSImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .animation(.easeInOut, value: sleepManager.isPreventingSleep)
                
                Text("Coffee")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(sleepManager.isPreventingSleep ? "Your Mac is awake." : "Your Mac can sleep.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Main Toggle
            Toggle("", isOn: $sleepManager.isPreventingSleep)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
                .scaleEffect(1.5)
                .padding(.vertical, 10)
            
            // Timer Picker
            HStack {
                Text("Duration:")
                Spacer()
                Picker("", selection: $sleepManager.selectedTimerInterval) {
                    ForEach(timerOptions, id: \.self) { duration in
                        Text(formatDuration(duration)).tag(duration)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 110)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
        }
    }
    
    var inlineSettingsView: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    withAnimation {
                        showInlineSettings = false
                    }
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.accentColor)
                
                Spacer()
            }
            
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                Picker("App Mode:", selection: $isMenuBarMode) {
                    Text("Window").tag(false)
                    Text("Menu Bar").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 10)
                
                Toggle("Launch at Login", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "launchAtLogin") },
                    set: { newValue in
                        UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
                        updateLaunchAtLogin(enabled: newValue)
                    }
                ))
                Toggle("Activate on Launch", isOn: $activateOnLaunch)
            }
            
            Spacer()
        }
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Failed to update launch at login status: \(error)")
                UserDefaults.standard.set(SMAppService.mainApp.status == .enabled, forKey: "launchAtLogin")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration == 0 {
            return "Indefinite"
        }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SleepManager())
    }
}
