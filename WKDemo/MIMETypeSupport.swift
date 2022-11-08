//
//  MIMETypeSupport.swift
//
//  Created by nakata on 2020/03/04.
//

import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

public enum MIMETypeSupport {
    public static func preferredPathExtension(mimeType: String) -> String? {
        if #available(iOSApplicationExtension 14.0, *) {
            guard let uti = UTType(mimeType: mimeType) else {
                return nil
            }
            return uti.preferredFilenameExtension
        } else {
            guard let uti = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassMIMEType,
                mimeType as CFString,
                nil
            )?.takeRetainedValue() else {
                return nil
            }
            guard let pathExtension = UTTypeCopyPreferredTagWithClass(
                uti as CFString,
                kUTTagClassFilenameExtension
            )?.takeRetainedValue() else {
                return nil
            }
            return pathExtension as String
        }
    }
}
