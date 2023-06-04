//
//  Messenger.swift
//  SwiftyMessenger
//
//  Copyright © 2018 Abdullah Selek
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import CoreFoundation
import Foundation

public enum TransitingType {
    case file
    case coordinatedFile
    case binary
}


/**
  Interface for classes wishing to support the transiting of data
  between container app and extension. Transiting is defined as passage between two points, and in this
  case it involves both the reading and writing of messages as well as the deletion of message
  contents.
 */
public protocol FileTransiting {

    /**
      Responsible for writing a given message object in a persisted format for a given
      identifier. The method should return true if the message was successfully saved. The message object
      may be nil, in which case true should also be returned. Returning true from this method results in a
      notification being fired which will trigger the corresponding listener block for the given
      identifier.

      - parameter message: The message dictionary to be passed.
      This dictionary may be nil. In this the method should return true.
      - parameter identifier: The identifier for the message
      - return: `true` indicating that a notification should be sent and `false` otherwise
     */
    func writeMessage(message: Any?, identifier: String) -> Bool

    /**
      For reading and returning the contents of a given message. It should
      understand the structure of messages saved by the implementation of the above writeMessage
      method and be able to read those messages and return their contents.

      - parameter identifier: The identifier for the message
      - return: Optional message object
     */
    func messageForIdentifier(identifier: String?) -> Any?

    /**
      Clear the persisted contents of a specific message with a given identifier.

      - parameter identifier: The identifier for the message
     */
    func deleteContent(withIdentifier identifier: String?)

    /**
      Clear the contents of all messages passed to the Messenger.
     */
    func deleteContentForAllMessages()

}

/**
  Protocol used to notify container app and extension with identifier and message.
 */
public protocol TransitingDelegate {

    /**
      Notifier between two sides.

      - parameter identifier: The identifier for the message
      - parameter message: Message dictionary
     */
    func notifyListenerForMessage(withIdentifier identifier: String?, message: Any?)

}

open class MessengerFileTransiting: FileTransiting {

    internal var applicationGroupIdentifier: String!
    internal var directory: String?
    internal var fileManager: FileManager!

    internal convenience init() {
        self.init(withApplicationGroupIdentifier: "dev.messenger.nonDesignatedInitializer", directory: nil)
    }

    /**
     Initializer.

     - parameter identifier: An application group identifier
     - parameter directory: An optional directory to read/write messages
     */
    public init(withApplicationGroupIdentifier identifier: String?, directory: String?) {
        applicationGroupIdentifier = identifier
        self.directory = directory
        fileManager = FileManager()
    }

    // MARK: File Operation Methods

    internal func messagePassingDirectoryPath() -> String? {
        guard let appGroupContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            return nil
        }
        let appGroupContainerPath = appGroupContainer.path
        var directoryPath = appGroupContainerPath
        if let directory = directory {
            directoryPath = appGroupContainerPath.appendingPathComponent(path: directory)
        }
        do {
            try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("SwiftyMessenger: Error on messagePassingDirectoryPath \(error.description)")
            return nil
        }
        return directoryPath
    }

    internal func filePath(forIdentifier identifier: String) -> String? {
        if identifier.isEmpty {
            return nil
        }
        let directoryPath = messagePassingDirectoryPath()
        let fileName = String(format: "%@.archive", identifier)
        let filePath = directoryPath?.appendingPathComponent(path: fileName)
        return filePath
    }

    // MARK: FileTransiting

    open func writeMessage(message: Any?, identifier: String) -> Bool {
        if identifier.isEmpty {
            return false
        }
        guard let message = message else {
            return false
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: message) as NSData
        guard let filePath = self.filePath(forIdentifier: identifier) else {
            return false
        }
        let success = data.write(toFile: filePath, atomically: true)
        if !success {
            return false
        }
        return true
    }

    open func messageForIdentifier(identifier: String?) -> Any? {
        guard let identifier = identifier else {
            return nil
        }
        guard let filePath = self.filePath(forIdentifier: identifier) else {
            return nil
        }
        do {
            let data = try NSData(contentsOfFile: filePath) as Data
            let message = NSKeyedUnarchiver.unarchiveObject(with: data)
            return message
        } catch let error as NSError {
            NSLog("SwiftyMessenger: Error on messageForIdentifier \(error.description)")
            return nil
        }
    }

    open func deleteContent(withIdentifier identifier: String?) {
        guard let identifier = identifier else {
            NSLog("SwiftyMessenger: Can't delete content, given identifier is nil")
            return
        }
        do {
            try fileManager.removeItem(atPath: identifier)
        } catch let error as NSError {
            NSLog("SwiftyMessenger: Error on deleteContent \(error.description)")
        }
    }

    open func deleteContentForAllMessages() {
        guard let _ = directory, let directoryPath = messagePassingDirectoryPath() else {
            return
        }
        do {
            let messageFiles = try fileManager.contentsOfDirectory(atPath: directoryPath)
            for path in messageFiles {
                let filePath = directoryPath.appendingPathComponent(path: path)
                do {
                    try fileManager.removeItem(atPath: filePath)
                } catch let error as NSError {
                    NSLog("SwiftyMessenger: Error on deleteContentForAllMessages \(error.description)")
                }
            }
        } catch let error as NSError {
            NSLog("SwiftyMessenger: Error on deleteContentForAllMessages \(error.description)")
        }
    }

}


/**
  Creates a connection between a containing iOS application and an extension. Used to pass data or
  commands back and forth between the two locations.
 */
open class Messenger: TransitingDelegate {

    open var transitingDelegate: FileTransiting?
    private var listenerBlocks = [String: (Any) -> Void]()
    private static let NotificationName = NSNotification.Name(rawValue: "MessengerNotificationName")

    public init(withApplicationGroupIdentifier identifier: String?, directory: String?) {
        transitingDelegate = MessengerFileTransiting(withApplicationGroupIdentifier: identifier, directory: directory)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(Messenger.didReceiveMessageNotification(notification:)),
                                               name: Messenger.NotificationName,
                                               object: nil)
    }

    public convenience init(withApplicationGroupIdentifier identifier: String,
                            directory: String?,
                            transitingType: TransitingType) {
        self.init(withApplicationGroupIdentifier: identifier, directory: directory)
        switch transitingType {
        case .file:
            break
        case .coordinatedFile:
            transitingDelegate = MessengerCoordinatedFileTransiting(withApplicationGroupIdentifier: identifier, directory: directory)
        case .binary:
            transitingDelegate = MessengerBinaryFileTransiting(withApplicationGroupIdentifier: identifier, directory: directory)
        }
    }

    private func notificationCallBack(observer: UnsafeMutableRawPointer, identifier: String) {
        NotificationCenter.default.post(name: Messenger.NotificationName, object:observer, userInfo: ["identifier": identifier])
    }

    private func registerForNotification(withIdentifier identifier: String) {
        unregisterForNotification(withIdentifier: identifier)
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let str = identifier as CFString
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterAddObserver(notificationCenter, observer, {
            (notificationCenter, observer, notificationName, rawPointer, dictionary)  -> Void in
            if let observer = observer, let notificationName = notificationName {
                let mySelf = Unmanaged<Messenger>.fromOpaque(observer).takeUnretainedValue()
                mySelf.notificationCallBack(observer: observer, identifier: notificationName.rawValue as String)
            }
        }, str, nil, .deliverImmediately)
    }

    private func unregisterForNotification(withIdentifier identifier: String) {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let str = identifier as CFString
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterRemoveObserver(notificationCenter, observer, CFNotificationName(str), nil)
    }

    @objc private func didReceiveMessageNotification(notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let identifier = userInfo["identifier"] as? String else {
            return
        }
        let message = transitingDelegate?.messageForIdentifier(identifier: identifier)
        notifyListenerForMessage(withIdentifier: identifier, message: message)
    }

    open func notifyListenerForMessage(withIdentifier identifier: String?, message: Any?) {
        guard let identifier = identifier, let message = message else {
            return
        }
        guard let listenerBlock = listenerBlock(forIdentifier: identifier) else {
            return
        }
        DispatchQueue.main.async {
            listenerBlock(message)
        }
    }

    private func listenerBlock(forIdentifier identifier: String) -> ((Any) -> Void)? {
        return listenerBlocks[identifier]
    }

    private func sendNotification(forMessageIdentifier identifier: String) {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let deliverImmediately = true
        let str = identifier as CFString
        CFNotificationCenterPostNotification(notificationCenter, CFNotificationName(str), nil, nil, deliverImmediately)
    }

    /**
      Passes a message associated with a given identifier. This is the primary means
      of passing information through the messenger.
     */
    open func passMessage(message: Any?, identifier: String?) {
        guard let identifier = identifier else {
            return
        }
        if transitingDelegate?.writeMessage(message: message, identifier: identifier) == true {
            sendNotification(forMessageIdentifier: identifier)
        }
    }

    /**
      Returns the value of a message with a specific identifier as an object.
     */
    open func messageForIdentifier(identifier: String?) -> Any? {
        return transitingDelegate?.messageForIdentifier(identifier: identifier)
    }

    /**
      Clears the contents of a specific message with a given identifier.
     */
    open func clearMessageContents(identifer: String?) {
        transitingDelegate?.deleteContent(withIdentifier: identifer)
    }

    /**
      Clears the contents of your optional message directory to give you a clean state.
     */
    open func clearAllMessageContents() {
        transitingDelegate?.deleteContentForAllMessages()
    }

    /**
      Begins listening for notifications of changes to a message with a specific identifier.
      If notifications are observed then the given listener block will be called along with the actual
      message.
     */
    open func listenForMessage(withIdentifier identifier: String?, listener: @escaping ((Any) -> Void)) {
        guard let identifier = identifier else {
            return
        }
        listenerBlocks[identifier] = listener
        registerForNotification(withIdentifier: identifier)
    }

    /**
      Stops listening for change notifications for a given message identifier.
     */
    open func stopListeningForMessage(withIdentifier identifier: String?) {
        guard let identifier = identifier else {
            return
        }
        listenerBlocks[identifier] = nil
        unregisterForNotification(withIdentifier: identifier)
    }

}


/**
  Inherits from the default implementation of the FileTransiting protocol
  and implements message transiting in a similar way but using FileCoordinator for its file
  reading and writing.
 */
open class MessengerCoordinatedFileTransiting: MessengerFileTransiting {

    open var additionalFileWritingOptions: NSData.WritingOptions!

    override open func writeMessage(message: Any?, identifier: String) -> Bool {
        if identifier.isEmpty {
            return false
        }
        guard let message = message else {
            return false
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: message)
        guard let filePath = self.filePath(forIdentifier: identifier) else {
            return false
        }
        let fileURL = URL(fileURLWithPath: filePath)
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        var error: NSError?
        var success = false
        fileCoordinator.coordinate(readingItemAt: fileURL,
                                   options: NSFileCoordinator.ReadingOptions(rawValue: 0),
                                   error: &error) { newURL in
            do {
                try data.write(to: newURL, options: [.atomic/*, additionalFileWritingOptions*/])
                success = true
                
            } catch let error as NSError {
                NSLog("SwiftyMessenger: Error on writeMessage \(error.description)")
                success = false
            }
        }
        return success
    }

    override open func messageForIdentifier(identifier: String?) -> Any? {
        guard let identifier = identifier, let filePath = filePath(forIdentifier: identifier)  else {
            return nil
        }
        let fileURL = URL(fileURLWithPath: filePath)
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        var error: NSError?
        var data: NSData? = nil
        fileCoordinator.coordinate(readingItemAt: fileURL,
                                   options: NSFileCoordinator.ReadingOptions(rawValue: 0),
                                   error: &error) { newURL in
            data = NSData(contentsOf: newURL)
        }
        guard let filledData = data as Data? else {
            return nil
        }
        let message = NSKeyedUnarchiver.unarchiveObject(with: filledData)
        return message
    }

}



extension String {

    func appendingPathComponent(path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }

}


open class MessengerBinaryFileTransiting: MessengerFileTransiting {

    override open func writeMessage(message: Any?, identifier: String) -> Bool {
        if identifier.isEmpty {
            return false
        }
        guard let message = message as? Data else {
            return false
        }
        guard let filePath = self.filePath(forIdentifier: identifier) else {
            return false
        }
        let fileURL = URL(fileURLWithPath: filePath)
        var success = false
        do {
            try message.write(to: fileURL, options: .atomic)
            success = true
        } catch _ as NSError {
            success = false
        }
        return success
    }

    override open func messageForIdentifier(identifier: String?) -> Any? {
        guard let identifier = identifier, let filePath = filePath(forIdentifier: identifier)  else {
            return nil
        }
        let fileURL = URL(fileURLWithPath: filePath)
        let message = NSData(contentsOf: fileURL)
        return message
    }

}


public let wmessager = Messenger(withApplicationGroupIdentifier: "group.com.mh.Python3IDE", directory: "transmsg", transitingType: .coordinatedFile)


public let binaryWMessager = Messenger(withApplicationGroupIdentifier: "group.com.mh.Python3IDE", directory: "transmsg", transitingType: .binary)
