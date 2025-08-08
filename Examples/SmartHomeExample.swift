import Foundation
import SwiftFSM

// Smart Home states
enum SmartHomeStates: String, CaseIterable, Hashable {
    case idle = "idle"
    case morning = "morning"
    case evening = "evening"
    case away = "away"
    case party = "party"
    case sleep = "sleep"
}

// Smart Home events
enum SmartHomeEvents: String, CaseIterable, Hashable {
    // Shared events (used in multiple states)
    case setBrightness = "set_brightness"
    case setVolume = "set_volume"
    case setTemperature = "set_temperature"
    case emergency = "emergency"
    case timeout = "timeout"
    
    // State-specific events
    case startMorning = "start_morning"
    case startEvening = "start_evening"
    case startParty = "start_party"
    case goAway = "go_away"
    case goToSleep = "go_to_sleep"
    case wakeUp = "wake_up"
    case endParty = "end_party"
}

// Shared handler factories
class BrightnessHandlers {
    static func setBrightnessHandler(for home: SmartHome) -> (Event<SmartHomeEvents>) -> Transition<SmartHomeStates>? {
        return { [weak home] event in
            if let brightness = event.args.first as? Int {
                home?.setBrightnessInternal(brightness)
            }
            return nil
        }
    }
}

class VolumeHandlers {
    static func setVolumeHandler(for home: SmartHome) -> (Event<SmartHomeEvents>) -> Transition<SmartHomeStates>? {
        return { [weak home] event in
            if let volume = event.args.first as? Int {
                home?.setVolumeInternal(volume)
            }
            return nil
        }
    }
}

class TemperatureHandlers {
    static func setTemperatureHandler(for home: SmartHome) -> (Event<SmartHomeEvents>) -> Transition<SmartHomeStates>? {
        return { [weak home] event in
            if let temperature = event.args.first as? Double {
                home?.setTemperatureInternal(temperature)
            }
            return nil
        }
    }
}

class EmergencyHandlers {
    static func emergencyHandler() -> (Event<SmartHomeEvents>) -> Transition<SmartHomeStates>? {
        return { _ in
            print("🚨 EMERGENCY: All systems to safe mode!")
            return Transition(toState: .idle)
        }
    }
}

// Smart Home Controller
class SmartHome {
    private var brightness: Int = 50
    private var volume: Int = 30
    private var temperature: Double = 22.0
    
    // Lazy initialization of FSM
    private lazy var fsm: FSM<SmartHomeStates, SmartHomeEvents> = {
        // Create states
        let idleState = State<SmartHomeStates, SmartHomeEvents>(verbose: true)
        idleState.addHandler(eventType: .startMorning) { _ in
            Transition(toState: .morning)
        }
        idleState.addHandler(eventType: .startEvening) { _ in
            Transition(toState: .evening)
        }
        idleState.addHandler(eventType: .startParty) { _ in
            Transition(toState: .party)
        }
        idleState.addHandler(eventType: .goAway) { _ in
            Transition(toState: .away)
        }
        // Shared handlers
        idleState.addHandler(eventType: .setBrightness, handler: BrightnessHandlers.setBrightnessHandler(for: self))
        idleState.addHandler(eventType: .setVolume, handler: VolumeHandlers.setVolumeHandler(for: self))
        idleState.addHandler(eventType: .setTemperature, handler: TemperatureHandlers.setTemperatureHandler(for: self))
        idleState.addHandler(eventType: .emergency, handler: EmergencyHandlers.emergencyHandler())
        
        let morningState = State<SmartHomeStates, SmartHomeEvents>(timeout: 30, verbose: true)
        morningState.addHandler(eventType: .timeout) { _ in
            print("Morning routine completed, returning to idle")
            return Transition(toState: .idle)
        }
        // Shared handlers
        morningState.addHandler(eventType: .setBrightness, handler: BrightnessHandlers.setBrightnessHandler(for: self))
        morningState.addHandler(eventType: .setVolume, handler: VolumeHandlers.setVolumeHandler(for: self))
        morningState.addHandler(eventType: .setTemperature, handler: TemperatureHandlers.setTemperatureHandler(for: self))
        morningState.addHandler(eventType: .emergency, handler: EmergencyHandlers.emergencyHandler())
        morningState.addEnterHook { _ in
            print("☀️ Morning routine: Coffee brewing, lights brightening, music starting...")
        }
        
        let eveningState = State<SmartHomeStates, SmartHomeEvents>(timeout: 45, verbose: true)
        eveningState.addHandler(eventType: .goToSleep) { _ in
            Transition(toState: .sleep)
        }
        eveningState.addHandler(eventType: .timeout) { _ in
            print("Evening routine completed, returning to idle")
            return Transition(toState: .idle)
        }
        // Shared handlers
        eveningState.addHandler(eventType: .setBrightness, handler: BrightnessHandlers.setBrightnessHandler(for: self))
        eveningState.addHandler(eventType: .setVolume, handler: VolumeHandlers.setVolumeHandler(for: self))
        eveningState.addHandler(eventType: .setTemperature, handler: TemperatureHandlers.setTemperatureHandler(for: self))
        eveningState.addHandler(eventType: .emergency, handler: EmergencyHandlers.emergencyHandler())
        eveningState.addEnterHook { _ in
            print("🌙 Evening routine: Dimming lights, setting mood music...")
        }
        
        let awayState = State<SmartHomeStates, SmartHomeEvents>(verbose: true)
        // Shared handlers only
        awayState.addHandler(eventType: .setBrightness, handler: BrightnessHandlers.setBrightnessHandler(for: self))
        awayState.addHandler(eventType: .setTemperature, handler: TemperatureHandlers.setTemperatureHandler(for: self))
        awayState.addHandler(eventType: .emergency, handler: EmergencyHandlers.emergencyHandler())
        awayState.addEnterHook { _ in
            print("🏠 Away mode: Energy saving, security active...")
        }
        
        let partyState = State<SmartHomeStates, SmartHomeEvents>(timeout: 120, verbose: true)
        partyState.addHandler(eventType: .endParty) { _ in
            Transition(toState: .idle)
        }
        partyState.addHandler(eventType: .timeout) { _ in
            print("Party timeout, returning to idle")
            return Transition(toState: .idle)
        }
        // Shared handlers
        partyState.addHandler(eventType: .setBrightness, handler: BrightnessHandlers.setBrightnessHandler(for: self))
        partyState.addHandler(eventType: .setVolume, handler: VolumeHandlers.setVolumeHandler(for: self))
        partyState.addHandler(eventType: .setTemperature, handler: TemperatureHandlers.setTemperatureHandler(for: self))
        partyState.addHandler(eventType: .emergency, handler: EmergencyHandlers.emergencyHandler())
        partyState.addEnterHook { _ in
            print("🎉 Party mode: Colored lights, high volume, party playlist...")
        }
        
        let sleepState = State<SmartHomeStates, SmartHomeEvents>(verbose: true)
        sleepState.addHandler(eventType: .wakeUp) { _ in
            Transition(toState: .idle)
        }
        // Shared handlers (limited in sleep mode)
        sleepState.addHandler(eventType: .setBrightness, handler: BrightnessHandlers.setBrightnessHandler(for: self))
        sleepState.addHandler(eventType: .setTemperature, handler: TemperatureHandlers.setTemperatureHandler(for: self))
        sleepState.addHandler(eventType: .emergency, handler: EmergencyHandlers.emergencyHandler())
        sleepState.addEnterHook { _ in
            print("😴 Sleep mode: All lights off, alarm set, quiet mode...")
        }
        
        return FSM(
            initialState: .idle,
            stateObjects: [
                .idle: idleState,
                .morning: morningState,
                .evening: eveningState,
                .away: awayState,
                .party: partyState,
                .sleep: sleepState
            ],
            timeoutEvent: .timeout,
            verbose: true
        )
    }()
    
    init() {
        // FSM will be initialized lazily when first accessed
    }
    
    // Public API
    func startMorning() { fsm.handleEvent(Event(type: .startMorning)) }
    func startEvening() { fsm.handleEvent(Event(type: .startEvening)) }
    func startParty() { fsm.handleEvent(Event(type: .startParty)) }
    func goAway() { fsm.handleEvent(Event(type: .goAway)) }
    func goToSleep() { fsm.handleEvent(Event(type: .goToSleep)) }
    func wakeUp() { fsm.handleEvent(Event(type: .wakeUp)) }
    func endParty() { fsm.handleEvent(Event(type: .endParty)) }
    
    func setBrightness(_ brightness: Int) { fsm.handleEvent(Event(type: .setBrightness, args: [brightness])) }
    func setVolume(_ volume: Int) { fsm.handleEvent(Event(type: .setVolume, args: [volume])) }
    func setTemperature(_ temperature: Double) { fsm.handleEvent(Event(type: .setTemperature, args: [temperature])) }
    func emergency() { fsm.handleEvent(Event(type: .emergency)) }
    
    // Internal setters
    internal func setBrightnessInternal(_ brightness: Int) {
        print("💡 Setting brightness to \(brightness)%")
        self.brightness = brightness
    }
    
    internal func setVolumeInternal(_ volume: Int) {
        print("🔊 Setting volume to \(volume)%")
        self.volume = volume
    }
    
    internal func setTemperatureInternal(_ temperature: Double) {
        print("🌡️ Setting temperature to \(temperature)°C")
        self.temperature = temperature
    }
    
    // State and status
    var state: SmartHomeStates { return fsm.currentState }
    var currentBrightness: Int { return brightness }
    var currentVolume: Int { return volume }
    var currentTemperature: Double { return temperature }
}

// Example usage
func runSmartHomeExample() {
    print("=== Smart Home Controller Example ===")
    let home = SmartHome()
    
    print("Initial state: \(home.state.rawValue)")
    
    // Test shared handlers in idle state
    home.setBrightness(80)
    home.setVolume(50)
    home.setTemperature(24.0)
    print("State: \(home.state.rawValue), Brightness: \(home.currentBrightness)%, Volume: \(home.currentVolume)%, Temp: \(home.currentTemperature)°C")
    
    // Test state transitions
    home.startMorning()
    print("State: \(home.state.rawValue)")
    
    // Test shared handlers in morning state
    home.setBrightness(100)
    home.setVolume(60)
    home.setTemperature(22.0)
    print("State: \(home.state.rawValue), Brightness: \(home.currentBrightness)%, Volume: \(home.currentVolume)%, Temp: \(home.currentTemperature)°C")
    
    // Test emergency from any state
    home.emergency()
    print("State after emergency: \(home.state.rawValue)")
    
    // Test party mode
    home.startParty()
    print("State: \(home.state.rawValue)")
    home.setVolume(90)
    home.setBrightness(50)
    print("Party mode - Volume: \(home.currentVolume)%, Brightness: \(home.currentBrightness)%")
    
    // Test sleep mode
    home.endParty()
    home.startEvening()
    home.goToSleep()
    print("State: \(home.state.rawValue)")
    
    // Test away mode
    home.wakeUp()
    home.goAway()
    print("State: \(home.state.rawValue)")
    home.setTemperature(18.0) // Energy saving
    print("Away mode - Temperature: \(home.currentTemperature)°C")
}

// Main function
if CommandLine.arguments.count > 1 {
    let choice = CommandLine.arguments[1]
    switch choice {
    case "1":
        runSmartHomeExample()
    default:
        print("Invalid choice. Use 1 for Smart Home example.")
    }
} else {
    print("Running Smart Home Example...")
    runSmartHomeExample()
} 