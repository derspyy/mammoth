//
//  Results.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/19/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Results: Codable {
    /// An array of matched accounts.
    public let accounts: [Account]
    /// An array of matched statuses.
    public let statuses: [Status]
    /// An array of matched hashtags, as Tag.
    public let hashtags: [Tag]
}
