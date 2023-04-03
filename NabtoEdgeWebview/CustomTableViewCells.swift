//
//  CustomTableViewCells.swift
//  Nabto Edge Video
//
//  Created by Nabto on 01/02/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

import UIKit
import NabtoEdgeClient
import NabtoEdgeIamUtil

class DeviceRowModel {
    var bookmark: Bookmark
    var isPaired: Bool = false
    var isOnline: Bool? = nil
    var error: String? = nil
    var id: String {
        get {
            return "\(self.bookmark.productId).\(self.bookmark.deviceId)"
        }
    }

    init(bookmark: Bookmark) {
        self.bookmark = bookmark
    }

    internal func populateWithDetails() throws {
        do {
            let connection = try EdgeConnectionManager.shared.getConnection(self.bookmark)
            self.isOnline = true
            let user = try NabtoEdgeIamUtil.IamUtil.getCurrentUser(connection: connection)
            if let role = user.Role {
                self.isPaired = true
                self.bookmark.role = role
            } else {
                self.isPaired = false
            }
        } catch NabtoEdgeClientError.NO_CHANNELS(_, _) {
            self.isOnline = false
        } catch IamError.USER_DOES_NOT_EXIST {
            self.isPaired = false
        } catch {
            print("Device \(bookmark.name) is not available due to error: \(error)")
            self.isOnline = false
        }
    }

}

//Device cell on overview and discover screens
class DeviceCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var deviceIdLabel: UILabel!
    @IBOutlet weak var statusIcon: UIImageView!
    @IBOutlet weak var deviceIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(device: DeviceRowModel) {
        nameLabel.text = device.bookmark.name ?? device.id
        deviceIdLabel.text = device.id
        deviceIcon?.isHidden = false
        if let error = device.error {
            deviceIcon?.image = UIImage(systemName: "exclamationmark.triangle")?.withRenderingMode(.alwaysTemplate)
        } else {
            deviceIcon?.image = UIImage(systemName: "thermometer")?.withRenderingMode(.alwaysTemplate)
        }
    }
}

//Empty list warning cell - overview and discover
class NoDevicesCell: UITableViewCell {
    
    @IBOutlet weak var indicator    : UIActivityIndicatorView!
    @IBOutlet weak var messageView  : UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(waiting: Bool) {
        self.messageView.isHidden = waiting
        self.indicator.isHidden = !waiting
        if waiting {
            self.indicator.startAnimating()
        } else {
            self.indicator.stopAnimating()
        }
    }
}

class OverviewButtonCell: UITableViewCell {
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var addNewButton : UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        refreshButton.clipsToBounds = true
        addNewButton.clipsToBounds  = true
        refreshButton.layer.cornerRadius = 6
        addNewButton.layer.cornerRadius  = 6
        refreshButton.imageView?.tintColor = UIColor.black
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class DiscoverButtonCell: UITableViewCell {
    
    @IBOutlet weak var refreshButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        refreshButton.clipsToBounds = true
        refreshButton.layer.cornerRadius = 6
        refreshButton.imageView?.tintColor = UIColor.white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

