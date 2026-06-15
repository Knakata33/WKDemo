//
//  URL+Utill.swift
//  WKDemo
//
//  Created by nakata on 2026/06/15.
//

import Foundation

extension URL {
    var displayText: String {
        guard let host else {
            return absoluteString
        }
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        return host
    }
}
