//
//  AppWebsiteDataStore.swift
//  WKDemo
//
//  Created by 仲田健太郎 on 2026/07/24.
//
import WebKit

protocol AppWebsiteDataStoreProtocol: Sendable {
    @MainActor
    func cleanUp() async
}

struct AppWebsiteDataStore: AppWebsiteDataStoreProtocol {
    @MainActor
    func cleanUp() async {
        await WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0)
        )
    }
}
