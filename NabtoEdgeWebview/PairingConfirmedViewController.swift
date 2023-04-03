//
//  PairingConfirmedViewController.swift
//  Nabto Edge Video
//
//  Created by Ulrik Gammelby on 11/08/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

import Foundation
import UIKit
import NotificationBannerSwift

protocol PairingConfirmedListener {
    func pairingConfirmed()
}

class PairingConfirmedViewController: ViewControllerWithDevice, UITextFieldDelegate {
    
    @IBOutlet weak var congratulationsLabel: UILabel!
    @IBOutlet weak var saveAndShowDeviceButton: UIButton!
    @IBOutlet weak var nameField: UITextField!
    var pairingConfirmedDelegate: PairingConfirmedListener?

    var appName: String = "My Device"
    let text = "Congratulations! You are successfully paired with device '%@.%@' in role '%@'."

    override func viewDidLoad() {
        super.viewDidLoad()
        saveAndShowDeviceButton.layer.cornerRadius  = 6
        saveAndShowDeviceButton.clipsToBounds   = true

        // dismiss keyboard when tapping background or return key
        let tapGesture = UITapGestureRecognizer(target: self,
                action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        self.nameField.delegate = self
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    @objc private func hideKeyboard() {
        self.view.endEditing(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isModalInPresentation = true
        self.congratulationsLabel.text = String(format: text, self.device.productId, self.device.deviceId, self.device.role ?? "(not set)")
        self.nameField.text = self.device.name
    }

    @IBAction func handleTapSave(_ sender: Any) {
        if let name = self.nameField.text {
            if (name.count > 0) {
                self.device.name = name
                self.pairingConfirmedDelegate?.pairingConfirmed()
                do {
                    try BookmarkManager.shared.add(bookmark: self.device)
                } catch {
                    let banner = GrowingNotificationBanner(title: "Error", subtitle: "Could not add bookmark: \(error)")
                    banner.show()
                }
                dismiss(animated: true, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
