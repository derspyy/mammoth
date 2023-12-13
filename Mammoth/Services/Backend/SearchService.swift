//
//  SearchService.swift
//  Mammoth
//
//  Created by Benoit Nolens on 15/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct SearchService {
    
    static func search(query: String) async throws -> Results {
        let request = Search.search(query: query, resolve: true)
        let result = try await ClientService.runRequest(request: request)
        return result
    }

    static func searchAccounts(query: String) async throws -> [Account] {
        let request = Accounts.search(query: query)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    static func searchAccount(query: String) async throws -> Account? {
        let request = Accounts.lookup(acct: query) 
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    static func searchPosts(query: String) async throws -> [Status] {
        let request = Search.searchPosts(query: query)
        let result = try await ClientService.runRequest(request: request)
        return result.statuses
    }
    
    static func searchTags(query: String) async throws -> [Tag] {
        let request = Search.searchTags(query: query)
        let result = try await ClientService.runRequest(request: request)
        return result.hashtags
    }

}
