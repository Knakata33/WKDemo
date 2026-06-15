//
//  URL+Utill.swift
//  WKDemo
//
//  Created by nakata on 2026/06/15.
//

import Foundation

private extension URL {
    var displayText: String {
        host ?? absoluteString
    }
}
