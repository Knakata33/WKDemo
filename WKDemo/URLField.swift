//
//  URLField.swift
//  WKDemo
//
//  Created by nakata on 2020/12/08.
//

import UIKit

@IBDesignable
class URLField: UITextField {
    var canPerformEditAction: Bool = true
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(cut(_:)), #selector(paste(_:)):
            if canPerformEditAction {
                return super.canPerformAction(action, withSender: sender)
            }
            return false
        case #selector(selectAll(_:)), #selector(copy(_:)):
            return super.canPerformAction(action, withSender: sender)
        default:
            return false
        }
    }
}
