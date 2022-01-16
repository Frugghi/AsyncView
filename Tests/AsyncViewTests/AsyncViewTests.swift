import XCTest
import SwiftUI
@testable import AsyncView

final class AsyncViewTests: XCTestCase {
    
    func testLoadContentSuccess() throws {
        let emptyPhase = XCTestExpectation(description: "Received empty phase")
        let successPhase = XCTestExpectation(description: "Received success phase")
        let expectedValue = "test"
        let view = AsyncView(task: { expectedValue }) { phase in
            switch phase {
            case .empty:
                Fulfill(emptyPhase)

            case .success(let value) where value == expectedValue:
                Fulfill(successPhase)

            default:
                EmptyView()
            }
        }

        let window = view.addToWindow()
        defer { window.close() }

        wait(for: [emptyPhase, successPhase], timeout: 1, enforceOrder: true)
    }

    func testLoadContentFailure() throws {
        let emptyPhase = XCTestExpectation(description: "Received empty phase")
        let failurePhase = XCTestExpectation(description: "Received failure phase")
        let view = AsyncView(task: { throw URLError(.badServerResponse) }) { phase in
            switch phase {
            case .empty:
                Fulfill(emptyPhase)

            case .failure(_):
                Fulfill(failurePhase)

            default:
                EmptyView()
            }
        }

        let window = view.addToWindow()
        defer { window.close() }

        wait(for: [emptyPhase, failurePhase], timeout: 1, enforceOrder: true)
    }
}
