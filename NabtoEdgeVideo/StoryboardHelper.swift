//
//  StoryboardHelper.swift
//  Nabto Edge Video
//
//  Created by Nabto on 03/02/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

import UIKit

// To add custom view controllers for your devices:
// 1 - Create a subclass of DeviceViewController
// 2 - Add it to the storyboard with correct storyboardID
// 3 - Add it to the options in this method

class StoryboardHelper {

    class func getViewController(id: String) -> ViewControllerWithDevice {
        let storyboard =  UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: id) as! ViewControllerWithDevice
        return controller
    }

    class func viewControllerFor(device: Bookmark) -> DeviceDetailsViewController? {
        let controller: DeviceDetailsViewController? = getViewController(id: "EdgeDeviceViewController") as! EdgeDeviceViewController
        controller?.device = device
        return controller
    }
}
