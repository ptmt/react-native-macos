import XCTest
import Foundation
@testable import UIExplorerGtk

class BridgeTests: XCTestCase {

	func testContextIsCreated() {
		if let url = NSURL(string: "http://localhost:8081/ReactLinux/UIExplorerQtk/UIExplorerApp.linux.bundle?platform=linux&dev=true") {
			let bridge = Bridge(withURL: url)
			XCTAssert(bridge.context != nil)
		} else {
			XCTFail()
		}
	}

}
extension BridgeTests {
	static var allTests : [(String, BridgeTests -> () throws -> Void)] {
		return [
			("testExample", testExample),
		]
	}
}
