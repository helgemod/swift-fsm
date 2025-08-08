import Foundation

/// Represents an event with optional arguments
public struct Event<EventEnum: RawRepresentable & Hashable> where EventEnum.RawValue == String {
    /// The type of event
    public let type: EventEnum
    
    /// Optional arguments for the event
    public let args: [Any]
    
    /// Optional keyword arguments for the event
    public let kwargs: [String: Any]
    
    /// Initialize an event with type and optional arguments
    /// - Parameters:
    ///   - type: The type of event
    ///   - args: Optional positional arguments
    ///   - kwargs: Optional keyword arguments
    public init(type: EventEnum, args: [Any] = [], kwargs: [String: Any] = [:]) {
        self.type = type
        self.args = args
        self.kwargs = kwargs
    }
} 