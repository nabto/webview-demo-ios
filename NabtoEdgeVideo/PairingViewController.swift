//
//  PairingViewController.swift
//  Nabto Edge Video
//
//  Created by Nabto on 31/01/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

import UIKit
import NabtoEdgeIamUtil
import NabtoEdgeClient
import NotificationBannerSwift

class PairingViewController: UIViewController, PairingConfirmedListener, UITextFieldDelegate {

    @IBOutlet weak var nameLabel        : UILabel!
    @IBOutlet weak var deviceIdLabel    : UILabel!
    @IBOutlet weak var confirmLabel     : UILabel!
    @IBOutlet weak var confirmView      : UIView!
    @IBOutlet weak var resultView       : UIView!
    @IBOutlet weak var confirmButton    : UIButton!
    @IBOutlet weak var passwordField    : UITextField!
    @IBOutlet weak var usernameField    : UITextField!
    
    var device : Bookmark?
    var pairingStringPassword: String?

    let defaultPairingText = "You are about to pair with the above device."
    let passwordText = "This device requires a password for pairing:"
    let errorText = "Error! Could not connect to device for pairing."

    let confirmSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        confirmButton.clipsToBounds     = true
        confirmButton.layer.cornerRadius    = 6
        confirmButton.addSubview(confirmSpinner)
        confirmSpinner.leftAnchor.constraint(equalTo: confirmButton.leftAnchor, constant: 20.0).isActive = true
        confirmSpinner.centerYAnchor.constraint(equalTo: confirmButton.centerYAnchor).isActive = true

        // dismiss keyboard when tapping background or return key
        let tapGesture = UITapGestureRecognizer(target: self,
                action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        self.passwordField.delegate = self
        self.usernameField.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let device = device {
            self.nameLabel.text = device.name
            self.deviceIdLabel.text = "\(device.productId).\(device.deviceId)"
            self.passwordField.isHidden = true
            self.confirmLabel.text = String(format: self.defaultPairingText, device.productId, device.deviceId)
            self.usernameField.text = UIDevice.current.name
        } else {
            self.confirmLabel.text = "Error! No device to pair with!"
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        passwordField.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let device = sender as? Bookmark else { return }
        if let destination = segue.destination as? DeviceDetailsViewController {
            destination.device = device
        }
    }

    // MARK: - IB actions

    @IBAction func confirmPairing(_ sender: Any) {
        guard let device = device else { return }
        self.confirmSpinner.startAnimating()
        DispatchQueue.global().async {
            self.performPairing(device: device)
            DispatchQueue.main.async {
                self.confirmSpinner.stopAnimating()
            }
        }
    }

    @IBAction func goToHome(_ sender: Any) {
        _ = navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Keyboard input

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    @objc private func hideKeyboard() {
        self.view.endEditing(true)
    }

    // MARK: - Implementation

    func pairingConfirmed() {
        self.navigationController?.popToRootViewController(animated: true)
    }

    private func showPairingError(_ msg: String) {
        DispatchQueue.main.async {
            let banner = GrowingNotificationBanner(title: "Pairing Error", subtitle: msg, style: .danger)
            banner.show()
        }
    }

    private func showConfirmation() {
        DispatchQueue.main.sync {
            let controller = StoryboardHelper.getViewController(id: "PairingConfirmedViewController") as! PairingConfirmedViewController
            controller.device = self.device
            controller.pairingConfirmedDelegate = self
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func performPairing(device: Bookmark) {
        do {
            let modes = try IamUtil.getAvailablePairingModes(connection: EdgeConnectionManager.shared.getConnection(device))
            if (modes.count == 0) {
                self.showPairingError("Device is not open for pairing - please contact the owner. If you are the owner, you can factory reset it to get access again.")
            } else {
                if (modes.contains(PairingMode.LocalInitial)) {
                    try self.pairLocalInitial()
                } else if (modes.contains(PairingMode.LocalOpen)) {
                    try self.pairLocalOpen()
                } else if (modes.contains(PairingMode.PasswordOpen)) {
                    try self.pairPasswordOpen()
                } else {
                    self.showPairingError("This app only supports initial and open pairing modes - please reconfigure target device")
                }
                if (try IamUtil.isCurrentUserPaired(connection: EdgeConnectionManager.shared.getConnection(device))) {
                    try self.updateBookmarkWithDeviceInfo(device)
                    self.showConfirmation()
                }
            }
        } catch IamError.USERNAME_EXISTS {
            self.showPairingError("Name already in use on device - please change the name and try again")
            DispatchQueue.main.sync {
                self.usernameField.becomeFirstResponder()
            }
        } catch IamError.AUTHENTICATION_ERROR {
            self.showPairingError("Pairing password not valid for this device")
            if (self.pairingStringPassword != nil) {
                self.handleBadPairingStringPassword()
            }
        } catch IamError.BLOCKED_BY_DEVICE_CONFIGURATION {
            self.showPairingError("The device's IAM configuration is not valid - it must allow pairing")
        } catch NabtoEdgeClientError.NO_CHANNELS(_, _) {
            self.showPairingError("Could not connect to device for pairing - device offline or invalid id in pairing string")
        } catch {
            self.showPairingError("An error occurred when pairing with device: \(error)")
        }
    }

    private func handleBadPairingStringPassword() {
        DispatchQueue.main.sync {
            // enable user to edit password
            self.passwordField.isHidden = false
            self.passwordField.text = self.pairingStringPassword

            // do not try automatic pairing again using password from pairing string
            self.pairingStringPassword = nil
        }
    }

    private func pairLocalInitial() throws {
        guard let device = self.device else { return }
        let connection = try EdgeConnectionManager.shared.getConnection(device)
        try IamUtil.pairLocalInitial(connection: connection)

        var userInput: String?
        DispatchQueue.main.sync {
            userInput = self.usernameField.text
        }
        if let user = userInput {
            let validUserName = ProfileTools.convertToValidUsername(input: user)
            self.updateDisplayName(connection: connection, username: validUserName, displayName: user)
        }
    }

    private func pairLocalOpen() throws {
        guard let device = self.device else { return }
        let connection = try EdgeConnectionManager.shared.getConnection(device)
        var userInput: String?
        DispatchQueue.main.sync {
            userInput = self.usernameField.text
        }
        if let user = userInput {
            let validUserName = ProfileTools.convertToValidUsername(input: user)
            try IamUtil.pairLocalOpen(connection: connection, desiredUsername: validUserName)
            self.updateDisplayName(connection: connection, username: validUserName, displayName: user)
        }
    }

    private func pairPasswordOpen() throws {
        guard let device = self.device else { return }

        var password: String? = nil
        var user: String? = nil
        DispatchQueue.main.sync {
            // if available, try password from pairing string
            if let pairingStringPassword = self.pairingStringPassword {
                password = pairingStringPassword
            } else {
                // otherwise show password input field
                if (self.passwordField.isHidden) {
                    self.confirmLabel.text = self.passwordText
                    self.passwordField.isHidden = false
                    self.passwordField.becomeFirstResponder()
                } else if let userPassword = self.passwordField.text {
                    password = userPassword
                }
            }
            user = self.usernameField.text
        }
        if let password = password, let user = user {
            let validUserName = ProfileTools.convertToValidUsername(input: user)
            let connection = try EdgeConnectionManager.shared.getConnection(device)
            try IamUtil.pairPasswordOpen(connection: connection, desiredUsername: validUserName, password: password)
            self.updateDisplayName(connection: connection, username: validUserName, displayName: user)
        }
    }

    private func updateBookmarkWithDeviceInfo(_ device: Bookmark) throws {
        let connection = try EdgeConnectionManager.shared.getConnection(device)
        let user = try IamUtil.getCurrentUser(connection: connection)
        device.role = user.Role
        device.sct = user.Sct
        let details = try IamUtil.getDeviceDetails(connection: connection)
        if let appname = details.AppName {
            device.name = appname
        }
        device.deviceFingerprint = try connection.getDeviceFingerprintHex()
    }

    private func updateDisplayName(connection: Connection, username: String, displayName: String) {
        do {
            try IamUtil.updateUserDisplayName(connection: connection, username: username, displayName: displayName)
        } catch (IamError.BLOCKED_BY_DEVICE_CONFIGURATION) {
            print("Device IAM config does not support setting display name (tried setting \(displayName) for user \(username))")
        } catch {
            print("Unexpected error when setting display name: \(error)")
        }
    }

}
