//
//  UIPopoverPresentationController+Compat.swift
//  WKDemo
//
//  Created by nakata on 2020/12/08.
//

import UIKit

extension UIPopoverPresentationController {
    @objc func attachSourceView(_ sourceView: UIView) {
        self.sourceView = sourceView
        if #available(iOS 13.2, *) {
            // Starting in iOS 13.2, a value of CGRectNull will cause the popover to point at the current frame of sourceView and automatically update when the size of sourceView changes.
            // The default value in iOS 13.2 is CGRectNull.
        } else {
            self.sourceRect = sourceView.bounds
        }
    }
}
