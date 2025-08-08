import Foundation

/// Represents a state transition
public struct Transition<StateEnum: RawRepresentable & Hashable> where StateEnum.RawValue == String {
    /// The target state for the transition
    public let toState: StateEnum
    
    /// Initialize a transition to a target state
    /// - Parameter toState: The target state
    public init(toState: StateEnum) {
        self.toState = toState
    }
} 