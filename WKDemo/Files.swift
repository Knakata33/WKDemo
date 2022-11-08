//
//  TemporaryFile.swift
//
//  Created by nakata on 2020/12/08.
//
//

import Foundation

public protocol FileProtocol: AnyObject {
    var url: URL! { get }
    var path: String! { get }
}
extension FileProtocol {
    public var fileSize: UInt64? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: self.path) else {
            return nil
        }
        return attrs[.size] as? UInt64
    }
}

public class File: NSObject, FileProtocol {
    public var url: URL!
    
    public var path: String! {
        return url.path
    }
    public init(url: URL) {
        assert(url.isFileURL)
        self.url = url
    }
    public convenience init(path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }
}

public class TemporaryFile: NSObject, FileProtocol {
    private static let doneUnsafeRemoveTemporaryDirectory = AtomicBool()
    public static func unsafeRemoveTemporaryDirectoryOnce() {
        guard !doneUnsafeRemoveTemporaryDirectory.getAndSet(value: true) else {
            return
        }
        
        let rootPath = FileManager.default.temporaryDirectory.appendingPathComponent("WKDemo").path
        guard FileManager.default.fileExists(atPath: rootPath) else {
            return
        }
        debugPrint("[TemporaryFile.unsafeRemoveTemporaryDirectoryOnce] Begin" as NSString)
        do {
            try FileManager.default.removeItem(atPath: rootPath)
            debugPrint("[TemporaryFile.unsafeRemoveTemporaryDirectoryOnce] Success" as NSString)
        } catch let error {
            debugPrint("[TemporaryFile.unsafeRemoveTemporaryDirectoryOnce] Failure \(error.localizedDescription)" as NSString)
        }
    }
    
    public static func linkItem(at url: URL) throws -> TemporaryFile {
        assert(url.isFileURL)
        let tempFile = TemporaryFile(pathExtension: url.pathExtension)
        try FileManager.default.linkItem(at: url, to: tempFile.url)
        return tempFile
    }
    
    public static func linkItem(atPath path: String) throws -> TemporaryFile {
        let url = URL(fileURLWithPath: path)
        let tempFile = TemporaryFile(pathExtension: url.pathExtension)
        try FileManager.default.linkItem(atPath: url.path, toPath: tempFile.path)
        return tempFile
    }
    
    public static func makeURL(pathExtension: String? = nil, directoryName: String? = nil) -> URL {
        let fileName: String
        if let pathExtension = pathExtension {
            if !pathExtension.isEmpty {
                fileName = "\(UUID().uuidString).\(pathExtension)"
            } else {
                fileName = UUID().uuidString
            }
        } else {
            fileName = UUID().uuidString
        }
        
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        if let directoryName = directoryName, !directoryName.isEmpty {
            let dirURL = FileManager.default.ensureExistence(ofDirectoryURL: temporaryDirectoryURL.appendingPathComponent("WKDemo/\(directoryName)"))
            return dirURL.appendingPathComponent(fileName)
        } else {
            let dirURL = FileManager.default.ensureExistence(ofDirectoryURL: temporaryDirectoryURL.appendingPathComponent("WKDemo"))
            return dirURL.appendingPathComponent(fileName)
        }
    }
    public static func makePath(pathExtension: String? = nil, directoryName: String? = nil) -> String {
        return makeURL(pathExtension: pathExtension, directoryName: directoryName).path
    }
    
    
    private(set) public var url: URL!
    public var path: String! {
        return url?.path
    }
    
    public init(pathExtension: String? = nil, directoryName: String? = nil) {
        self.url = TemporaryFile.makeURL(pathExtension: pathExtension, directoryName: directoryName)
    }
    
    public init?(attach url: URL) {
        guard url.isFileURL else {
            return nil
        }
        self.url = url
    }
    
    public init(attachPath path: String) {
        self.url = URL(fileURLWithPath: path)
    }
    
    public func rename(to newFileName: String) throws {
        guard let currentURL = self.url else {
            return
        }
        let currentFileName = currentURL.lastPathComponent
        if currentFileName == newFileName {
            return
        }
        
        let newURL = currentURL.deletingLastPathComponent().appendingPathComponent(newFileName)
        if FileManager.default.fileExists(atPath: currentURL.path) {
            if FileManager.default.fileExists(atPath: newURL.path) {
                try FileManager.default.removeItem(at: newURL)
            }
            try FileManager.default.moveItem(at: currentURL, to: newURL)
        }
        self.url = newURL
    }
    
    public func move(to url: URL, detach: Bool = false) throws {
        assert(url.isFileURL)
        guard let currentURL = self.url else {
            return
        }
        if currentURL.path == url.path {
            return
        }
        
        if FileManager.default.fileExists(atPath: currentURL.path) {
            if FileManager.default.fileExists(atPath: url.path) {
                //TODO バックアップしたほうがいいかも。moveItemでエラーが出てしまうと、ファイルがなくなってしまう。
                try FileManager.default.removeItem(at: url)
            }
            try FileManager.default.moveItem(at: currentURL, to: url)
        }
        if detach {
            self.url = nil
        } else {
            self.url = url
        }
    }
    
    public func move(toPath path: String, detach: Bool = false) throws {
        return try move(to: URL(fileURLWithPath: path), detach: detach)
    }
    
    @discardableResult
    public func detach() -> URL! {
        let url = self.url
        self.url = nil
        return url
    }
    
    @discardableResult
    public func detachPath() -> String! {
        return detach()?.path
    }
    
    deinit {
        guard let url = self.url else {
            return
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(atPath: url.path)
        } catch {
            debugPrint("[TemporaryFile.deinit] Faled to remove temporary file. \(error)" as NSString)
        }
    }
}

public class FileWithTemporaryDirectory: NSObject, FileProtocol {
    private let directory: TemporaryFile
    private let fileName: String
    
    public var url: URL! {
        return self.directory.url?.appendingPathComponent(self.fileName)
    }
    
    public var path: String! {
        return self.url?.path
    }
    
    public init(directory: TemporaryFile, fileName: String) {
        self.directory = directory
        self.fileName = fileName
    }
    
    @discardableResult
    public func detach() -> URL! {
        return self.directory.detach()?.appendingPathComponent(self.fileName)
    }
    
    @discardableResult
    public func detachPath() -> String! {
        return self.detach()?.path
    }
    
    public static func makeFile(nameAs name: String) -> FileWithTemporaryDirectory {
        let tempDir = TemporaryFile()
        FileManager.default.ensureExistence(ofDirectoryURL: tempDir.url)
        return FileWithTemporaryDirectory(directory: tempDir, fileName: name)
    }
    
    public static func copyItemToRename(at srcURL: URL, ensureNameAs dstName: String) throws -> FileWithTemporaryDirectory {
        assert(srcURL.isFileURL)
        let tempFileWithDir = makeFile(nameAs: dstName)
        try FileManager.default.copyItem(at: srcURL, to: tempFileWithDir.url)
        return tempFileWithDir
    }
    
    public static func copyItemToRename(atPath srcPath: String, ensureNameAs dstName: String) throws -> FileWithTemporaryDirectory {
        let tempFileWithDir = makeFile(nameAs: dstName)
        try FileManager.default.copyItem(atPath: srcPath, toPath: tempFileWithDir.path)
        return tempFileWithDir
    }
    
    public static func moveItemToRename(at srcURL: URL, ensureNameAs dstName: String) throws -> FileWithTemporaryDirectory {
        assert(srcURL.isFileURL)
        let tempFileWithDir = makeFile(nameAs: dstName)
        try FileManager.default.moveItem(at: srcURL, to: tempFileWithDir.url)
        return tempFileWithDir
    }
    
    public static func moveItemToRename(atPath srcPath: String, ensureNameAs dstName: String) throws -> FileWithTemporaryDirectory {
        let tempFileWithDir = makeFile(nameAs: dstName)
        try FileManager.default.moveItem(atPath: srcPath, toPath: tempFileWithDir.path)
        return tempFileWithDir
    }
}
