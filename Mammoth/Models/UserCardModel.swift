//
//  UserCardModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SDWebImage

class UserCardModel {
    let id: String
    let uniqueId: String
    let name: String
    let userTag: String
    let username: String
    let imageURL: String?
    let description: String?
    let isFollowing: Bool
    let emojis: [Emoji]?
    let account: Account?
    
    var instanceName: String?
    
    let isLocked: Bool
    let isBot: Bool
    
    var richName: NSAttributedString?
    var richDescription: NSAttributedString?
    let richPreviewDescription: NSAttributedString?
    var followStatus: FollowManager.FollowStatus?
    let followingCount: String
    let followersCount: String
    let fields: [HashType]?
    var relationship: Relationship?
    
    // when a user has been followed we keep the unfollow button
    // until a hard refresh happens
    var forceFollowButtonDisplay: Bool = false
    
    let joinedOn: Date?
    
    var isSelf: Bool {
        return self.account?.fullAcct != nil && AccountsManager.shared.currentUser()?.fullAcct != nil && AccountsManager.shared.currentUser()?.fullAcct == self.account?.fullAcct
    }
    
    var isMuted: Bool {
        return ModerationManager.shared.mutedUsers.first(where: {$0.remoteFullOriginalAcct == self.uniqueId}) != nil
    }
    
    var isBlocked: Bool {
        return ModerationManager.shared.blockedUsers.first(where: {$0.remoteFullOriginalAcct == self.uniqueId}) != nil
    }
    
    // deprecated initializer
    init(name: String, userTag: String, imageURL: String?, description: String?, isFollowing: Bool, emojis: [Emoji]?, account: Account?) {
        self.id = account?.id ?? ""
        self.uniqueId = account?.remoteFullOriginalAcct ?? ""
        self.name = name
        self.userTag = userTag
        self.username = account?.username ?? ""
        self.imageURL = imageURL
        self.description = description?.stripHTML()
        self.isFollowing = isFollowing
        self.emojis = emojis
        self.account = account
        
        self.richName = NSAttributedString(string: self.name)
        self.richDescription = NSAttributedString()
        self.richPreviewDescription = self.description != nil ? removeTrailingLinebreaks(string: NSAttributedString(string: self.description!)) : nil
        
        self.instanceName = nil
        
        self.isLocked = account?.locked ?? false
        self.isBot = account?.bot ?? false
        
        if let account = account, !Self.isOwn(account: account) {
            self.followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: .none)
            self.relationship = FollowManager.shared.relationshipForAccount(account, requestUpdate: false)
        }
        
        self.followingCount = max(account?.followingCount ?? 0, 0).formatUsingAbbrevation()
        self.followersCount = max(account?.followersCount ?? 0, 0).formatUsingAbbrevation()
        
        self.fields = account?.fields
        self.joinedOn = account?.createdAt?.toDate()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.richDescription = self.description != nil ? parseRichText(text: description) : nil
        }
    }
    
    init(account: Account, instanceName: String? = nil, requestFollowStatusUpdate: FollowManager.NetworkUpdateType = .none) {
        self.id = account.id
        self.uniqueId = account.remoteFullOriginalAcct
        self.name = !account.displayName.isEmpty ? account.displayName : account.username
        self.userTag = account.fullAcct
        self.username = account.username
        self.imageURL = account.avatar
        self.description = account.note.stripHTML()
        self.isFollowing = false
        self.emojis = account.emojis
        self.account = account
        
        self.richName = NSAttributedString(string: self.name)
        self.richDescription = NSAttributedString()
        self.richPreviewDescription = self.description != nil ? removeTrailingLinebreaks(string: NSAttributedString(string: self.description!)) : nil
        
        self.instanceName = instanceName
        
        self.isLocked = account.locked
        self.isBot = account.bot
        
        if !Self.isOwn(account: account) {
            self.followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: requestFollowStatusUpdate)
            self.relationship = FollowManager.shared.relationshipForAccount(account, requestUpdate: false)
        }
        
        self.followingCount = max(account.followingCount, 0).formatUsingAbbrevation()
        self.followersCount = max(account.followersCount, 0).formatUsingAbbrevation()
        
        self.fields = account.fields
        self.joinedOn = account.createdAt?.toDate()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.richDescription = self.description != nil ? parseRichText(text: account.note) : nil
        }
    }
    
    // Return an instance without description
    func simple() -> UserCardModel {
        return UserCardModel(name: self.name,
                        userTag: self.userTag,
                        imageURL: self.imageURL,
                        description: "",
                        isFollowing: self.isFollowing,
                        emojis: self.emojis,
                        account: self.account)
    }
    
    func syncFollowStatus(_ requestUpdate: FollowManager.NetworkUpdateType = .whenUncertain) {
        if let account = account {
            self.followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: requestUpdate)
        }
    }
    
    func setFollowStatus(_ followStatus: FollowManager.FollowStatus) {
        self.followStatus = followStatus
    }
    
    static func isOwn(account: Account) -> Bool {
        return AccountsManager.shared.currentUser()?.fullAcct != nil && AccountsManager.shared.currentUser()?.fullAcct == account.fullAcct
    }
    
}

extension UserCardModel {
    static func fromAccount(account: Account, instanceName: String? = nil) -> UserCardModel {
        return UserCardModel(account: account, instanceName: instanceName)
    }
}

extension UserCardModel: Equatable {
    static func == (lhs: UserCardModel, rhs: UserCardModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.imageURL == rhs.imageURL &&
        lhs.description == rhs.description &&
        lhs.followingCount == rhs.followingCount &&
        lhs.followersCount == rhs.followersCount &&
        lhs.isFollowing == rhs.isFollowing &&
        lhs.followStatus == rhs.followStatus &&
        lhs.fields == rhs.fields &&
        lhs.isBot == rhs.isBot &&
        lhs.isLocked == rhs.isLocked
    }
}

extension UserCardModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preload
extension UserCardModel {
    func preloadImages() {
        
        let arrayOfURLS = [
            // Prefetch the profile picture
            self.imageURL,
        ]
        .filter({ !SDImageCache.shared.diskImageDataExists(withKey: $0) })
        .compactMap({URL(string: $0 ?? "")})
        
        if !arrayOfURLS.isEmpty {
            DispatchQueue.global(qos: .default).async {
                SDWebImagePrefetcher.shared.prefetchURLs(arrayOfURLS, progress: nil, completed: nil)
            }
        }
    }
}
