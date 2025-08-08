import Foundation

/// Base class for states in the FSM
public class State<StateEnum: RawRepresentable & Hashable, EventEnum: RawRepresentable & Hashable> 
    where StateEnum.RawValue == String, EventEnum.RawValue == String {
    
    /// Dictionary of event handlers for this state
    private var handlers: [EventEnum: (Event<EventEnum>) -> Transition<StateEnum>?] = [:]
    
    /// Array of enter hooks that run when entering this state
    internal var enterHooks: [(StateEnum) -> Void] = []
    
    /// Array of exit hooks that run when exiting this state
    internal var exitHooks: [(StateEnum) -> Void] = []
    
    /// Optional timeout for this state (in seconds)
    public let timeout: TimeInterval?
    
    /// Whether to enable verbose logging
    public let verbose: Bool
    
    /// Initialize a state with optional timeout and verbose settings
    /// - Parameters:
    ///   - timeout: Optional timeout in seconds
    ///   - verbose: Whether to enable verbose logging
    public init(timeout: TimeInterval? = nil, verbose: Bool = false) {
        self.timeout = timeout
        self.verbose = verbose
    }
    
    /// Add a handler for a specific event type
    /// - Parameters:
    ///   - eventType: The event type to handle
    ///   - handler: The handler function that takes an event and returns an optional transition
    public func addHandler(eventType: EventEnum, handler: @escaping (Event<EventEnum>) -> Transition<StateEnum>?) {
        handlers[eventType] = handler
    }
    
    /// Add a hook that runs when entering this state
    /// - Parameter hook: The hook function that takes the state enum
    public func addEnterHook(_ hook: @escaping (StateEnum) -> Void) {
        enterHooks.append(hook)
    }
    
    /// Add a hook that runs when exiting this state
    /// - Parameter hook: The hook function that takes the state enum
    public func addExitHook(_ hook: @escaping (StateEnum) -> Void) {
        exitHooks.append(hook)
    }
    
    /// Handle an event and return a transition if state should change
    /// - Parameters:
    ///   - event: The event to handle
    ///   - stateName: The name of the current state (for logging)
    ///   - catchExceptions: Whether to catch exceptions in handlers
    /// - Returns: An optional transition if the state should change
    public func handleEvent(_ event: Event<EventEnum>, stateName: String, catchExceptions: Bool = false) -> Transition<StateEnum>? {
        guard let handler = handlers[event.type] else {
            if verbose {
                print("No handler for event \(event.type.rawValue) in state \(stateName)")
            }
            return nil
        }
        
        if catchExceptions {
            do {
                return handler(event)
            } catch {
                if verbose {
                    print("Error in handler for event \(event.type.rawValue) in state \(stateName): \(error.localizedDescription)")
                }
                return nil
            }
        } else {
            return handler(event)
        }
    }
    
    /// Execute enter hooks for this state
    /// - Parameter state: The state enum
    internal func executeEnterHooks(_ state: StateEnum) {
        for hook in enterHooks {
            hook(state)
        }
    }
    
    /// Execute exit hooks for this state
    /// - Parameter state: The state enum
    internal func executeExitHooks(_ state: StateEnum) {
        for hook in exitHooks {
            hook(state)
        }
    }
} 