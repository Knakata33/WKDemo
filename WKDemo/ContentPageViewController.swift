//
//  ContentPageViewController.swift
//  WKDemo
//
//  Created by nakata on 2020/12/07.
//

import UIKit
@preconcurrency import WebKit

class ContentPageViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bottomBarView: UIVisualEffectView!
    @IBOutlet weak var bottomBarViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var reloadButtonWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var closeButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewBottomConstraint: NSLayoutConstraint!
    
    private var webView: WKWebView!
    private var touchLocation: CGPoint = .zero
    private let url: URL
    private var isURLBarCompact = false
    private var lastContentOffsetY: CGFloat = 0
    private var isLoadingObservation: NSKeyValueObservation?
    private let websiteDataStore: any AppWebsiteDataStoreProtocol
    private var isCleaningUpWebsiteData = false
    
    init(url: URL, websiteDataStore: any AppWebsiteDataStoreProtocol = AppWebsiteDataStore()) {
        self.url = url
        self.websiteDataStore = websiteDataStore
        super.init(nibName: "ContentPageViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapAction(_ sender: UITapGestureRecognizer) {
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isURLBarCompact {
            bottomBarViewWidthConstraint.constant = view.bounds.width * 0.3
        }
    }
    
    private func makeWebViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        if #available(iOS 18.0, *) {
            configuration.writingToolsBehavior = .none
        }
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        return configuration
    }
    
    private func configureWebView(_ webView: WKWebView) {
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self
        webView.scrollView.alwaysBounceVertical = false
        webView.allowsBackForwardNavigationGestures = true
    }
    
    private func addTouchLocationRecognizer(to webView: WKWebView) {
        let recognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(tapAction(_:))
        )
        recognizer.delegate = self
        recognizer.numberOfTapsRequired = 1
        webView.addGestureRecognizer(recognizer)
    }
    
    private func setupWebView() {
        let webView = WKWebView(frame: self.containerView.bounds, configuration: makeWebViewConfiguration())
        configureWebView(webView)
        addTouchLocationRecognizer(to: webView)
        
        containerView.addSubview(webView)
        self.webView = webView
    }
    
    private func loadInitialURL() {
        webView.load(URLRequest(url: url))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        
        setupWebView()
        setupBottomBar()
        setupURLTextField()
        setupButtons()
        observeWebViewLoadingState()
        loadInitialURL()
    }
    
    private func setupButtonHighlightEffect(_ button: UIButton) {
        button.configurationUpdateHandler = { btn in
            var config = btn.configuration
            if btn.isHighlighted {
                config?.baseForegroundColor = .systemGray3
                config?.background.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.3)
            } else {
                config?.baseForegroundColor = .label
                config?.background.backgroundColor = .clear
            }
            btn.configuration = config
            UIView.animate(withDuration: 0.12) {
                btn.transform = btn.isHighlighted
                ? CGAffineTransform(scaleX: 0.92, y: 0.92)
                : .identity
            }
        }
    }
    
    private func setupBottomBar() {
        bottomBarView.clipsToBounds = true
        contentView.clipsToBounds = true
    }
    
    private func setupButtons() {
        let symbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 14,
            weight: .medium
        )
        
        reloadButton.setPreferredSymbolConfiguration(
            symbolConfiguration,
            forImageIn: .normal
        )
        closeButton.setImage(
            UIImage(systemName: "xmark", withConfiguration: symbolConfiguration),
            for: .normal
        )
        
        setupButtonHighlightEffect(reloadButton)
        setupButtonHighlightEffect(closeButton)
    }
    
    private func makeSearchIconView() -> UIView {
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.tintColor = .systemGray2
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 8, y: 0, width: 18, height: 18)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 18))
        view.addSubview(imageView)
        return view
    }
    
    private func setupURLTextField() {
        urlTextField.delegate = self
        urlTextField.clipsToBounds = true
        urlTextField.leftView = makeSearchIconView()
        urlTextField.leftViewMode = .always
        let interaction = UIContextMenuInteraction(delegate: self)
        urlTextField.addInteraction(interaction)
    }
    
    private func setURLBarCompact(_ isCompact: Bool) {
        guard isURLBarCompact != isCompact else { return }
        isURLBarCompact = isCompact
        let metrics: URLBarMetrics = isCompact ? .compact : .regular
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.applyURLBarMetrics(metrics)
            self.view.layoutIfNeeded()
        }
    }
    
    private func applyURLBarMetrics(_ metrics: URLBarMetrics) {
        bottomBarViewWidthConstraint.constant = view.bounds.width * metrics.widthRatio
        bottomBarHeightConstraint.constant = metrics.height
        reloadButtonWidthConstraint.constant = metrics.buttonWidth
        closeButtonWidthConstraint.constant = metrics.buttonWidth
        contentViewLeadingConstraint.constant = metrics.horizontalInset
        contentViewTrailingConstraint.constant = metrics.horizontalInset
        contentViewTopConstraint.constant = metrics.verticalInset
        contentViewBottomConstraint.constant = metrics.verticalInset
        bottomBarView.layer.cornerRadius = metrics.barCornerRadius
        contentView.layer.cornerRadius = metrics.contentCornerRadius
        reloadButton.alpha = metrics.buttonAlpha
        closeButton.alpha = metrics.buttonAlpha
        bottomBarView.transform = metrics.transform
        urlTextField.leftViewMode = metrics.leftViewMode
    }
    
    private func updateURLTextFieldDisplay() {
        guard !urlTextField.isEditing else { return }
        urlTextField.text = webView.url?.displayText
    }
    
    private func updateReloadButton(isLoading: Bool) {
        let imageName = isLoading ? "xmark" : "arrow.clockwise"
        reloadButton.setImage(
            UIImage(systemName: imageName),
            for: .normal
        )
        reloadButton.accessibilityLabel = isLoading ? "読み込み停止" : "再読み込み"
    }
    
    private func observeWebViewLoadingState() {
        isLoadingObservation = webView.observe(
            \.isLoading,
            options: [.initial, .new]
        ) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.updateReloadButton(isLoading: webView.isLoading)
            }
        }
    }
    
    @MainActor
    private func cleanUpWebsiteDataIfNeeded() async {
        guard !isCleaningUpWebsiteData else { return }
        
        isCleaningUpWebsiteData = true
        defer {
            isCleaningUpWebsiteData = false
        }
        
        webView?.stopLoading()
        await websiteDataStore.cleanUp()
    }
    
    @IBAction func urlTextFieldDidEndOnExit(_ sender: UITextField) {
        sender.resignFirstResponder()
        
        guard let input = sender.text,
              let url = WebNavigationResolver.resolve(from: input) else {
            return
        }
        
        webView.load(URLRequest(url: url))
    }
    
    @IBAction func reloadButtonTouchUpInside(_ sender: Any) {
        guard isViewLoaded else {
            return
        }
        if webView.isLoading {
            webView.stopLoading()
        } else {
            webView.reload()
        }
    }
    
    @IBAction func bottomBarCloseButtonTouchUpInside(_ sender: Any) {
        guard !isCleaningUpWebsiteData else { return }
        
        isCleaningUpWebsiteData = true
        closeButton.isEnabled = false
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            self.webView.stopLoading()
            await self.websiteDataStore.cleanUp()
            self.dismiss(animated: true)
        }
    }
}

extension ContentPageViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let contentWidth = webView.scrollView.contentSize.width
        guard contentWidth > 0 else { return }
        webView.pageZoom = webView.bounds.width / contentWidth
        
        updateURLTextFieldDisplay()
    }
    
    private func shouldIgnoreNavigationError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else {
            return false
        }
        return urlError.code == .cancelled
    }
    
    private func handleNavigationError(_ error: Error) {
        if shouldIgnoreNavigationError(error) {
            return
        }
        print(error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }
    
    private func allowHTTPNavigationIfNeeded(
        _ url: URL,
        decisionHandler: (WKNavigationActionPolicy) -> Void
    ) -> Bool {
        guard url.isHTTPOrHTTPS else {
            return false
        }
        decisionHandler(.allowWithoutTryingAppLink)
        return true
    }
    
    private func allowWebViewHandledSchemeIfNeeded(
        _ url: URL,
        decisionHandler: (WKNavigationActionPolicy) -> Void
    ) -> Bool {
        guard
            let scheme = url.scheme?.lowercased(),
            WKWebView.handlesURLScheme(scheme)
        else {
            return false
        }

        decisionHandler(.allow)
        return true
    }
    
    private func openExternalURL(
        _ url: URL,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        UIApplication.shared.open(url) { success in
            if !success {
                debugPrint("WKDemo openURL failed url: \(url)")
            }

            decisionHandler(.cancel)
        }
    }
    
    private func presentActivityMessage(title: String) {
        let dialog = UIAlertController(
            title: title,
            message: nil,
            preferredStyle: .alert
        )

        dialog.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )

        dialog.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel
            )
        )

        present(dialog, animated: true)
    }
    
    private func handleDataURLIfNeeded(
        _ url: URL,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) -> Bool {
        guard
            let mimeType = DataURLSupport.mimeType(of: url),
            let pathExtension = MIMETypeSupport.preferredPathExtension(mimeType: mimeType),
            let data = try? Data(contentsOf: url)
        else {
            return false
        }

        let tempFile = TemporaryFile(pathExtension: pathExtension as String)

        do {
            try data.write(to: tempFile.url, options: .atomic)
        } catch {
            print(error)
            decisionHandler(.cancel)
            return true
        }

        let activityViewController = UIActivityViewController.Builder(file: tempFile)
            .setSourceRect(
                CGRect(origin: touchLocation, size: .zero),
                in: containerView
            )
            .setCompletionHandler { [weak self] message in
                switch message {
                case .present(let title):
                    self?.presentActivityMessage(title: title)

                case .none:
                    break
                }
            }
            .setErrorHandler { error in
                print(error)
            }
            .build()

        present(activityViewController, animated: true)
        decisionHandler(.cancel)
        return true
    }
    
    private func decidePolicy(
        for navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            assertionFailure("navigationAction.request.url is nil")
            decisionHandler(.cancel)
            return
        }

        if allowHTTPNavigationIfNeeded(url, decisionHandler: decisionHandler) {
            return
        }

        if handleDataURLIfNeeded(url, decisionHandler: decisionHandler) {
            return
        }

        if allowWebViewHandledSchemeIfNeeded(url, decisionHandler: decisionHandler) {
            return
        }

        openExternalURL(url, decisionHandler: decisionHandler)
    }
    private func presentShareSheet(_ url: URL) {
        let vc = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        present(vc, animated: true)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        debugPrint("ViewController decidePolicy url: \(String(describing: navigationAction.request.url)), preferredContentMode: \(preferences.preferredContentMode.rawValue)")        
        decidePolicy(for: navigationAction) { (policy) in
            decisionHandler(policy, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateURLTextFieldDisplay()
    }
}

extension ContentPageViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http"
        else {
            return nil
        }
        UIApplication.shared.open(url) { success in
            if !success {
                print("[ContentPageViewController] openURL failed url: \(url)")
            }
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

extension ContentPageViewController {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField === urlTextField else { return }
        
        textField.text = webView.url?.absoluteString
        
        DispatchQueue.main.async {
            textField.selectedTextRange = textField.textRange(
                from: textField.beginningOfDocument,
                to: textField.endOfDocument
            )
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField === urlTextField else { return }
        
        updateURLTextFieldDisplay()
    }
}

extension ContentPageViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffsetY = scrollView.contentOffset.y
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !urlTextField.isEditing else { return }
        
        let currentY = scrollView.contentOffset.y
        let diff = currentY - lastContentOffsetY
        
        // 下にスクロール開始したらコンパクト
        if diff > 6 {
            setURLBarCompact(true)
        }
        
        // 上に戻したら展開
        if diff < -6 || currentY <= 0 {
            setURLBarCompact(false)
        }
        
        lastContentOffsetY = currentY
    }
}

extension ContentPageViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard !urlTextField.isEditing else {
            return nil
        }
        guard let url = webView.url else {
            return nil
        }
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil
        ) { _ in
            let copyAction = UIAction(
                title: "URLをコピー",
                image: UIImage(systemName: "doc.on.doc")
            ) { _ in
                UIPasteboard.general.string = url.absoluteString
            }
            let shareAction = UIAction(
                title: "共有",
                image: UIImage(systemName: "square.and.arrow.up")
            ) { [weak self] _ in
                self?.presentShareSheet(url)
            }
            let safariAction = UIAction(
                title: "Safariで開く",
                image: UIImage(systemName: "safari")
            ) { _ in
                UIApplication.shared.open(url)
            }
            return UIMenu(children: [
                copyAction,
                shareAction,
                safariAction
            ])
        }
    }
}

private extension WKNavigationActionPolicy {
    static var allowWithoutTryingAppLink: WKNavigationActionPolicy {
        let policy = WKNavigationActionPolicy(
            rawValue: WKNavigationActionPolicy.allow.rawValue + 2
        )

        assert(policy != nil)
        return policy ?? .allow
    }
}
