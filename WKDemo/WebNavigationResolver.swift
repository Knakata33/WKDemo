//
//  WebNavigationResolver.swift
//  WKDemo
//
//  Created by nakata
//

import Foundation

enum WebNavigationResolver {
    static func resolve(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = makeBrowsableURL(from: trimmed) {
            return url
        } else {
            return makeGoogleSearchURL(query: trimmed)
        }
    }

    static func makeBrowsableURL(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            guard let url = URL(string: trimmed),
                  let scheme = url.scheme?.lowercased(),
                  let host = url.host,
                  (scheme == "http" || scheme == "https"),
                  !host.isEmpty else {
                return nil
            }
            return url
        }

        if looksLikeHost(trimmed),
           let url = URL(string: "https://\(trimmed)") {
            return url
        }

        return nil
    }

    static func makeGoogleSearchURL(query: String) -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: trimmed)
        ]
        return components?.url
    }

    static func looksLikeHost(_ text: String) -> Bool {
        if text.contains(" ") {
            return false
        }

        if text == "localhost" || text.hasPrefix("localhost:") {
            return true
        }

        if !text.contains(".") {
            return false
        }

        return URLComponents(string: "https://\(text)")?.host != nil
    }
}
