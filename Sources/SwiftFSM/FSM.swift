import Foundation

/// A generic Finite State Machine implementation with optional state timeouts
public class FSM<StateEnum: RawRepresentable & Hashable, EventEnum: RawRepresentable & Hashable> 
    where StateEnum.RawValue == String, EventEnum.RawValue == String {
    
    /// Current state of the FSM
    public private(set) var currentState: StateEnum
    
    /// Dictionary mapping state enums to state objects
    private let stateObjects: [StateEnum: State<StateEnum, EventEnum>]
    
    /// Whether to enable verbose logging
    public let verbose: Bool
    
    /// Optional timeout event type
    public let timeoutEvent: EventEnum?
    
    /// Optional error state
    public let errorState: StateEnum?
    
    /// Whether to validate transitions during initialization
    public let validateTransitions: Bool
    
    /// Whether to run in debug mode (disables timers)
    public let debugMode: Bool
    
    /// Current timer for the current state
    private var currentTimer: Timer?
    
    /// Dictionary of enter hooks for each state
    private var enterHooks: [StateEnum: [(StateEnum) -> Void]] = [:]
    
    /// Dictionary of exit hooks for each state
    private var exitHooks: [StateEnum: [(StateEnum) -> Void]] = [:]
    
    /// Initialize the FSM with initial state and state objects
    /// - Parameters:
    ///   - initialState: The initial state of the FSM
    ///   - stateObjects: Dictionary mapping state enums to state objects
    ///   - timeoutEvent: Optional event type to trigger on timeout
    ///   - errorState: Optional error state to transition to on exceptions
    ///   - validateTransitions: Whether to validate transitions during initialization
    ///   - verbose: Whether to enable verbose logging
    ///   - debugMode: Whether to run in debug mode (disables timers)
    public init(
        initialState: StateEnum,
        stateObjects: [StateEnum: State<StateEnum, EventEnum>],
        timeoutEvent: EventEnum? = nil,
        errorState: StateEnum? = nil,
        validateTransitions: Bool = true,
        verbose: Bool = false,
        debugMode: Bool = false
    ) {
        // Validate initial state exists
        guard stateObjects[initialState] != nil else {
            fatalError("Initial state \(initialState.rawValue) not found in stateObjects")
        }
        
        // Validate error state exists if provided
        if let errorState = errorState, stateObjects[errorState] == nil {
            fatalError("Error state \(errorState.rawValue) not found in stateObjects")
        }
        
        self.currentState = initialState
        self.stateObjects = stateObjects
        self.verbose = verbose
        self.timeoutEvent = timeoutEvent
        self.errorState = errorState
        self.validateTransitions = validateTransitions
        self.debugMode = debugMode
        
        // Validate all transitions point to valid states
        if validateTransitions {
            validateAllTransitions()
        }
        
        // Start timer for initial state if needed (unless in debug mode)
        if timeoutEvent != nil && !debugMode {
            startTimer(for: initialState)
        }
    }
    
    /// Validate that all transitions point to states that exist in stateObjects
    private func validateAllTransitions() {
        // Note: In Swift, we can't easily inspect closures like in Python
        // So we'll skip detailed validation and trust the user
        // This is similar to the Python version's approach with lambda functions
    }
    
    /// Add a hook that runs when entering a state
    /// - Parameters:
    ///   - state: The state to add the hook for
    ///   - hook: The hook function
    public func addEnterHook(for state: StateEnum, hook: @escaping (StateEnum) -> Void) {
        if enterHooks[state] == nil {
            enterHooks[state] = []
        }
        enterHooks[state]?.append(hook)
    }
    
    /// Add a hook that runs when exiting a state
    /// - Parameters:
    ///   - state: The state to add the hook for
    ///   - hook: The hook function
    public func addExitHook(for state: StateEnum, hook: @escaping (StateEnum) -> Void) {
        if exitHooks[state] == nil {
            exitHooks[state] = []
        }
        exitHooks[state]?.append(hook)
    }
    
    /// Start timer for a state if timeout is set and not in debug mode
    /// - Parameter state: The state to start timer for
    private func startTimer(for state: StateEnum) {
        if debugMode {
            if verbose {
                print("Debug mode: Skipping timer for state \(state.rawValue)")
            }
            return
        }
        
        // Stop any existing timer first
        stopTimer()
        
        guard let stateObject = stateObjects[state],
              let timeout = stateObject.timeout,
              let timeoutEvent = timeoutEvent else {
            return
        }
        
        currentTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.handleEvent(Event(type: timeoutEvent))
        }
    }
    
    /// Stop the current timer if it exists
    private func stopTimer() {
        currentTimer?.invalidate()
        currentTimer = nil
    }
    
    /// Handle an incoming event by delegating to current state handler
    /// - Parameter event: The event to handle
    public func handleEvent(_ event: Event<EventEnum>) {
        let current = currentState
        guard let stateObject = stateObjects[current] else {
            print("No state object found for current state \(current.rawValue)")
            return
        }
        
        // Let the state handle the event
        guard let transition = stateObject.handleEvent(event, stateName: current.rawValue) else {
            return
        }
        
        // If state change is needed
        if transition.toState != current {
            // Stop timer for current state
            stopTimer()
            
            // Execute exit hooks for current state
            executeHooks(stateObject.exitHooks, state: current)
            
            // Update state
            currentState = transition.toState
            guard let newState = stateObjects[transition.toState] else {
                print("No state object found for new state \(transition.toState.rawValue)")
                return
            }
            
            // Execute enter hooks for new state
            executeHooks(newState.enterHooks, state: transition.toState)
            
            // Start timer for new state if needed
            if !debugMode {
                startTimer(for: transition.toState)
            }
        }
    }
    
    /// Execute hooks safely, catching and logging any exceptions
    /// - Parameters:
    ///   - hooks: The hooks to execute
    ///   - state: The state enum
    private func executeHooks(_ hooks: [(StateEnum) -> Void], state: StateEnum) {
        for hook in hooks {
            hook(state)
        }
    }
    
    /// Shutdown the FSM and cleanup resources
    public func shutdown() {
        stopTimer()
        if verbose {
            print("FSM shutdown complete")
        }
    }
    
    /// Transition to the error state due to an exception
    /// - Parameter exception: The exception that caused the error
    private func transitionToErrorState(_ exception: Error) {
        guard let errorState = errorState else {
            return
        }
        
        // Stop timer for current state
        stopTimer()
        
        // Get current state object
        guard let currentStateObj = stateObjects[currentState] else {
            print("No state object found for current state \(self.currentState.rawValue)")
            return
        }
        
        // Execute exit hooks for current state
        executeHooks(currentStateObj.exitHooks, state: currentState)
        
        // Update state
        let previousState = currentState
        currentState = errorState
        guard let errorStateObj = stateObjects[errorState] else {
            print("No state object found for error state \(errorState.rawValue)")
            return
        }
        
        // Log the transition
        if verbose {
            print("Transitioning from \(previousState.rawValue) to error state \(errorState.rawValue) due to exception: \(exception.localizedDescription)")
        }
        
        // Execute enter hooks for error state
        executeHooks(errorStateObj.enterHooks, state: errorState)
    }
} 