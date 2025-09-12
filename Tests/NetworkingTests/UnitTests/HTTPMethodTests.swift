//
// HTTPMethodTests.swift
// UtilTests
//
// Created by Dong on 9/12/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation
import Testing

@testable import Networking

@Suite("Model tests")
struct ModelTests {

    /// Test if HTTPMethod raw values are correct
    ///
    /// **Acceptance Criteria:** \
    /// Given HTTPMethod enum cases \
    /// When accessing their raw values \
    /// Then the correct string values should be returned
    @Test("HTTPMethod raw values should be correct")
    func httpMethodRawValues() {
        #expect(HTTPMethod.GET.rawValue == "GET")
        #expect(HTTPMethod.POST.rawValue == "POST")
        #expect(HTTPMethod.PUT.rawValue == "PUT")
        #expect(HTTPMethod.DELETE.rawValue == "DELETE")
        #expect(HTTPMethod.PATCH.rawValue == "PATCH")
    }
}
