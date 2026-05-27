//
//  URLBarMetrics.swift
//  WKDemo
//
//  Created by nakata on 2026/05/27.
//
import UIKit

struct URLBarMetrics {
    let widthRatio: CGFloat
    let height: CGFloat
    let buttonWidth: CGFloat
    let horizontalInset: CGFloat
    let verticalInset: CGFloat
    let barCornerRadius: CGFloat
    let contentCornerRadius: CGFloat
    let buttonAlpha: CGFloat
    let transform: CGAffineTransform
    let leftViewMode: UITextField.ViewMode

    static let regular = URLBarMetrics(
        widthRatio: 0.5,
        height: 48,
        buttonWidth: 36,
        horizontalInset: 10,
        verticalInset: 8,
        barCornerRadius: 18,
        contentCornerRadius: 12,
        buttonAlpha: 1,
        transform: .identity,
        leftViewMode: .always
    )

    static let compact = URLBarMetrics(
        widthRatio: 0.15,
        height: 24,
        buttonWidth: 0,
        horizontalInset: 6,
        verticalInset: 4,
        barCornerRadius: 8,
        contentCornerRadius: 6,
        buttonAlpha: 0,
        transform: CGAffineTransform(translationX: 0, y: 4),
        leftViewMode: .never
    )
}
