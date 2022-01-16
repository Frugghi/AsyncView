import SwiftUI
import XCTest

struct Fulfill: View {

    init(_ expectation: XCTestExpectation) {
        expectation.fulfill()
    }

    var body: some View {
        EmptyView()
    }
}
