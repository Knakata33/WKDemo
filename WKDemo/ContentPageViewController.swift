//
//  ContentPageViewController.swift
//  WKDemo
//
//  Created by nakata on 2020/12/07.
//

import UIKit
@preconcurrency import WebKit

class ContentPageViewController: UIViewController {
    @IBOutlet weak var containerView: WKWebView!
    private weak var webView: WKWebView!
    private var touchLocation: CGPoint = .zero
    private let url: URL
    
    init(url: URL) {
        self.url = url
        super.init(nibName: "ContentPageViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapAction(_ sender: UITapGestureRecognizer) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        
        let configuration = WKWebViewConfiguration()
        if #available(iOS 18.0, *) {
            configuration.writingToolsBehavior = .none
        }
        configuration.websiteDataStore = .nonPersistent()
        configuration.applicationNameForUserAgent = "Version/13.0 Safari/605.1.15"
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: self.containerView.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.scrollView.alwaysBounceVertical = false
        
        // tapRecognizerは、webView上のタッチ位置を取得するためだけに使用しています
        // そのためtapAction自体も呼ばれないよう、gestureRecognizer(_:shouldReceive)にて制御しています
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapRecognizer.delegate = self
        tapRecognizer.numberOfTapsRequired = 1
        webView.addGestureRecognizer(tapRecognizer)
        
        self.webView = webView
        self.containerView.addSubview(webView)
        self.webView.load(URLRequest(url: self.url))
    }
}

extension ContentPageViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let pageZoom = webView.bounds.size.width / webView.scrollView.contentSize.width
        webView.pageZoom = pageZoom
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // 遷移操作の繰り返しによるリクエストキャンセルエラーのみ無視する
        if let urlError = error as? URLError {
            if .cancelled == urlError.code {
                return
            }
        }
        // TODO: 現行の完了ボタン→再度カードを開く、による再接続処理をやめて、LoadErrorView表示＆リロードボタンによるリクエスト再生成にする
        print(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // 遷移操作の繰り返しによるリクエストキャンセルエラーのみ無視する
        if let urlError = error as? URLError {
            if .cancelled == urlError.code {
                return
            }
        }
        // TODO: 現行の完了ボタン→再度カードを開く、による再接続処理をやめて、LoadErrorView表示＆リロードボタンによるリクエスト再生成にする
        print(error)
    }
    
    private func decidePolicy(for navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            assert(false)
            decisionHandler(.cancel)
            return
        }
        if let scheme = url.scheme?.lowercased() {
            if scheme == "https" || scheme == "http" {
                // iosのUniversal Linksの機能で、webページのアドレスでアプリを起動する機能があるが、YouTube等がアプリ内ブラウザで開けるように強制しています
                // 副作用として、YouTubeのページ内にある「アプリで開く」ボタンを押しても、
                // YouTubeアプリが起動せずに後述のopenURLからAppStoreのYouTubeページが開くようになりますが、許容しています
                // https://stackoverflow.com/questions/38450586/prevent-universal-links-from-opening-in-wkwebview-uiwebview
                // static WKNavigationActionPolicy const LLWKNavigationActionPolicyAllowWithoutTryingAppLink = WKNavigationActionPolicyAllow + 2;
                let allowWithoutTryingAppLink = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2)
                assert(allowWithoutTryingAppLink != nil)
                decisionHandler(allowWithoutTryingAppLink ?? .allow)
                return
            }
            
            if let mimeType = DataURLSupport.mimeType(of: url), let pathExtension = MIMETypeSupport.preferredPathExtension(mimeType: mimeType), let data = try? Data(contentsOf: url) {
                let tempFile = TemporaryFile(pathExtension: pathExtension as String)
                do {
                    try data.write(to: tempFile.url, options: .atomic)
                } catch {
                    print(error)
                    decisionHandler(.cancel)
                    return
                }
                
                let vc = UIActivityViewController.Builder(file: tempFile)
                    .setSourceRect(CGRect(origin: self.touchLocation, size: .zero), in: self.containerView)
                    .setCompletionHandler({ [weak self] (message) in
                        switch message {
                        case .present(let title):
                            let dialog = UIAlertController(title: title, message: nil, preferredStyle: .alert)
                            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                            guard let myself = self else {
                                return
                            }
                            myself.present(dialog, animated: true, completion: nil)
                        case .none:
                            break
                        }
                    })
                    .setErrorHandler({ (error) in
                        print(error)
                    })
                    .build()
                present(vc, animated: true, completion: nil)
                
                decisionHandler(.cancel)
                return
            }
            
            if WKWebView.handlesURLScheme(scheme) {
                decisionHandler(.allow)
                return
            }
        }
        
        UIApplication.shared.open(url) { (success) in
            if !success {
                debugPrint("WKDemo openURL failed url: \(url)")
            }
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        debugPrint("ViewController decidePolicy url: \(String(describing: navigationAction.request.url)), preferredContentMode: \(preferences.preferredContentMode.rawValue)")        
        decidePolicy(for: navigationAction) { (policy) in
            decisionHandler(policy, preferences)
        }
    }
}

extension ContentPageViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // target="_blank"を同じWKWebViewで開く場合に必要な対応
        if navigationAction.targetFrame?.isMainFrame != true {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationFor elementInfo: WKContextMenuElementInfo
    ) async -> UIContextMenuConfiguration? {
        // リンクでコンテキストメニューを表示しないために空のUIContextMenuConfigurationを渡しています
        return UIContextMenuConfiguration()
    }
}

extension ContentPageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        self.touchLocation = touch.location(in: self.containerView)
        return false
    }
}
