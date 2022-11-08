//
//  AtomicBool.swift
//  WKDemo
//
//  Created by nakata on 2020/12/08.
//

import Foundation

public class OSUnfairLock {
    private let obj: os_unfair_lock_t
    
    public init() {
        obj = .allocate(capacity: 1)
        obj.initialize(to: os_unfair_lock())
    }
    
    deinit {
        obj.deinitialize(count: 1)
        obj.deallocate()
    }
    
    public func lock() {
        os_unfair_lock_lock(obj)
    }
    
    public func unlock() {
        os_unfair_lock_unlock(obj)
    }
}

public extension OSUnfairLock {
    
    func withLock<T>(_ closure: () -> T) -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return closure()
    }
    
    func withLock(_ closure: () -> Void) {
        self.lock()
        defer {
            self.unlock()
        }
        closure()
    }
}

public class AtomicBool {
    private let lock = OSUnfairLock()
    private var flag : Bool = false
    
    public init(initial : Bool = false) {
        flag = initial
    }
    
    public var value: Bool {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return flag
        }
        set(newValue) {
            lock.lock()
            defer {
                lock.unlock()
            }
            flag = newValue
        }
    }
    
    public func getAndSet(value: Bool) -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        let prev = flag
        flag = value
        return prev
    }
}
