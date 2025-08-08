import XCTest
@testable import SwiftFSM

final class SwiftFSMTests: XCTestCase {
    
    // Test enums
    enum States: String, CaseIterable, Hashable {
        case stateA = "state_a"
        case stateB = "state_b"
    }
    
    enum Events: String, CaseIterable, Hashable {
        case event1 = "event_1"
        case event2 = "event_2"
        case eventWithData = "event_with_data"
        case timeout = "timeout"
    }
    
    func testInitialState() {
        // Create states
        let stateA = State<States, Events>()
        let stateB = State<States, Events>()
        
        // Add handlers
        stateA.addHandler(eventType: .event1) { _ in
            Transition(toState: .stateB)
        }
        
        stateB.addHandler(eventType: .event2) { _ in
            Transition(toState: .stateA)
        }
        
        // Create FSM
        let fsm = FSM(
            initialState: .stateA,
            stateObjects: [
                .stateA: stateA,
                .stateB: stateB
            ]
        )
        
        XCTAssertEqual(fsm.currentState, .stateA)
    }
    
    func testStateTransition() {
        // Create states
        let stateA = State<States, Events>()
        let stateB = State<States, Events>()
        
        // Add handlers
        stateA.addHandler(eventType: .event1) { _ in
            Transition(toState: .stateB)
        }
        
        stateB.addHandler(eventType: .event2) { _ in
            Transition(toState: .stateA)
        }
        
        // Create FSM
        let fsm = FSM(
            initialState: .stateA,
            stateObjects: [
                .stateA: stateA,
                .stateB: stateB
            ]
        )
        
        // Test transition from A to B
        fsm.handleEvent(Event(type: .event1))
        XCTAssertEqual(fsm.currentState, .stateB)
        
        // Test transition back to A
        fsm.handleEvent(Event(type: .event2))
        XCTAssertEqual(fsm.currentState, .stateA)
    }
    
    func testUnhandledEvent() {
        // Create states
        let stateA = State<States, Events>()
        let stateB = State<States, Events>()
        
        // Add handlers
        stateA.addHandler(eventType: .event1) { _ in
            Transition(toState: .stateB)
        }
        
        stateB.addHandler(eventType: .event2) { _ in
            Transition(toState: .stateA)
        }
        
        // Create FSM
        let fsm = FSM(
            initialState: .stateA,
            stateObjects: [
                .stateA: stateA,
                .stateB: stateB
            ]
        )
        
        // Event that isn't handled shouldn't change state
        let initialState = fsm.currentState
        fsm.handleEvent(Event(type: .eventWithData))
        XCTAssertEqual(fsm.currentState, initialState)
    }
    
    func testHooks() {
        // Create states
        let stateA = State<States, Events>()
        let stateB = State<States, Events>()
        
        // Track hook calls
        var enterCalls: [(String, States)] = []
        var exitCalls: [(String, States)] = []
        
        // Add handlers and hooks
        stateA.addHandler(eventType: .event1) { _ in
            Transition(toState: .stateB)
        }
        stateA.addExitHook { state in
            exitCalls.append(("A", state))
        }
        stateB.addEnterHook { state in
            enterCalls.append(("B", state))
        }
        
        // Create FSM
        let fsm = FSM(
            initialState: .stateA,
            stateObjects: [
                .stateA: stateA,
                .stateB: stateB
            ]
        )
        
        // Test transition and hooks
        fsm.handleEvent(Event(type: .event1))
        XCTAssertEqual(exitCalls.count, 1)
        XCTAssertEqual(exitCalls.first?.0, "A")
        XCTAssertEqual(exitCalls.first?.1, .stateA)
        XCTAssertEqual(enterCalls.count, 1)
        XCTAssertEqual(enterCalls.first?.0, "B")
        XCTAssertEqual(enterCalls.first?.1, .stateB)
    }
    
    func testEventWithData() {
        // Create state with handler that uses event data
        let stateA = State<States, Events>()
        var receivedData: [Any] = []
        
        stateA.addHandler(eventType: .eventWithData) { event in
            receivedData = event.args
            return nil
        }
        
        // Create FSM
        let fsm = FSM(
            initialState: .stateA,
            stateObjects: [.stateA: stateA]
        )
        
        // Test event with data
        let testData: [Any] = [42, "test"]
        fsm.handleEvent(Event(type: .eventWithData, args: testData))
        XCTAssertEqual(receivedData.count, 2)
        XCTAssertEqual(receivedData[0] as? Int, 42)
        XCTAssertEqual(receivedData[1] as? String, "test")
    }
    
    func testTimeout() {
        // Create states with timeout
        let stateA = State<States, Events>(timeout: 0.1) // 100ms timeout
        let stateB = State<States, Events>()
        
        // Add handlers
        stateA.addHandler(eventType: .event1) { _ in
            Transition(toState: .stateB)
        }
        stateA.addHandler(eventType: .timeout) { _ in
            Transition(toState: .stateB)
        }
        
        // Create FSM with timeout event
        let fsm = FSM(
            initialState: .stateA,
            stateObjects: [
                .stateA: stateA,
                .stateB: stateB
            ],
            timeoutEvent: .timeout,
            debugMode: false // Enable timers
        )
        
        // Wait for timeout
        let expectation = XCTestExpectation(description: "Timeout transition")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(fsm.currentState, .stateB)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.3)
    }
    
    func testDebugMode() {
        // Create states with timeout
        let stateA = State<States, Events>(timeout: 0.1)
        let stateB = State<States, Events>()
        
        // Add handlers
        stateA.addHandler(eventType: .timeout) { _ in
            Transition(toState: .stateB)
        }
        
        // Create FSM in debug mode (timers disabled)
        let fsm = FSM(
            initialState: .stateA,
            stateObjects: [
                .stateA: stateA,
                .stateB: stateB
            ],
            timeoutEvent: .timeout,
            debugMode: true // Disable timers
        )
        
        // Wait - should not transition due to debug mode
        let expectation = XCTestExpectation(description: "No timeout in debug mode")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(fsm.currentState, .stateA) // Should still be in stateA
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.3)
    }
    
    func testShutdown() {
        // Create states with timeout
        let stateA = State<States, Events>(timeout: 1.0)
        
        // Create FSM
        let fsm = FSM(
            initialState: .stateA,
            stateObjects: [.stateA: stateA],
            timeoutEvent: .timeout
        )
        
        // Shutdown should stop timers
        fsm.shutdown()
        
        // Verify no timer is running (by checking that state doesn't change)
        let expectation = XCTestExpectation(description: "No state change after shutdown")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(fsm.currentState, .stateA)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.3)
    }
} 