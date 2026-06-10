import Foundation
import Sparkle
import SwiftUI
import AppKit

class UpdaterManager: NSObject, ObservableObject, SPUUserDriver {
    static let shared = UpdaterManager()
    
    private var updater: SPUUpdater!
    @Published var isDownloadingUpdate = false
    @Published var downloadProgress: Double = 0.0
    
    override init() {
        super.init()
        let hostBundle = Bundle.main
        updater = SPUUpdater(hostBundle: hostBundle, applicationBundle: hostBundle, userDriver: self, delegate: nil)
        do {
            try updater.start()
            // Force an instant background check on launch!
            updater.checkForUpdatesInBackground()
        } catch {
            print("Failed to start Sparkle updater: \(error)")
        }
    }
    
    // MARK: - SPUUserDriver
    
    func show(_ request: SPUUpdatePermissionRequest, reply: @escaping (SUUpdatePermissionResponse) -> Void) {
        let response = SUUpdatePermissionResponse(automaticUpdateChecks: true, sendSystemProfile: false)
        reply(response)
    }
    
    func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) { }
    
    func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState, reply: @escaping (SPUUserUpdateChoice) -> Void) {
        DispatchQueue.main.async {
            self.isDownloadingUpdate = true
            NSApp.activate(ignoringOtherApps: true)
        }
        reply(.install)
    }
    
    func showUpdateReleaseNotes(with downloadData: SPUDownloadData) { }
    
    func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) { }
    
    func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
        acknowledgement()
    }
    
    func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.isDownloadingUpdate = false
        }
        acknowledgement()
    }
    
    func showDownloadInitiated(cancellation: @escaping () -> Void) { }
    
    func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) { }
    
    func showDownloadDidReceiveData(ofLength length: UInt64) { }
    
    func showDownloadDidStartExtractingUpdate() { }
    
    func showExtractionReceivedProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.downloadProgress = progress
        }
    }
    
    func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        reply(.install)
    }
    
    func showInstallingUpdate(withApplicationTerminated applicationTerminated: Bool, retryTerminatingApplication: @escaping () -> Void) { }
    
    func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {
        acknowledgement()
    }
    
    func showUpdateInFocus() { }
    
    func dismissUpdateInstallation() {
        DispatchQueue.main.async {
            self.isDownloadingUpdate = false
        }
    }
}
