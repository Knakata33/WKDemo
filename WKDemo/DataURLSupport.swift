//
//  DataURLSupport.swift
//
//  Created by nakata on 2020/12/08.
//

import Foundation

enum DataURLSupport {
    static func mimeType(of dataURL: URL) -> String? {
        let string = dataURL.absoluteString
        guard string.hasPrefix("data:") else {
            return nil
        }
        guard let startIndex = string.range(of: ":")?.upperBound else {
            return nil
        }
        // データURLの形式 https://ja.wikipedia.org/wiki/Data_URI_scheme
        // > data:[<MIME-type>][;charset=<encoding>][;base64],<data>
        
        // 末尾の`,<data>`の先頭位置を探索
        guard let endIndex = string.firstIndex(of: ",") else {
            return nil
        }
        guard startIndex < endIndex else {
            return nil
        }
        let component = String(string[startIndex..<endIndex])
        assert(!component.isEmpty)
        
        // componentに`[;charset=<encoding>][;base64]`が含まれていた場合は、その前の部分に`[<MIME-type>]`がある
        guard let subDelimIndex = component.firstIndex(of: ";") else {
            return component
        }
        guard component.startIndex < subDelimIndex else {
            return nil
        }
        let subComponent = String(component[..<subDelimIndex])
        assert(!subComponent.isEmpty)
        return subComponent
    }
}
