//
//  FrameworkIntegrationTests.swift
//  Nabto Edge Video
//
//  Created by Nabto on 07/02/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

//  Basic checks to verify that the framework is integrated correctly

import XCTest

class FrameworkIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNabtoStartup() {
        
        let expect = expectation(description: "Nabto startup")

        NabtoManager.shared.startup { (success, error) in
            XCTAssert(success)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
        }
    }
    
    func testNabtoProfileCreation() {
        
        let expect = expectation(description: "Nabto profile")
        
        NabtoManager.shared.createKeyPair(username: "tester") { (success, error) in
            XCTAssert(success)
            if success {
                NabtoManager.shared.getFingerprint(username: "tester", completion: { (fingerprint, error) in
                    if let fingerprint = fingerprint {
                        NabtoManager.shared.openSessionForProfile(username: "tester") { (success, error) in
                            XCTAssert(success)
                            XCTAssert(fingerprint.characters.count == 32)
                            expect.fulfill()
                        }
                    } else {
                        XCTFail()
                    }
                })
            }
        }
        waitForExpectations(timeout: 1) { error in
        }
    }
    
    func testNabtoDiscover() {
        let expect = expectation(description: "Nabto discover")
        
        NabtoManager.shared.createKeyPair(username: "tester") { (success, error) in
            XCTAssert(success)
            NabtoManager.shared.getFingerprint(username: "tester", completion: { (fingerprint, error) in
                XCTAssertNotNil(fingerprint)
                NabtoManager.shared.openSessionForProfile(username: "tester") { (success, error) in
                    XCTAssert(success, "Open session")
                    //test discover
                    NabtoManager.shared.discover(progress: { (device) in
                        XCTAssert(true, "Got device")
                        expect.fulfill()
                    }) { (error) in
                        switch error {
                        case .empty:
                            XCTAssert(true, "Got empty list")
                            expect.fulfill()
                        default:
                            XCTFail()
                        }
                    }
                }
            })
        }
        waitForExpectations(timeout: 20) { error in
        }
    }
}
