//
// Counter.swift
// NetworkingTests
//
// Created by Dong on 09/15/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0
    var value: Int { lock.withLock { _value } }

    func increment() { lock.withLock { _value += 1 } }
}
