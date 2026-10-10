import AppKit
import CoreAudio
import CoreMediaIO

/// Looks for things that should hold the break timer: a call (microphone or camera in use),
/// a deep focus app in front, or a macOS Focus. Asked once per tick.
@MainActor
enum SmartPauseMonitor {
    static func reason(for settings: TimerSettings) -> SmartPauseReason? {
        if settings.pauseForMeetings && (isMicrophoneInUse() || isCameraInUse()) {
            return .meeting
        }
        if settings.pauseForFocusApps,
           let front = NSWorkspace.shared.frontmostApplication,
           let app = settings.focusApps.first(where: { $0.bundleID == front.bundleIdentifier }) {
            return .focusApp(name: app.name)
        }
        if settings.pauseForFocusMode && isFocusModeOn {
            return .focusMode
        }
        return nil
    }

    // MARK: - Microphone (Core Audio)

    /// Any audio input device being used by any app. Reading this needs no permission.
    private static func isMicrophoneInUse() -> Bool {
        audioDevices().contains { device in
            hasInput(device) && audioFlag(device, kAudioDevicePropertyDeviceIsRunningSomewhere)
        }
    }

    private static func audioDevices() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var devices = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &devices) == noErr else { return [] }
        return devices
    }

    private static func hasInput(_ device: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr && size > 0
    }

    private static func audioFlag(_ device: AudioObjectID, _ selector: AudioObjectPropertySelector) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr && value != 0
    }

    // MARK: - Camera (CoreMediaIO)

    /// Any camera being used by any app. Reading this needs no permission.
    private static func isCameraInUse() -> Bool {
        var address = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        var size: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return false }
        var devices = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(system, &address, 0, nil, size, &used, &devices) == noErr else { return false }

        return devices.contains { device in
            var running = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
            )
            var value: UInt32 = 0
            var valueUsed: UInt32 = 0
            return CMIOObjectGetPropertyData(device, &running, 0, nil, UInt32(MemoryLayout<UInt32>.size), &valueUsed, &value) == noErr
                && value != 0
        }
    }

    // MARK: - Focus mode

    /// Set by Shortcuts automations opening `breakreminder://focus-on` and `breakreminder://focus-off`.
    /// macOS doesn't tell apps signed without a paid developer account whether a Focus is on, so the user
    /// sets up "When a Focus turns on/off → Open URL" in Shortcuts. Saved so it survives a restart.
    static var isFocusModeOn: Bool {
        get { UserDefaults.standard.bool(forKey: "focusModeOn") }
        set { UserDefaults.standard.set(newValue, forKey: "focusModeOn") }
    }

    /// Handles a `canopy://` (or older `breakreminder://`) link. Returns false if it isn't one we know.
    static func handle(_ url: URL) -> Bool {
        switch url.host {
        case "focus-on": isFocusModeOn = true
        case "focus-off": isFocusModeOn = false
        default: return false
        }
        return true
    }
}
