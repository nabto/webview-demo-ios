//
//  PairingConfirmedViewController.swift
//  Nabto Edge Video
//
//  Created by Ulrik Gammelby on 11/08/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

import Foundation
import UIKit
import NabtoEdgeClient

class AddDeviceViewController: UIViewController, UITextFieldDelegate {

    // MARK: - IBOutlet fields

    @IBOutlet weak var pairingStringButton: UIButton!
    @IBOutlet weak var discoverButton: UIButton!
    @IBOutlet weak var pairingStringField: UITextField!
    @IBOutlet weak var pairingStringErrorLabel: UILabel!

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.pairingStringButton.isEnabled = false
        self.discoverButton.layer.cornerRadius  = 6
        self.discoverButton.clipsToBounds   = true
        self.pairingStringButton.layer.cornerRadius  = 6
        self.pairingStringButton.clipsToBounds   = true

        // dismiss keyboard when tapping background or return key
        let tapGesture = UITapGestureRecognizer(target: self,
                action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        self.pairingStringField.delegate = self
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
        guard identifier == "pairUsingString" else { return true }
        if let str = pairingStringField.text {
            do {
                let _ = try Self.parsePairingString(pairingString: str)
                return true
            } catch {
                return false
            }
        }
        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let destination = segue.destination as? PairingViewController {
            if let str = pairingStringField.text {
                do {
                    let pairingDetails = try Self.parsePairingString(pairingString: str)
                    let bookmark = Bookmark(deviceId: pairingDetails.deviceId, productId: pairingDetails.productId, sct: pairingDetails.sct)
                    destination.device = bookmark
                    destination.pairingStringPassword = pairingDetails.password
                } catch {
                    print("Never here: Pairing string invalid")
                    return
                }
            } else {
                print("Never here: Pairing string empty")
                return
            }
        }
    }

    // MARK: - Keyboard input

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func hideKeyboard() {
        self.view.endEditing(true)
    }

    @IBAction func handlePairingStringChanged(_ sender: Any) {
        if let str = pairingStringField.text {
            do {
                let _ = try Self.parsePairingString(pairingString: str)
                self.pairingStringButton.isEnabled = true
                self.pairingStringErrorLabel.isHidden = true
            } catch {
                self.pairingStringButton.isEnabled = false
                self.pairingStringErrorLabel.isHidden = false
            }
        } else {
            self.pairingStringButton.isEnabled = false
            self.pairingStringErrorLabel.isHidden = false
        }
    }

    struct PairingDetails {
        var productId: String!
        var deviceId: String!
        var password: String!
        var sct: String?
        var username: String?
    }

    static internal func parsePairingString(pairingString: String) throws -> PairingDetails {
        var result = PairingDetails()
        let elements = pairingString.components(separatedBy: CharacterSet(charactersIn: ";:,"))
        if (elements.count < 3 || elements.count > 5) {
            throw NabtoEdgeClientError.FAILED_WITH_DETAIL(detail: "Unexpected number of elements in pairing string")
        }
        for element in elements {
            let tuple = element.components(separatedBy: "=")
            if (tuple.count != 2) {
                throw NabtoEdgeClientError.FAILED_WITH_DETAIL(detail: "Badly formatted pairing string, missing '='")
            }
            let key = tuple[0]
            let value = tuple[1]
            switch (key) {
            case "p": result.productId = value; break
            case "d": result.deviceId = value; break
            case "pwd": result.password = value; break
            case "sct": result.sct = value; break
            case "u": result.username = value; break
            default: throw NabtoEdgeClientError.FAILED_WITH_DETAIL(detail: "Unexpected element in pairing string: \(key)")
            }
        }
        if (result.productId == nil || result.deviceId == nil || result.password == nil) {
            throw NabtoEdgeClientError.FAILED_WITH_DETAIL(detail: "Missing element in pairing string")
        }
        return result
    }

}
