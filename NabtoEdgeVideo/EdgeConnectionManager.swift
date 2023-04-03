//
//  EdgeManager.swift
//  Nabto Edge Video
//

import UIKit
import Network
import NabtoEdgeClient

public enum DeviceError : Error {
    // fingerprint changed on device since pairing
    case DEVICE_IDENTITY_CHANGED
}

fileprivate class EdgeConnectionWrapper : ConnectionEventReceiver {
    var isClosed: Bool = false
    let target: Bookmark
    let connection: Connection

    func onEvent(event: NabtoEdgeClientConnectionEvent) {
        if (event == NabtoEdgeClientConnectionEvent.CLOSED) {
            self.isClosed = true
            NSLog("Connection to \(target) closed, notifying listeners")
            NotificationCenter.default.post(
                    name: NSNotification.Name(EdgeConnectionManager.eventNameConnectionClosed),
                    object: target)
        }
    }

    init(target: Bookmark, connection: Connection) throws {
        self.target = target
        self.connection = connection
        try connection.addConnectionEventsReceiver(cb: self)
    }

    func stop() {
        self.connection.removeConnectionEventsReceiver(cb: self)
        self.connection.stop()
    }
}

class EdgeConnectionManager {
    internal static let eventNameConnectionClosed = "EDGE_CONNECTION_CLOSED"
    internal static let eventNameNoNetwork        = "EDGE_NO_NETWORK"
    internal static let eventNameNetworkAvailable = "EDGE_NETWORK_AVAILABLE"
    internal static let shared = EdgeConnectionManager()

    private var cache: [Bookmark:EdgeConnectionWrapper] = [:]
    private var client_: NabtoEdgeClient.Client! = nil
    private let logLevel = "info"
    private let monitor = NWPathMonitor()
    private let cacheQueue = DispatchQueue(label: "cacheQueue")
    private let clientQueue = DispatchQueue(label: "clientQueue")
    private let monitorQueue = DispatchQueue.global()
    private var networkAvailable = true

    private init() {
        self.monitor.pathUpdateHandler = { [weak self] path in
            self?.handleNetworkPathUpdated(path)
        }
        self.monitor.start(queue: self.monitorQueue)
    }

    internal var client: NabtoEdgeClient.Client {
        get {
            self.clientQueue.sync {
                if (self.client_ == nil) {
                    self.client_ = NabtoEdgeClient.Client()
//                    self.client_.setLogCallBack(cb: EdgeConnectionManager.traceOnlyApiCalls)
                    self.client_.enableNsLogLogging()
                    try! self.client_.setLogLevel(level: self.logLevel)
                    print("Initialized Nabto Edge Client SDK version \(NabtoEdgeClient.Client.versionString())")
                }
                return self.client_
            }
        }
    }

    private func handleNetworkPathUpdated(_ path: NWPath) {
        if (path.status == .satisfied) {
            if (!self.networkAvailable) {
                self.networkAvailable = true
                NotificationCenter.default.post(
                        name: NSNotification.Name(EdgeConnectionManager.eventNameNetworkAvailable),
                        object: nil)
            }
        } else {
            self.networkAvailable = false
            NotificationCenter.default.post(
                    name: NSNotification.Name(EdgeConnectionManager.eventNameNoNetwork),
                    object: nil)
        }
    }

    private static func traceOnlyApiCalls(msg: NabtoEdgeClientLogMessage) {
        //if (msg.severity < 3 || msg.message.range(of: "coap_exec|connection_connect",
        if (msg.severity < 3 || msg.message.range(of: "#[0-9]{1,6} called|ended",
                options: .regularExpression, range: nil, locale: nil) != nil) {
            NSLog("Nabto log: \(msg.file):\(msg.line) [\(msg.severity)/\(msg.severityString)]: \(msg.message)")
        }
    }

    func isStopped() -> Bool {
        self.clientQueue.sync {
            return self.client_ == nil
        }
    }

    func reset() {
        self.cacheQueue.sync {
            for (_, value) in self.cache {
                value.stop()
            }
            self.cache = [:]
        }
        self.clientQueue.sync {
            self.monitor.cancel()
            self.client_?.stop()
            self.client_ = nil
        }
    }

    func getConnection(_ target: Bookmark) throws -> Connection {
        var cached: EdgeConnectionWrapper?
        cacheQueue.sync {
            cached = cache[target]
        }
        if (cached == nil || cached!.isClosed) {
            let newConnection = try doConnect(target)
            try cacheQueue.sync {
                cache[target] = try EdgeConnectionWrapper(target: target, connection: newConnection)
            }
            return newConnection
        } else {
            return cached!.connection
        }
    }

    func removeConnection(_ target: Bookmark) {
        cacheQueue.sync {
            let connection = cache.removeValue(forKey: target)
            connection?.stop()
        }
    }

    func doConnect(_ target: Bookmark) throws -> Connection {
        let connection = try self.client.createConnection()
        try connection.setProductId(id: target.productId)
        try connection.setDeviceId(id: target.deviceId)
        guard let key = ProfileTools.getSavedPrivateKey() else {
            throw NabtoEdgeClientError.FAILED_WITH_DETAIL(detail: "Private key not set")
        }
        try connection.setPrivateKey(key: key)
        if let sct = target.sct {
            try connection.setServerConnectToken(sct: sct)
        }
        try connection.connect()
        if let fp = target.deviceFingerprint {
            if (try connection.getDeviceFingerprintHex() != fp) {
                throw DeviceError.DEVICE_IDENTITY_CHANGED
            }
        }
        return connection
    }

}
