//
//  PermissionTests.swift
//  Nabto Edge Video
//
//  Created by Nabto on 07/02/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

//  Check that device permissions are being used correctly

import XCTest

class PermissionTests: XCTestCase {
    
    var device: NabtoDevice!
    
    override func setUp() {
        super.setUp()

        let dictionary: [String: Any] = ["device_name" : "Device",
                                         "is_open_for_pairing" : true]
        
        device = NabtoDevice(id: "kzspcxu3.gygkd.appmyproduct.com", nabtoInfo: dictionary)
        device.remoteAccessEnabled = true
        device.grantGuestRemoteAccess = true
    }
    
    func testPermissionRead() {
        //test getting permissions
        
        let correctSystemPermissions = Permission.SYSTEM_LOCAL_ACCESS | Permission.SYSTEM_REMOTE_ACCESS | Permission.SYSTEM_PAIRING
        let correctDefaultPermissions = Permission.REMOTE_ACCESS | Permission.LOCAL_ACCESS
        
        XCTAssert(device.getSystemPermissions() == correctSystemPermissions)
        XCTAssert(device.getDefaultUserPermissions() == correctDefaultPermissions)
    }
    
    func testPermissionWrite() {
        //test setting permissions
        
        device.setSecurityDetails(permissions: Permission.SYSTEM_LOCAL_ACCESS | Permission.REMOTE_ACCESS, defaultUserPermissions: 0)
        
        XCTAssert(device.grantGuestRemoteAccess == false)
        XCTAssert(device.remoteAccessEnabled == true)
        XCTAssert(device.openForPairing == false)
        
        device.setSecurityDetails(permissions: Permission.SYSTEM_LOCAL_ACCESS | Permission.SYSTEM_PAIRING, defaultUserPermissions: Permission.REMOTE_ACCESS)
        
        XCTAssert(device.grantGuestRemoteAccess == true)
        XCTAssert(device.remoteAccessEnabled == false)
        XCTAssert(device.openForPairing == true)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
}
