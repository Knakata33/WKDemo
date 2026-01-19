//
//  StarPageView.swift
//  WKDemo
//
//  Created by nakata
//

import SwiftUI
import UIKit

// MARK: - StartPageView (SwiftUI)

struct StartPageView: View {
    @State private var urlText: String = ""
    @State private var presentingURL: URL?

    @State private var showInvalidURLAlert = false
    @State private var invalidURLMessage = "URLが不正です。"
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var maxWidth: CGFloat {
        (hSizeClass == .regular) ? 800 : .infinity
    }
    private var horizontalMargin: CGFloat {
        (hSizeClass == .regular) ? 64 : 32
    }

    var body: some View {
        ZStack {
            // 背景色
            Color(
                red: 18.0 / 255.0,
                green: 38.0 / 255.0,
                blue: 79.0 / 255.0
            ).ignoresSafeArea()
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // URLバー（虫眼鏡付き）
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("", text: $urlText)
                            .foregroundColor(.black)
                            .tint(.black)
                            .font(.system(size: 18))
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .submitLabel(.go)
                            .onSubmit {
                                openFromText()
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(minHeight: 52)
                    .frame(maxWidth: maxWidth)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)   // ← 白背景
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.4))
                    )
                }
                .padding(.horizontal, horizontalMargin)
                
                Spacer()
            }
        }
        .fullScreenCover(item: $presentingURL) { url in
            ZStack {
                Color(red: 18.0 / 255.0,
                      green: 38.0 / 255.0,
                      blue: 79.0 / 255.0
                ).ignoresSafeArea()
                ContentPageVCWrapper(url: url).ignoresSafeArea()
            }
        }
        // URL不正アラート
        .alert("開けませんでした", isPresented: $showInvalidURLAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(invalidURLMessage)
        }
    }

    private func openFromText() {
        let raw = urlText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = normalizeAndValidateURL(raw) else {
            invalidURLMessage = "入力された文字列から正しいURLを作れませんでした。\n例: https://example.com"
            showInvalidURLAlert = true
            return
        }

        presentingURL = url
    }

    /// スキーム補完 + 最低限の妥当性チェック
    private func normalizeAndValidateURL(_ text: String) -> URL? {
        guard !text.isEmpty else { return nil }

        var s = text
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") {
            s = "https://" + s
        }

        guard let url = URL(string: s) else { return nil }
        guard let scheme = url.scheme, (scheme == "http" || scheme == "https") else { return nil }
        guard url.host != nil else { return nil }

        return url
    }
}

// fullScreenCover(item:) 用
extension URL: Identifiable {
    public var id: String { absoluteString }
}

// MARK: - UIKit VC Wrapper (SwiftUI ↔ UIKit Bridge)

struct ContentPageVCWrapper: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> ContentPageViewController {
        ContentPageViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: ContentPageViewController, context: Context) {
        // URLを途中で変えて再ロードする運用がないので空のままにしています
    }
}


// ↓debug用。見た目確認したい時にコメント外す
//#Preview {
//    StartPageView()
//}
