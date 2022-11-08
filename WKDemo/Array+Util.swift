//
//  Array+Util.swift
//  WKDemo
//
//  Created by nakata on 2020/12/08.
//

import Foundation

extension Array {
    @discardableResult
    mutating func removeIf(_ filter: (_ element: Element) -> Bool) -> Array {
        var removed = self.filter { (element) -> Bool in
            return !filter(element)
        }
        swap(&self, &removed)
        return self
    }
    
    func toJsonString() -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: self) {
            let str = String(data: data, encoding: .utf8)
            return str
        }
        return nil
    }
    
    func indexOfNearest<R: SignedNumeric & Comparable & Strideable>(distance: (Element) -> R) -> Int? {
        if isEmpty {
            return nil
        }
        
        var minIndex = 0
        var minValue = abs(distance(self[0]))
        for i in 1..<self.count {
            let value = abs(distance(self[i]))
            if minValue > value {
                minIndex = i
                minValue = value
            }
        }
        return minIndex
    }
}

extension Array where Element: Equatable {
    @discardableResult
    mutating func remove(_ element: Element) -> Array {
        self.removeIf { (el) -> Bool in
            return el == element
        }
        return self
    }
}

extension Array where Element: SignedNumeric & Comparable & Strideable {
    func indexOfNearest(element: Element) -> Int? {
        if isEmpty {
            return nil
        }
        var minIndex = 0
        var minValue = abs(element.distance(to: self[0]))
        for i in 1..<self.count {
            let value = abs(element.distance(to: self[i]))
            if minValue > value {
                minIndex = i
                minValue = value
            }
        }
        return minIndex
    }
}

