//
//  Search.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public struct Search {
    /// Searches for content.
    ///
    /// - Parameters:
    ///   - query: The search query.
    ///   - resolve: Whether to resolve non-local accounts.
    /// - Returns: Request for `Results`.
    public static func search(query: String, resolve: Bool? = nil) -> Request<Results> {
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "limit", value: "10"),
            Parameter(name: "resolve", value: resolve.flatMap(trueOrNil))
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }

    // Use Accounts.search instead
//    public static func searchAccounts(query: String) -> Request<Results> {
//        let parameters = [
//            Parameter(name: "q", value: query),
//            Parameter(name: "limit", value: "50"),
//        ]
//        let method = HTTPMethod.get(.parameters(parameters))
//        return Request<Results>(path: "/api/v1/accounts/search", method: method)
//    }
    
    public static func searchAccount(query: String) -> Request<Results> {
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "type", value: "accounts"),
            Parameter(name: "limit", value: "1"),
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }

    public static func searchPosts(query: String) -> Request<Results> {
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "type", value: "statuses"),
            Parameter(name: "limit", value: "50"),
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }

    public static func searchTags(query: String) -> Request<Results> {
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "type", value: "hashtags"),
            Parameter(name: "limit", value: "50"),
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }
    
}
