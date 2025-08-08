# SwiftFSM - Swift Finite State Machine Library

A Swift implementation of a generic Finite State Machine library, inspired by the Python `common-fsm` library. This library provides a type-safe, iOS-compatible FSM implementation with support for state timeouts, hooks, and error handling.

## Features

- **Type-safe**: Uses Swift's generic system and enums for compile-time safety
- **iOS Compatible**: Works with iOS 13+, macOS 10.15+, tvOS 13+, and watchOS 6+
- **State Timeouts**: Automatic state transitions based on timeouts
- **Hooks**: Enter and exit hooks for states
- **Error Handling**: Optional error states for exception handling
- **Debug Mode**: Disable timers for testing and debugging
- **Verbose Logging**: Optional detailed logging for debugging

## Installation

### Swift Package Manager

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/helgemod/swift-fsm.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/helgemod/swift-fsm.git`
3. Select the version you want to use

## Quick Start

### 1. Define Your States and Events

```swift
enum States: String, CaseIterable {
    case off = "off"
    case on = "on"
}

enum Events: String, CaseIterable {
    case powerOn = "power_on"
    case powerOff = "power_off"
    case timeout = "timeout"
}
```

### 2. Create State Objects

```swift
let offState = State<States, Events>()
offState.addHandler(eventType: .powerOn) { _ in
    Transition(toState: .on)
}

let onState = State<States, Events>(timeout: 5)
onState.addHandler(eventType: .powerOff) { _ in
    Transition(toState: .off)
}
onState.addHandler(eventType: .timeout) { _ in
    Transition(toState: .off)
}
```

### 3. Create the FSM

```swift
let fsm = FSM(
    initialState: .off,
    stateObjects: [
        .off: offState,
        .on: onState
    ],
    timeoutEvent: .timeout
)
```

### 4. Handle Events

```swift
fsm.handleEvent(Event(type: .powerOn))
print(fsm.currentState) // .on
```

## API Reference

### Event

Represents an event with optional arguments.

```swift
struct Event<EventEnum: RawRepresentable> where EventEnum.RawValue == String {
    let type: EventEnum
    let args: [Any]
    let kwargs: [String: Any]
    
    init(type: EventEnum, args: [Any] = [], kwargs: [String: Any] = [:])
}
```

### Transition

Represents a state transition.

```swift
struct Transition<StateEnum: RawRepresentable> where StateEnum.RawValue == String {
    let toState: StateEnum
    
    init(toState: StateEnum)
}
```

### State

Base class for states in the FSM.

```swift
class State<StateEnum: RawRepresentable, EventEnum: RawRepresentable> {
    init(timeout: TimeInterval? = nil, verbose: Bool = false)
    
    func addHandler(eventType: EventEnum, handler: @escaping (Event<EventEnum>) -> Transition<StateEnum>?)
    func addEnterHook(_ hook: @escaping (StateEnum) -> Void)
    func addExitHook(_ hook: @escaping (StateEnum) -> Void)
}
```

### FSM

The main Finite State Machine class.

```swift
class FSM<StateEnum: RawRepresentable, EventEnum: RawRepresentable> {
    var currentState: StateEnum { get }
    
    init(
        initialState: StateEnum,
        stateObjects: [StateEnum: State<StateEnum, EventEnum>],
        timeoutEvent: EventEnum? = nil,
        errorState: StateEnum? = nil,
        validateTransitions: Bool = true,
        verbose: Bool = false,
        debugMode: Bool = false
    )
    
    func handleEvent(_ event: Event<EventEnum>)
    func addEnterHook(for state: StateEnum, hook: @escaping (StateEnum) -> Void)
    func addExitHook(for state: StateEnum, hook: @escaping (StateEnum) -> Void)
    func shutdown()
}
```

## Examples

### Basic State Machine

```swift
import SwiftFSM

enum States: String {
    case idle = "idle"
    case active = "active"
}

enum Events: String {
    case start = "start"
    case stop = "stop"
}

// Create states
let idleState = State<States, Events>()
idleState.addHandler(eventType: .start) { _ in
    Transition(toState: .active)
}

let activeState = State<States, Events>()
activeState.addHandler(eventType: .stop) { _ in
    Transition(toState: .idle)
}

// Create FSM
let fsm = FSM(
    initialState: .idle,
    stateObjects: [
        .idle: idleState,
        .active: activeState
    ]
)

// Use the FSM
fsm.handleEvent(Event(type: .start))
print(fsm.currentState) // .active
```

### State with Timeout

```swift
let activeState = State<States, Events>(timeout: 10) // 10 second timeout
activeState.addHandler(eventType: .timeout) { _ in
    Transition(toState: .idle)
}

let fsm = FSM(
    initialState: .active,
    stateObjects: [.active: activeState],
    timeoutEvent: .timeout
)
// After 10 seconds, will automatically transition to .idle
```

### State Hooks

```swift
let activeState = State<States, Events>()
activeState.addEnterHook { state in
    print("Entering \(state.rawValue)")
}
activeState.addExitHook { state in
    print("Exiting \(state.rawValue)")
}
```

### Event with Data

```swift
let state = State<States, Events>()
state.addHandler(eventType: .setValue) { event in
    if let value = event.args.first as? Int {
        print("Received value: \(value)")
    }
    return nil
}

fsm.handleEvent(Event(type: .setValue, args: [42]))
```

### Error Handling

```swift
enum States: String {
    case normal = "normal"
    case error = "error"
}

let fsm = FSM(
    initialState: .normal,
    stateObjects: [
        .normal: normalState,
        .error: errorState
    ],
    errorState: .error
)
```

## Testing

Run the tests with:

```bash
swift test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Comparison with Python Version

This Swift implementation maintains the same API design principles as the Python `common-fsm` library:

- Same event-driven architecture
- Same state transition model
- Same timeout functionality
- Same hook system
- Same error handling approach

Key differences due to Swift's type system:
- Stronger type safety with generics
- Compile-time validation of state/event enums
- More explicit error handling
- iOS/macOS platform integration

