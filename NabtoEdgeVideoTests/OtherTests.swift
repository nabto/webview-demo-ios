//
//  ios_starter_nabtoTests.swift
//  Nabto Edge VideoTests
//
//  Created by Nabto on 30/01/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

import XCTest
import NabtoEdgeClient

class OtherTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBookmarkSaving() {
        BookmarkManager.shared.clearBookmarks()
        let bookmark1 = Bookmark(deviceId: "kzspcxu3.gygkd.appmyproduct.com", productId: "TBD", creationTime: Date(), name: "AMP stub")
        let bookmark2 = Bookmark(deviceId: "kzspcxu4.gygkd.appmyproduct.com", productId: "TBD", creationTime: Date(), name: "AMP stub2")
        BookmarkManager.shared.add(bookmark: bookmark1)
        BookmarkManager.shared.add(bookmark: bookmark2)
        BookmarkManager.shared.saveBookmarks()
        BookmarkManager.shared.deviceBookmarks = []
        
        BookmarkManager.shared.loadBookmarks()
        let savedBookmarks = BookmarkManager.shared.deviceBookmarks
        XCTAssertEqual(savedBookmarks.count, 2)
        
        let saved1 = savedBookmarks[0]
        let saved2 = savedBookmarks[1]
        XCTAssert(bookmark1 == saved1)
        XCTAssert(bookmark2 == saved2)
        XCTAssert(bookmark1.name == saved1.name)
        XCTAssert(bookmark2.name == saved2.name)
        
        BookmarkManager.shared.clearBookmarks()
        BookmarkManager.shared.loadBookmarks()
        XCTAssert(BookmarkManager.shared.deviceBookmarks.count == 0)
    }
    
    func testFingerprintFormatting() {
        let string = "6074fce148dd2dd6b39106fbf4b99dbd"
        let formatted = UserInfo.format(fingerprint: string)
        XCTAssert(formatted == "60:74:fc:e1:48:dd:2d:d6:b3:91:06:fb:f4:b9:9d:bd")
    }

    func testUsernameStrip() {
        XCTAssertEqual(ProfileTools.convertToValidUsername(input: "ABC def-123æøå_Ghijkl+?-_foo🥳XY Z"), "abc-def-123_ghijkl-_fooxy-z")
    }

    func testParsePairingString() throws {
        let result = try AddDeviceViewController.parsePairingString(pairingString: "p=pr-foo,d=de-bar,pwd=secret,sct=alsosecret")
        XCTAssertEqual(result.productId, "pr-foo")
        XCTAssertEqual(result.deviceId, "de-bar")
        XCTAssertEqual(result.password, "secret")
        XCTAssertEqual(result.sct, "alsosecret")
    }

    func testParseBadlyFormattedPairingString() throws {
        do {
            _ = try AddDeviceViewController.parsePairingString(pairingString: "p=pr-foo,de-bar,pwd=secret,sct=alsosecret")
            _ = try AddDeviceViewController.parsePairingString(pairingString: "p=pr-foo:de-bar,pwd=secret,sct=alsosecret")
            _ = try AddDeviceViewController.parsePairingString(pairingString: ":")
            _ = try AddDeviceViewController.parsePairingString(pairingString: ",,")
        } catch NabtoEdgeClientError.FAILED_WITH_DETAIL(let detail) {
            XCTAssertTrue(detail.lowercased().contains("format"))
            return
        }
    }

    func testParsePairingStringWithoutSct() throws {
        let result = try AddDeviceViewController.parsePairingString(pairingString: "p=pr-foo,d=de-bar,pwd=secret")
        XCTAssertEqual(result.productId, "pr-foo")
        XCTAssertEqual(result.deviceId, "de-bar")
        XCTAssertEqual(result.password, "secret")
    }

    func testParsePairingStringWithoutDeviceId() throws {
        do {
            try AddDeviceViewController.parsePairingString(pairingString: "p=pr-foo,pwd=secret,sct=bar")
        } catch NabtoEdgeClientError.FAILED_WITH_DETAIL(let detail) {
            XCTAssertTrue(detail.lowercased().contains("missing"))
            return
        }
        XCTFail("Expected parse failure")
    }

    func testParsePairingStringWithoutProductId() throws {
        do {
            try AddDeviceViewController.parsePairingString(pairingString: "sct=foo,d=de-bar,pwd=secret")
        } catch NabtoEdgeClientError.FAILED_WITH_DETAIL(let detail) {
            XCTAssertTrue(detail.lowercased().contains("missing"))
            return
        }
        XCTFail("Expected parse failure")
    }

    func testParsePairingStringWithoutPassword() throws {
        do {
            try AddDeviceViewController.parsePairingString(pairingString: "d=de-foo,sct=bar,p=pr-baz")
        } catch NabtoEdgeClientError.FAILED_WITH_DETAIL(let detail) {
            XCTAssertTrue(detail.lowercased().contains("missing"))
            return
        }
        XCTFail("Expected parse failure")
    }

    func testParsePairingStringWithUnknownField() throws {
        do {
            try AddDeviceViewController.parsePairingString(pairingString: "p=pr-foo,d=de-bar,pwd=secret,sct=alsosecret,foo=bar")
        } catch NabtoEdgeClientError.FAILED_WITH_DETAIL(let detail) {
            XCTAssertTrue(detail.lowercased().contains("unexpected"))
            return
        }
        XCTFail("Expected parse failure")
    }

    func testParsePairingStringTooShort() throws {
        do {
            try AddDeviceViewController.parsePairingString(pairingString: "p=pr-foo,d=de-bar")
        } catch NabtoEdgeClientError.FAILED_WITH_DETAIL(let detail) {
            XCTAssertTrue(detail.lowercased().contains("unexpected number"))
            return
        }
        XCTFail("Expected parse failure")
    }

    func testParseRealPairingString() throws {
        let result = try AddDeviceViewController.parsePairingString(pairingString: "p=pr-fatqcwj9,de-ijrdq47i,pwd=open-password,sct=WzwjoTabnvux")
        XCTAssertEqual(result.productId, "pr-fatqcwj9")
        XCTAssertEqual(result.deviceId, "de-ijrdq47i")
        XCTAssertEqual(result.password, "open-password")
        XCTAssertEqual(result.sct, "WzwjoTabnvux")
    }


}
