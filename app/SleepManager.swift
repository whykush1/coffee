import Foundation
import IOKit.pwr_mgt

class SleepManager: ObservableObject {
    static let shared = SleepManager()
    @Published var isPreventingSleep: Bool = false {
        didSet {
            if isPreventingSleep {
                enableAssertion()
            } else {
                disableAssertion()
            }
        }
    }
    
    @Published var selectedTimerInterval: TimeInterval = 0 { // 0 means indefinite
        didSet {
            // If timer changes while active, restart the timer
            if isPreventingSleep {
                scheduleTimer()
            }
        }
    }
    
    private var assertionID: IOPMAssertionID = 0
    private var sleepTimer: Timer?
    
    init() {}
    
    private func enableAssertion() {
        if assertionID != 0 {
            // Already active
            return
        }
        
        let reasonForActivity = "Coffee app is keeping the system awake" as CFString
        let success = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonForActivity,
            &assertionID
        )
        
        if success == kIOReturnSuccess {
            print("Successfully created power assertion with ID \(assertionID)")
            scheduleTimer()
        } else {
            print("Failed to create power assertion")
            // Revert state if failed
            DispatchQueue.main.async {
                self.isPreventingSleep = false
            }
        }
    }
    
    private func disableAssertion() {
        if assertionID != 0 {
            let success = IOPMAssertionRelease(assertionID)
            if success == kIOReturnSuccess {
                print("Successfully released power assertion with ID \(assertionID)")
            } else {
                print("Failed to release power assertion")
            }
            assertionID = 0
        }
        sleepTimer?.invalidate()
        sleepTimer = nil
    }
    
    private func scheduleTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        
        if selectedTimerInterval > 0 {
            sleepTimer = Timer.scheduledTimer(withTimeInterval: selectedTimerInterval, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isPreventingSleep = false
                }
            }
        }
    }
    
    deinit {
        disableAssertion()
    }
}
