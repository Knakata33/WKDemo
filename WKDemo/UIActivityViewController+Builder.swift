//
//  UIActivityViewController+Builder.swift
//  WKDemo
//
//  Created by nakata on 2020/12/08.
//

import UIKit

extension UIActivityViewController {
    class Builder: NSObject {
        private let file: FileProtocol
        
        private var printOnly: Bool = false
        @discardableResult
        func setPrintOnly(_ printOnly: Bool) -> Builder {
            self.printOnly = printOnly
            return self
        }
        
        enum SourceItem {
            case view(UIView)
            case rect(CGRect, UIView)
            case barButtonItem(UIBarButtonItem)
        }
        private var sourceItem: SourceItem? = nil
        @discardableResult
        func setSourceView(_ view: UIView) -> Builder {
            self.sourceItem = .view(view)
            return self
        }
        @discardableResult
        func setSourceRect(_ rect: CGRect, in view: UIView) -> Builder {
            self.sourceItem = .rect(rect, view)
            return self
        }
        @discardableResult
        func setBarButtonItem(_ barButtonItem: UIBarButtonItem) -> Builder {
            self.sourceItem = .barButtonItem(barButtonItem)
            return self
        }
        
        private var permittedArrowDirections: UIPopoverArrowDirection = .any
        @discardableResult
        func setPermittedArrowDirections(_ permittedArrowDirections: UIPopoverArrowDirection) -> Builder {
            self.permittedArrowDirections = permittedArrowDirections
            return self
        }
        
        var completionHandler: ((UIActivity.ActivityType.CompletionMessage) -> Void)? = nil
        @discardableResult
        func setCompletionHandler(_ handler: @escaping (UIActivity.ActivityType.CompletionMessage) -> Void) -> Builder {
            self.completionHandler = handler
            return self
        }
        @discardableResult
        func _setCompletionHandler(_ handler: @escaping (String?) -> Void) -> Builder {
            self.completionHandler = { (completionMessage) in
                switch completionMessage {
                case .present(let title):
                    handler(title)
                case .none:
                    handler(nil)
                }
            }
            return self
        }
        
        var errorHandler: ((Error) -> Void)? = nil
        @discardableResult
        func setErrorHandler(_ handler: @escaping (Error) -> Void) -> Builder {
            self.errorHandler = handler
            return self
        }
        
        init(file: FileProtocol) {
            self.file = file
        }
        
        func build() -> UIActivityViewController {
            let file = self.file
            
            let vc = UIActivityViewController(activityItems: [file.url as Any], applicationActivities: nil)
            
            if printOnly {
                var excludingTypes = Builder.allActivityTypes
                excludingTypes.remove(.print)
                vc.excludedActivityTypes = excludingTypes
            }
            
            if UIDevice.current.userInterfaceIdiom == .pad, let sourceItem = self.sourceItem {
                vc.modalPresentationStyle = .popover
                switch sourceItem {
                case .view(let view):
                    vc.popoverPresentationController?.attachSourceView(view)
                case .rect(let rect, let view):
                    vc.popoverPresentationController?.sourceView = view
                    vc.popoverPresentationController?.sourceRect = rect
                case .barButtonItem(let barButtonItem):
                    vc.popoverPresentationController?.barButtonItem = barButtonItem
                }
                vc.popoverPresentationController?.permittedArrowDirections = self.permittedArrowDirections
            }
            
            let completionHandler = self.completionHandler
            let errorHandler = self.errorHandler
            
            vc.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
                // fileの実態が一時ファイルでもファイルが消えないように強参照をここで保持しておく
                let _ = file
                
                if completed {
                    let completionMessage = activityType?.completionMessage ?? .none
                    completionHandler?(completionMessage)
                } else if let error = activityError {
                    errorHandler?(error)
                }
            }
            return vc
        }
        
        #if swift(>=5.3.2)
        #warning("UIActivityTypeがSDKのバージョンによって増減する可能性があるので、xcodeのバージョンを上げたら再確認してください")
        #endif
        private static let allActivityTypes: [UIActivity.ActivityType] = [
            .postToFacebook,
            .postToTwitter,
            .postToWeibo,
            .message,
            .mail,
            .print,
            .copyToPasteboard,
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .airDrop,
            .openInIBooks,
            .markupAsPDF
        ]
    }
}
