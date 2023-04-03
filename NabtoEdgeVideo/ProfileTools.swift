//
//  ProfileManager.swift
//  Nabto Edge Video
//
//  Created by Nabto on 02/02/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

import UIKit
import Foundation

class ProfileTools {

    enum DefaultsKey: String {
        case username = "username"
        case privateKey = "privateKey"
        case displayName = "displayName"
    }

    class func convertToValidUsername(input: String) -> String {
        // valid chars in Edge IAM: https://docs.nabto.com/developer/api-reference/coap/iam/pairing-password-open.html
        let validChars = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvxyz0123456789-_.")
        return input
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .components(separatedBy: validChars.inverted)
                .joined(separator: "")
    }

    class func saveProfile(username: String, privateKey: String, displayName: String) {
        ProfileTools.savePrivateKey(privateKey: privateKey)
    }
    
    class func clearProfile() {
        ProfileTools.clearPrivateKey()
    }
    
    class func getSavedPrivateKey() -> String? {
        return UserDefaults.standard.string(forKey: DefaultsKey.privateKey.rawValue)
    }
    
    class func savePrivateKey(privateKey: String) {
        let defaults = UserDefaults.standard
        defaults.set(privateKey, forKey: DefaultsKey.privateKey.rawValue)
        defaults.synchronize()
    }
    
    class func clearPrivateKey() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: DefaultsKey.privateKey.rawValue)
        defaults.synchronize()
    }
}
