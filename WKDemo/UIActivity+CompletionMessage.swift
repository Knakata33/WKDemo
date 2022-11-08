//
//  UIActivity+CompletionMessage.swift
//  WKDemo
//
//  Created by nakata on 2020/12/08.
//

import UIKit

extension UIActivity.ActivityType {
    enum CompletionMessage {
        case present(String)
        case none
    }
    
    var completionMessage: CompletionMessage {
        switch self {
        case .copyToPasteboard: // コピー
            return .present(NSLocalizedString("908", comment: "コピーしました"))
        case .saveToCameraRoll: // ビデオを保存
            return .present(NSLocalizedString("909", comment: "\"写真\"に保存しました"))
        case .init(rawValue: "com.apple.mobileslideshow.StreamShareService"): // 共有アルバムに追加
            return .present(NSLocalizedString("910", comment: "\"写真\"の共有アルバムに\n追加しました"))
        case .init(rawValue: "com.apple.CloudDocsUI.AddToiCloudDrive"): // "ファイル"に保存
            return .present(NSLocalizedString("911", comment: "\"ファイル\"に保存しました"))
        default:
            return .none
        }
    }
}
