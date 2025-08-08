import Foundation
import SwiftFSM

// Speaker states
enum SpeakerStates: String, CaseIterable, Hashable {
    case off = "off"
    case on = "on"
}

// Speaker events
enum SpeakerEvents: String, CaseIterable, Hashable {
    case powerOn = "power_on"
    case powerOff = "power_off"
    case setVolume = "set_volume"
    case timeout = "timeout"
}

// Speaker class that uses FSM
class Speaker {
    private var volume: Int = 0
    
    // Lazy initialization of FSM
    private lazy var fsm: FSM<SpeakerStates, SpeakerEvents> = {
        // Create states
        let offState = State<SpeakerStates, SpeakerEvents>(verbose: true)
        offState.addHandler(eventType: .powerOn) { _ in
            Transition(toState: .on)
        }
        offState.addExitHook { _ in
            print("off_state exit hook: Powering up...")
        }
        
        let onState = State<SpeakerStates, SpeakerEvents>(timeout: 5, verbose: true)
        onState.addHandler(eventType: .powerOff) { _ in
            Transition(toState: .off)
        }
        onState.addHandler(eventType: .setVolume) { [weak self] event in
            if let volume = event.args.first as? Int {
                self?.setVolumeInternal(volume)
            }
            return nil
        }
        onState.addHandler(eventType: .timeout) { _ in
            print("on_state timeout handler: Powering down...")
            return Transition(toState: .off)
        }
        onState.addEnterHook { _ in
            print("on_state enter hook: Speaker is now active!")
        }
        onState.addExitHook { _ in
            print("on_state exit hook: Powering down...")
        }
        
        return FSM(
            initialState: .off,
            stateObjects: [
                .off: offState,
                .on: onState
            ],
            timeoutEvent: .timeout,
            verbose: true
        )
    }()
    
    init() {
        // FSM will be initialized lazily when first accessed
    }
    
    func powerOn() {
        fsm.handleEvent(Event(type: .powerOn))
    }
    
    func powerOff() {
        fsm.handleEvent(Event(type: .powerOff))
    }
    
    func setVolume(_ volume: Int) {
        fsm.handleEvent(Event(type: .setVolume, args: [volume]))
    }
    
    private func setVolumeInternal(_ volume: Int) {
        print("Setting volume (internal) to \(volume)")
        self.volume = volume
    }
    
    var state: SpeakerStates {
        return fsm.currentState
    }
    
    var currentVolume: Int {
        return volume
    }
}

// Example usage
func runSpeakerExample1() {
    print("=== Speaker Example 1 ===")
    let speaker = Speaker()
    
    // Test the FSM
    speaker.setVolume(10) // This should not be handled
    print("State: \(speaker.state.rawValue), Volume: \(speaker.currentVolume)")
    
    speaker.powerOn()
    print("State: \(speaker.state.rawValue), Volume: \(speaker.currentVolume)")
    
    speaker.setVolume(10)
    print("State: \(speaker.state.rawValue), Volume: \(speaker.currentVolume)")
    
    speaker.powerOff()
    print("State: \(speaker.state.rawValue), Volume: \(speaker.currentVolume)")
}

func runSpeakerExample2() {
    print("=== Speaker Example 2 ===")
    let speaker = Speaker()
    
    // Test the FSM with timeout
    speaker.powerOn()
    print("State: \(speaker.state.rawValue), Volume: \(speaker.currentVolume)")
    
    speaker.setVolume(10)
    print("State: \(speaker.state.rawValue), Volume: \(speaker.currentVolume)")
    
    // After 5 seconds, the speaker should power off automatically
    print("Waiting for timeout...")
    
    // Wait for timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
        print("State after timeout: \(speaker.state.rawValue), Volume: \(speaker.currentVolume)")
    }
    
    // Keep the program running for a bit to see the timeout
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 7.0))
}

// Main function to run examples
if CommandLine.arguments.count > 1 {
    let choice = CommandLine.arguments[1]
    switch choice {
    case "1":
        runSpeakerExample1()
    case "2":
        runSpeakerExample2()
    default:
        print("Invalid choice. Use 1 or 2.")
    }
} else {
    print("Running Speaker Example 1...")
    runSpeakerExample1()
    print("\nRunning Speaker Example 2...")
    runSpeakerExample2()
} 