//
//  FileManager+Support.swift
//  WKDemo
//
//  Created by nakata on 2020/12/08.
//

import Foundation

public extension FileManager {
    @discardableResult
    func ensureExistence(ofDirectoryPath dir: String) -> String {
        var isDirectory: ObjCBool = false
        if self.fileExists(atPath: dir, isDirectory: &isDirectory) {
            assert(isDirectory.boolValue)
            return dir
        }
        //エラー無視して大丈夫？
        //ディレクトリかどうかチェックしないで大丈夫？
        do {
            try self.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            assert(false)
            debugPrint("Failed to createDirectory. \(error.localizedDescription)" as NSString)
        }
        return dir
    }
    
    @discardableResult
    func ensureExistence(ofDirectoryURL url: URL) -> URL {
        assert(url.isFileURL)
        let path = self.ensureExistence(ofDirectoryPath: url.path)
        return URL(fileURLWithPath: path)
    }
    
    enum ContentType {
        case directory
        case file
    }
    func contentType(atPath path: String) -> ContentType? {
        var isDirectory: ObjCBool = false
        guard self.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return nil
        }
        return isDirectory.boolValue ? .directory : .file
    }
    
    func fileExistsInDirectory(of url: URL) -> Bool {
        assert(url.isFileURL)
        guard let enumerator = self.enumerator(atPath: url.path) else {
            return false
        }
        // debugPrint("fileExistsInDirectory: \(url) [" as NSString)
        while let content = enumerator.nextObject() as? String {
            let contentURL = url.appendingPathComponent(content)
            // debugPrint("content: \(content), contentURL: \(contentURL), " as NSString)
            if self.contentType(atPath: contentURL.path) == .file {
                // debugPrint("... ] File detected." as NSString)
                return true
            }
        }
        // debugPrint("] No file." as NSString)
        return false
    }
}

