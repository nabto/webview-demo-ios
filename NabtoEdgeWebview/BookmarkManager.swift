//
//  BookmarkManager.swift
//  Nabto Edge Video
//
//  Created by Nabto on 03/02/2022.
//  Copyright © 2022 Nabto. All rights reserved.
//

import UIKit

class Bookmark : Equatable, Hashable, CustomStringConvertible, Codable {
    let deviceId: String
    let productId: String
    var timeAdded: Date?
    var sct: String?
    var name : String = "Anonymous Device"
    var modelName: String?
    var role: String?
    var deviceFingerprint: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(deviceId)
        hasher.combine(productId)
    }

    static func ==(lhs: Bookmark, rhs: Bookmark) -> Bool {
        if lhs.deviceId != rhs.deviceId {
            return false
        }
        if lhs.productId != rhs.productId {
            return false
        }
        return true
    }

    var description: String {
        "Bookmark(deviceId: \(deviceId), productId: \(productId), timeAdded: \(timeAdded), sct: \(sct), name: \(name), modelName: \(modelName), role: \(role))"
    }

    init(deviceId: String, productId: String, creationTime: Date?=nil, sct: String?=nil, name: String?=nil, modelName: String?=nil, role: String?=nil) {
        self.deviceId = deviceId
        self.productId = productId
        self.timeAdded = creationTime
        self.sct = sct
        if let name = name {
            self.name = name
        }
        self.modelName = modelName
        self.role = role
    }
}

class BookmarkManager {

    static let shared = BookmarkManager()
    private var initialized: Bool = false

    var deviceBookmarks: [Bookmark] = []

    func add(bookmark: Bookmark) throws {
        let index = self.deviceBookmarks.firstIndex(of: bookmark)
        if let index = index {
            self.deviceBookmarks.remove(at: index)
        }
        bookmark.timeAdded = Date()
        self.deviceBookmarks.append(bookmark)
        try self.saveBookmarks()
    }
    
    func saveBookmarks() throws {
        let data = try JSONEncoder().encode(self.deviceBookmarks)
        let url = bookmarksFileURL()
        try data.write(to: url, options: .atomic)
    }
    
    func loadBookmarks() throws {
        let url = bookmarksFileURL()
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        let data = try Data(contentsOf: url)
        var bookmarks: [Bookmark] = try JSONDecoder().decode([Bookmark].self, from: data)
        self.deviceBookmarks = bookmarks.sorted(by: {
            if ($0.timeAdded != nil && $1.timeAdded != nil) {
                return $0.timeAdded! < $1.timeAdded!
            } else {
                return false
            }
        })
    }
    
    func clearBookmarks() {
        self.deviceBookmarks = []
        let url = bookmarksFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(atPath: url.path)
        }
    }

    func exists(_ bookmark: Bookmark) -> Bool {
        return self.deviceBookmarks.contains(bookmark)
    }

    func bookmarksFileURL() -> URL {
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: directory).appendingPathComponent("bookmarks.json")
    }
}
