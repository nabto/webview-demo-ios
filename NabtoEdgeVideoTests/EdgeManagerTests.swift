import XCTest
import Foundation

struct TestDevice {
    var productId: String
    var deviceId: String
    var url: String
    var key: String
    var fp: String?
    var sct: String?
    var local: Bool
    var password: String!

    init(productId: String, deviceId: String, url: String, key: String, fp: String?=nil, sct: String?=nil, local: Bool=false, password: String?=nil) {
        self.productId = productId
        self.deviceId = deviceId
        self.url = url
        self.key = key
        self.fp = fp
        self.sct = sct
        self.local = local
        self.password = password
    }

    func asJson() -> String {
        let sctElement = sct != nil ? "\"ServerConnectToken\": \"\(sct!)\",\n" : ""
        return """
               {\n
               \"Local\": \(self.local),\n
               \"ProductId\": \"\(self.productId)\",\n
               \"DeviceId\": \"\(self.deviceId)\",\n
               \"ServerUrl\": \"\(self.url)\",\n
               \(sctElement)
               \"ServerKey\": \"\(self.key)\"\n}
               """
    }
}

class EdgeManagerTest: XCTestCase {

    let testDevice = TestDevice(
            productId: "pr-fatqcwj9",
            deviceId: "de-avmqjaje",
            url: "https://pr-fatqcwj9.clients.nabto.net",
            key: "sk-5f3ab4bea7cc2585091539fb950084ce",
            fp: "fcb78f8d53c67dbc4f72c36ca6cd2d5fc5592d584222059f0d76bdb514a9340c"
    )

    func createTestBookmark() -> Bookmark {
        return Bookmark(
                deviceId: self.testDevice.deviceId,
                productId: self.testDevice.productId,
                creationTime: Date(),
                name: "Test Device")
    }

    var sut: EdgeConnectionManager!

    override func setUpWithError() throws {
        self.continueAfterFailure = false
        self.sut = EdgeConnectionManager()
        let key = try self.sut.client.createPrivateKey()
        let username = "edgemanager-test-user"
        let displayName = "EdgeManager Test User"
        ProfileTools.saveProfile(username: username, privateKey: key, displayName: displayName)
    }

    override func tearDown() {
        self.sut.reset()
    }

    func testSomething() {
        XCTAssertEqual(1, 1);
    }

    func testConnectionCache() throws {
        let bookmark = self.createTestBookmark()

        let connection = try self.sut.getConnection(bookmark)
        let coap = try connection.createCoapRequest(method: "GET", path: "/hello-world")
        let response = try coap.execute()
        XCTAssertEqual(response.status, 205)

        let connection2 = try self.sut.getConnection(bookmark)
        XCTAssertEqual(Unmanaged.passUnretained(connection).toOpaque(), Unmanaged.passUnretained(connection2).toOpaque())

        try connection.close()

        let connection3 = try self.sut.getConnection(bookmark)
        XCTAssertNotEqual(Unmanaged.passUnretained(connection).toOpaque(), Unmanaged.passUnretained(connection3).toOpaque())

        let coap2 = try connection3.createCoapRequest(method: "GET", path: "/hello-world")
        let response2 = try coap2.execute()
        XCTAssertEqual(response2.status, 205)

    }
}
