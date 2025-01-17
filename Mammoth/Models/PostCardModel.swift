//
//  PostCardModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 25/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SDWebImage
import AVFoundation

final class PostCardModel {
    
    enum Data {
       case mastodon(Status)
       case bluesky(BlueskyPostViewModel)
    }
    
    var data: Data
    var preSyncData: Data?
    
    /// staticMetrics should be true when posts are coming from a pre-defined
    /// server, e.g. the For You feed. For these posts metrics will not update
    /// when the user likes, reblogs or bookmarks. We keep a local tally in those cases.
    let staticMetrics: Bool
    
    /// if the post is coming from another instance as the current
    /// user's instance, an instanceName is set
    var instanceName: String?
    
    let id: String?
    let cursorId: String?
    let uniqueId: String?
    
    let originalId: String?
    let originalInstanceName: String?
    
    let url: String?
    let uri: String?
    let createdAt: Date
    let emojis: [Emoji]?
    
    var isSyncedWithOriginal: Bool = false
    
    // Debug properties
    var batchId: String?
    var batchItemIndex: Int?
    
    // When a post card has been deleted by the server
    var isDeleted: Bool = false
    
    // Formatted properties
    
    let username: String
    var richUsername: NSAttributedString?
    
    let rebloggerUsername: String
    var richRebloggerUsername: NSAttributedString?
    
    var applicationName: String?
    let visibility: String?
    
    var account: Account?
    var user: UserCardModel?
    
    let userTag: String
    let fullUserTag: String
    let contentWarning: String
    let isSensitive: Bool
    var postText: String
    var richPostText: NSAttributedString?
    
    var profileURL: URL?
    let isLockedAccount: Bool
    let containsPoll: Bool
    var poll: Poll?
    let isAReply: Bool
    let isReblogged: Bool
    var rebloggerID: String?
    let isHashtagged: Bool
    let isPinned: Bool
    let isPrivateMention: Bool
    let isOwn: Bool
    
    var isBlocked: Bool
    var isMuted: Bool

    var mediaAttachments: [Attachment]
    var hasMediaAttachment: Bool
    let mediaDisplayType: MediaDisplayType
    var linkCard: Card?
    var hasLink: Bool
    let hideLinkImage: Bool
    let formattedCardUrlStr: String?
    var statusSource: [StatusSource]?
    
    enum FilterType {
        case warn(String)
        case hide(String)
        case none
    }
    
    var filterType: FilterType
    
    enum MediaDisplayType {
        case singleImage
        case singleVideo
        case carousel
        case none
    }
    
    enum QuotePostStatus: Int, CaseIterable, Equatable {
        case disabled
        case loading
        case fetched
        case notFound
        
        static func == (lhs: QuotePostStatus, rhs: QuotePostStatus) -> Bool {
            switch(lhs, rhs) {
            case (.disabled, .disabled):
                return true
            case (.loading, .loading):
                return true
            case (.fetched, .fetched):
                return true
            case (.notFound, .notFound):
                return true
            default:
                return false
            }
        }
    }
    
    var videoPlayer: AVPlayer?
    
    let hasQuotePost: Bool
    let quotePostCard: Card?
    var quotePostData: PostCardModel?
    var quotePostStatus: QuotePostStatus = .disabled
    var quotePreloadTask: Task<Void, Error>?
    

    // Computed / dynamic properties
    
    var likeCount: String {
        switch data {
        case .mastodon(let status):
            return PostCardModel.formattedLikeCount(status: status, withStaticMetrics: self.staticMetrics)
            
        case .bluesky(let postVM):
            return (postVM.post.likeCount ?? 0).formatUsingAbbrevation()
        }
    }
    
    var isLiked: Bool {
        if let value = StatusCache.shared.hasLocalMetric(metricType: .like, forStatusId: uniqueId) {
            return value
        }
        
        switch data {
        case .mastodon(let status):
            return status.reblog?.favourited ?? status.favourited ?? false
            
        case .bluesky(let postVM):
            return postVM.post.viewer?.like != nil
            
        }
    }
    
    var replyCount: String {
        switch data {
        case .mastodon(let status):
            return max((status.reblog?.repliesCount ?? status.repliesCount), 0).formatUsingAbbrevation()
            
        case .bluesky(let postVM):
            return (postVM.post.replyCount ?? 0).formatUsingAbbrevation()
        }
    }
    
    var hasReplies: Bool {
        switch data {
        case .mastodon(let status):
            return (status.reblog?.repliesCount ?? status.repliesCount) > 0
            
        case .bluesky(let postVM):
            return (postVM.post.replyCount ?? 0) > 0
        }
    }
    
    var repostCount: String {
        switch data {
        case .mastodon(let status):
            return PostCardModel.formattedRepostCount(status: status, withStaticMetrics: self.staticMetrics)
            
        case .bluesky(let postVM):
            return (postVM.post.repostCount ?? 0).formatUsingAbbrevation()
        }
    }
    
    var isReposted: Bool {
        if let value = StatusCache.shared.hasLocalMetric(metricType: .repost, forStatusId: self.uniqueId) {
            return value
        }
        
        switch data {
        case .mastodon(let status):
            return status.reblog?.reblogged ?? status.reblogged ?? false
            
        case .bluesky(let postVM):
            return postVM.post.viewer?.repost != nil
        }
    }
    
    var isBookmarked: Bool {
        if let value = StatusCache.shared.hasLocalMetric(metricType: .bookmark, forStatusId: self.uniqueId) {
            return value
        }
        
        switch data {
        case .mastodon(let status):
            return status.reblog?.bookmarked ?? status.bookmarked ?? false
            
        case .bluesky:
            return false
        }
    }
    
    var time: String {
        switch data {
        case .mastodon(let status):
            return PostCardModel.formattedTime(status: status, formatter: GlobalStruct.dateFormatter)
            
        case .bluesky(let postVM):
            return postVM.post.record.createdAt.toStringWithRelativeTime()
        }
    }
    
    var source: String {
        var sourceDescription = ""
        if let statusSource, statusSource.count > 0 {
            sourceDescription = "from "
            for (index, source) in statusSource.enumerated() {
                var sourceName: String
                switch source.source {
                case .Follows:
                    sourceName = "Trending Follows"
                case .FriendsOfFriends:
                    sourceName = "Friend of a Friend"
                case .MammothPick:
                    sourceName = "Mammoth Picks"
                case .SmartList:
                    sourceName = source.title ?? "Smart List"
                default:
                    sourceName = "Other"
                }
                sourceDescription += sourceName
                if statusSource.count > index+1 {
                    sourceDescription += ", "
                }
            }
        }
        return sourceDescription
    }
    
    init(status: Status, withStaticMetrics staticMetrics: Bool = false, instanceName: String? = nil) {
        self.data = .mastodon(status)
        self.staticMetrics = staticMetrics
        self.instanceName = instanceName

        self.id = status.reblog?.id ?? status.id
        self.cursorId = status.id
        self.uniqueId = status.uniqueId

        self.originalId = (status.reblog ?? status).originalId
        self.originalInstanceName = (status.reblog ?? status).serverName

        self.url = status.reblog?.url ?? status.url
        self.uri = status.reblog?.uri ?? status.uri
        self.createdAt = (status.reblog?.createdAt ?? status.createdAt).toDate()
        self.emojis = status.reblog?.emojis ?? status.emojis
        
        // Username formatting
        self.username = PostCardModel.formattedUsername(status: status)
        self.richUsername = NSAttributedString(string: self.username)
        
        self.rebloggerUsername = PostCardModel.formattedUsername(status: status, reblogger: true)
        self.richRebloggerUsername = NSAttributedString(string: self.rebloggerUsername)
        
        self.account = status.reblog?.account ?? status.account
        self.user = self.account != nil ? UserCardModel(account: self.account!) : nil

        // User tag formatting
        self.userTag = (status.reblog?.account?.acct ?? status.account?.acct ?? "")
        self.fullUserTag = (status.reblog?.account?.fullAcct ?? status.account?.fullAcct ?? "")
        
        // Profile url formatting
        self.profileURL = PostCardModel.formattedProfileURL(status: status)
        
        // Is account locked?
        self.isLockedAccount = status.reblog?.account?.locked ?? status.account?.locked ?? false
        
        // Post text formatting
        self.postText = PostCardModel.formattedPostText(status: status)
        self.richPostText = removeTrailingLinebreaks(string: NSAttributedString(string: self.postText))
        
        // Content warning (applies to entire post)
        self.contentWarning = (status.reblog?.spoilerText ?? status.spoilerText).stripHTML()
        
        // Sensitive content
        self.isSensitive = status.reblog?.sensitive ?? status.sensitive ?? false

        // Contains poll?
        self.containsPoll = PostCardModel.containsPoll(status: status)
        
        // The poll to display
        self.poll = status.reblog?.poll ?? status.poll
        
        // Should show reply indicator?
        self.isAReply = PostCardModel.isAReply(status: status)
        
        // Is a reblog
        self.isReblogged = status.reblog != nil
        self.rebloggerID = status.reblog?.account?.id
        
        // Is hashtagged
        self.isHashtagged = false
        
        self.isPinned = status.reblog?.pinned ?? status.pinned ?? false
        
        self.isPrivateMention = status.visibility == .direct
        
        // Is this post from the logged in user?
        self.isOwn = AccountsManager.shared.currentUser()?.id != nil && (status.reblog?.account?.id ?? status.account?.id ?? "") == AccountsManager.shared.currentUser()!.id

        // All image attachments
        if status.reblog?.mediaAttachments.count ?? status.mediaAttachments.count > 0 {
            self.mediaAttachments = (status.reblog?.mediaAttachments ?? status.mediaAttachments).filter({$0.type != .unknown})
        } else {
            self.mediaAttachments = []
        }

        // Has an image/video/audio to display
        self.hasMediaAttachment = self.mediaAttachments.count > 0
        
        if self.mediaAttachments.count > 1 {
            self.mediaDisplayType = .carousel
        } else if self.mediaAttachments.count == 1 {
            switch self.mediaAttachments.first?.type {
            case .image:
                self.mediaDisplayType = .singleImage
            case .gifv, .video:
                self.mediaDisplayType = .singleVideo
            default:
                // TODO: enable single media view for all media types when implementation is done (video, gifs, images and audio)
                self.mediaDisplayType = .carousel
            }
        } else {
            self.mediaDisplayType = .none
        }

        // The link to display
        self.linkCard = status.reblog?.card ?? status.card
        
        // Post has a link to display
        self.hasLink = self.linkCard?.url != nil
        
        // Hide the link image if there is a media attachment
        self.hideLinkImage = self.hasMediaAttachment
        
        // Format card url to only domain
        if #available(iOS 16.0, *),
            let urlString = self.linkCard?.url {
            let urlFormatStyle = URL.FormatStyle()
                .scheme(.omitIfHTTPFamily)
                .user(.never)
                .password(.never)
                .host(.omitSpecificSubdomains(["www", "mobile", "m"]))
                .port(.omitIfHTTPFamily)
                .path(.never)
                .query(.never)
                .fragment(.never)
            
            if let url = URL(string: urlString)?.formatted(urlFormatStyle) {
                self.formattedCardUrlStr = url
            } else {
                self.formattedCardUrlStr = nil
            }
        } else {
            self.formattedCardUrlStr = nil
        }
        
        self.applicationName = ((status.reblog?.application ?? status.application)?.name.stripHTML() ?? status.reblog?.application?.name ?? status.application?.name)
        
        self.visibility = (status.reblog?.visibility ?? status.visibility).rawValue.lowercased()
        
        // Contains quote post?
        self.hasQuotePost = (status.reblog?.quotePostCard() ?? status.quotePostCard()) != nil
        
        // Quote post card
        self.quotePostCard = status.reblog?.quotePostCard() ?? status.quotePostCard()
        
        // Quote post status data
        if self.hasQuotePost {
            if let urlStr = self.quotePostCard?.url,
                let url = URL(string: urlStr),
               let cachedQuoteStatus = StatusCache.shared.cachedStatusForURL(url: url) {
                // If local quote post status found, use it
                self.quotePostData = PostCardModel(status: cachedQuoteStatus, withStaticMetrics: false)
                self.quotePostStatus = .fetched
            } else {
                // If no local quote post status found, assume we'll prefetch it
                self.quotePostStatus = .loading
            }
        }
        
        // Status
        self.statusSource = nil
        
        // Filters
        self.filterType = status.filtered?.reduce(FilterType.none) { result, current in
            if case .hide(_) = result { return result }
            if current.filter.filterAction == "hide" { return .hide(current.filter.title) }
            return .warn(current.filter.title)
        } ?? FilterType.none
        
        let blockedIds = ModerationManager.shared.blockedUsers.map { $0.remoteFullOriginalAcct }
        let mutedIds = ModerationManager.shared.mutedUsers.map { $0.remoteFullOriginalAcct }
        
        if let acctID = self.account?.remoteFullOriginalAcct {
            self.isBlocked = blockedIds.contains(acctID)
            self.isMuted = mutedIds.contains(acctID)
        } else {
            self.isBlocked = false
            self.isMuted = false
        }
    }
    
    convenience init(status: Status, withStaticMetrics staticMetrics: Bool = false, instanceName: String? = nil, batchId: String? = nil, batchItemIndex: Int? = nil) {
        self.init(status: status, withStaticMetrics: staticMetrics, instanceName: instanceName)
        self.batchId = batchId
        self.batchItemIndex = batchItemIndex
    }
    
    init(blueskyPostVM postVM: BlueskyPostViewModel, uniqueID: String? = nil) {
        self.data = .bluesky(postVM)
        self.staticMetrics = false
        self.instanceName = nil
        
        self.id = postVM.post.uri
        self.cursorId = self.id
        self.uniqueId = uniqueID ?? UUID().uuidString
        self.originalId = self.id
        self.originalInstanceName = nil
        self.url = nil
        self.uri = nil
        self.createdAt = Date()
        self.emojis = nil
        
        // Username formatting
        self.username = postVM.post.author.uiDisplayName
        self.richUsername = nil
        
        self.rebloggerUsername = ""
        self.richRebloggerUsername = nil
        
        self.account = Account(postVM.post.author)
        self.user = account.map { UserCardModel(account: $0) }
        
        self.userTag = postVM.post.author.handle
        self.fullUserTag = postVM.post.author.handle
        
        self.profileURL = postVM.post.author.avatar.flatMap {
            URL(string: $0)
        }
        
        self.isLockedAccount = false
        
        self.postText = postVM.post.record.text
        self.richPostText = nil
        
        self.contentWarning = ""
        self.isSensitive = false

        self.containsPoll = false
        self.poll = nil
        
        self.isAReply = false
        
        self.isReblogged = false
        self.rebloggerID = nil
        self.isHashtagged = false
        
        self.isPinned = false
        self.isPrivateMention = false
        
        self.isOwn = postVM.isAuthorMe

        self.mediaAttachments = postVM.images.map { Attachment(image: $0) }
        self.hasMediaAttachment = !postVM.images.isEmpty
        self.mediaDisplayType = .carousel
        
        self.hasLink = false
        self.linkCard = nil
        self.hideLinkImage = false
        self.formattedCardUrlStr = nil
        
        self.applicationName = ""
        self.visibility = ""
        
        self.hasQuotePost = postVM.quotedPost != nil
        
        self.quotePostStatus = {
            guard let quotedPost = postVM.quotedPost
            else { return .disabled }
            
            switch quotedPost {
            case .post: return .fetched
            case .notFound: return .notFound
            }
        }()
        
        self.quotePostData = { () -> PostCardModel? in
            guard let quotedPost = postVM.quotedPost
            else { return nil }
            
            switch quotedPost {
            case .notFound:
                return nil
                
            case .post(let postValue):
                let post = Model.Feed.PostView(
                    uri: postValue.viewRecord.uri,
                    cid: postValue.viewRecord.cid,
                    indexedAt: postValue.viewRecord.indexedAt,
                    author: postValue.viewRecord.author,
                    record: postValue.viewRecord.value,
                    embed: postValue.viewRecord.embeds?.first,
                    likeCount: nil,
                    replyCount: nil,
                    repostCount: nil,
                    viewer: nil)
                
                let postVM = BlueskyPostViewModel(
                    post: post,
                    myUserID: "")
                
                return PostCardModel(blueskyPostVM: postVM)
            }
        }()
        
        self.quotePostCard = {
            guard let quotedPost = postVM.quotedPost
            else { return nil }
            
            switch quotedPost {
            case .post:
                return Card(
                    url: nil,
                    title: "",
                    description: "",
                    type: .link)
                
            case .notFound:
                return nil
            }
        }()

        // Status
        self.statusSource = nil
        self.filterType = .none
        
        self.isBlocked = false
        self.isMuted = false
    }

    func copy(with zone: NSZone? = nil) -> PostCardModel {
        switch data {
        case .mastodon(let status):
            return PostCardModel(status: status, withStaticMetrics: staticMetrics, batchId: self.batchId, batchItemIndex: self.batchItemIndex)
        case .bluesky(let postVM):
            return PostCardModel(blueskyPostVM: postVM, uniqueID: uniqueId)
        }
    }
    
    func withNewPoll(poll: Poll) -> PostCardModel {
        let card = self.copy()
        card.poll = poll
        return card
    }
    
    func withNewQuotePost(status: Status?) -> PostCardModel {
        let card = self.copy()
        if let status = status {
            card.quotePostData = PostCardModel(status: status, withStaticMetrics: false)
            card.quotePostStatus = .fetched
        } else {
            card.quotePostStatus = .notFound
        }
        
        return card
    }
    
    func withNewUser(user: UserCardModel) -> PostCardModel {
        let card = self.copy()
        card.user = user
        card.account = user.account
        return card
    }
    
    /// Only merge in parts of the original status we're interested in (metrics and applicationName)
    func mergeInOriginalData(status newStatus: Status) -> Self {
        if self.preSyncData == nil {
            self.preSyncData = self.data
        }
        // updating the data object so that computed properties 
        // e.g. likesCount is getting updated
        if self.isReblogged {
            if case .mastodon(let status) = data {
                status.reblog = newStatus
                self.data = .mastodon(status)
            }
        } else {
            self.data = .mastodon(newStatus)
        }
        // application name is only known by the original post
        self.applicationName = ((newStatus.reblog?.application ?? newStatus.application)?.name.stripHTML() ?? newStatus.reblog?.application?.name ?? newStatus.application?.name)
        
        // Filters
        self.filterType = newStatus.filtered?.reduce(FilterType.none) { result, current in
            if case .hide(_) = result { return result }
            if current.filter.filterAction == "hide" { return .hide(current.filter.title) }
            return .warn(current.filter.title)
        } ?? FilterType.none
        
        // Muted and Blocked
        let blockedIds = ModerationManager.shared.blockedUsers.map { $0.remoteFullOriginalAcct }
        let mutedIds = ModerationManager.shared.mutedUsers.map { $0.remoteFullOriginalAcct }
        
        if let acctID = self.account?.remoteFullOriginalAcct {
            self.isBlocked = blockedIds.contains(acctID)
            self.isMuted = mutedIds.contains(acctID)
        } else {
            self.isBlocked = false
            self.isMuted = false
        }
        
        self.isSyncedWithOriginal = true
        return self
    }
}

// MARK: - Preload
extension PostCardModel {
    var preloadedImageURLs: [String] {
        let firstImageAttached = self.mediaAttachments.compactMap({ attachment in
            if [.image, .gifv, .video].contains(where: {$0 == attachment.type}),
                let url = attachment.previewURL {
                return url
            }
            return nil
        }).first
        
        return [
            // Prefetch the profile picture
            self.user?.imageURL,
            // Prefetch the first image attached
            firstImageAttached,
            // Prefetch the link card image
            !self.hideLinkImage ? self.linkCard?.image?.absoluteString : nil
        ].compactMap({$0})
    }
    
    func preloadImages() {
        let urls = self.preloadedImageURLs
            .filter({ !SDImageCache.shared.diskImageDataExists(withKey: $0) })
            .compactMap({URL(string: $0)})
        
        if !urls.isEmpty {
            DispatchQueue.global(qos: .default).async {
                SDWebImagePrefetcher.shared.prefetchURLs(urls, progress: nil, completed: nil)
            }
        }
    }
    
    func preloadVideo() {
        if GlobalStruct.autoPlayVideos {
            if self.videoPlayer == nil, let media = self.mediaAttachments.first, let videoURL = URL(string: media.url) {
                DispatchQueue.global(qos: .default).async {
                    let playerItem = AVPlayerItem(url: videoURL)
                    let player = AVPlayer(playerItem: playerItem)
                    player.isMuted = true
                    DispatchQueue.main.async {
                        self.videoPlayer = player
                    }
                }
            }
        }
    }
    
    func preloadQuotePost() {
        guard case .mastodon = data,
            self.hasQuotePost,
            self.quotePostStatus != .fetched,
            let quoteUrlStr = self.quotePostCard?.url,
            let quoteUrl = URL(string: quoteUrlStr)
        else { return }
        
        self.quotePreloadTask = Task {
            StatusCache.shared.cacheStatusForURL(url: quoteUrl) { (url, status) in
                guard !Task.isCancelled else { return }
                let newPostCard = self.withNewQuotePost(status: status)
                    DispatchQueue.main.async {
                        if newPostCard.quotePostStatus != self.quotePostStatus {
                            if let _ = newPostCard.batchId {
                                newPostCard.batchId! += " (EDITED)"
                            }
                            log.debug("preload quote post: \(newPostCard.uniqueId ?? "unknown")")
                            // Consolidate list data with updated post card data and request a cell refresh
                            NotificationCenter.default.post(name: PostActions.didUpdatePostCardNotification, object: nil, userInfo: ["postCard": newPostCard])
                        }
                }
            }
        }
    }
    
    func cancelAllPreloadTasks() {
        self.videoPlayer?.pause()
        self.videoPlayer = nil
        if let task = self.quotePreloadTask, !task.isCancelled {
            task.cancel()
        }
    }
    
    func clearCache() {
        self.videoPlayer?.pause()
        self.videoPlayer = nil
        self.preloadedImageURLs.forEach({
            SDImageCache.shared.removeImageFromMemory(forKey: $0)
        })
    }
}

// MARK: - Formatters
extension PostCardModel {
    static func formattedLikeCount(status: Status, withStaticMetrics staticMetrics: Bool = false) -> String {
        let hasLocal = StatusCache.shared.hasLocalMetric(metricType: .like, forStatusId: status.uniqueId)
        let localCount = hasLocal != nil ? hasLocal! ? 1 : 0 : 0
        let isFavorited = status.reblog?.favourited ?? status.favourited
        let onlineCount = status.reblog?.favouritesCount ?? status.favouritesCount
        // Add 1 to the count:
        //  - when we know the post has static metrics (For You feed) and we know locally the post has been liked
        //  - when we know locally the post has been liked but it's not yet reflected online (optimistic updates)
        //  - when the online post returns 'favorited' but the count is still zero
        // Additionally, make sure the result is never < 0
        if staticMetrics {
            return max(onlineCount + localCount, 0).formatUsingAbbrevation()
        }
        if localCount > 0 && (isFavorited ?? false) == false {
            return max(onlineCount + localCount, 0).formatUsingAbbrevation()
        }
        if (isFavorited ?? false) == true && onlineCount == 0 {
            return max(onlineCount + 1, 0).formatUsingAbbrevation()
        }
        
        return max(onlineCount, 0).formatUsingAbbrevation()
    }
    
    static func formattedRepostCount(status: Status, withStaticMetrics staticMetrics: Bool = false) -> String {
        let hasLocal = StatusCache.shared.hasLocalMetric(metricType: .repost, forStatusId: status.uniqueId)
        let localCount = hasLocal != nil ? hasLocal! ? 1 : 0 : 0
        let isReblogged = status.reblog?.reblogged ?? status.reblogged
        let onlineCount = status.reblog?.reblogsCount ?? status.reblogsCount
        // Add 1 to the count:
        //  - when we know the post has static metrics (For You feed) and we know locally the post has been reblogged
        //  - when we know locally the post has been reblogged but it's not yet reflected online (optimistic updates)
        //  - when the online post returns 'reblogged' but the count is still zero
        // Additionally, make sure the result is never < 0
        if staticMetrics {
            return max(onlineCount + localCount, 0).formatUsingAbbrevation()
        }
        if localCount > 0 && (isReblogged ?? false) == false {
            return max(onlineCount + localCount, 0).formatUsingAbbrevation()
        }
        if (isReblogged ?? false) == true && onlineCount == 0 {
            return max(onlineCount + 1, 0).formatUsingAbbrevation()
        }
        
        return max(onlineCount, 0).formatUsingAbbrevation()
    }
    
    static func formattedUsername(status: Status, reblogger: Bool = false) -> String {
        var username = ""
        if reblogger {
            if let account = status.account {
                username = !account.displayName.isEmpty ? account.displayName : account.username
            }
        } else {
            if let reblog = status.reblog, let account = reblog.account {
                username = !account.displayName.isEmpty ? account.displayName : account.username
            } else  if let account = status.account {
                username = !account.displayName.isEmpty ? account.displayName : account.username
            }
        }
        
        return self.formattedUsername(username: username)
    }
    
    static func formattedUsername(username: String) -> String {
        return username
    }
    
    static func formattedTime(status: Status, formatter: DateFormatter) -> String {
        let createdAt = (status.reblog?.createdAt ?? status.createdAt)
        var timeStr = formatter.date(from: createdAt)?.toStringWithRelativeTime() ?? ""

        if GlobalStruct.originalPostTimeStamp == false {
           let createdAt = status.createdAt
           timeStr = formatter.date(from: createdAt)?.toStringWithRelativeTime() ?? ""
        }

        if GlobalStruct.timeStampStyle == 1 {
           let createdAt = (status.reblog?.createdAt ?? status.createdAt)
           timeStr = formatter.date(from: createdAt)?.toString(dateStyle: .short, timeStyle: .short) ?? ""
           if GlobalStruct.originalPostTimeStamp == false {
               let createdAt = (status.createdAt)
               timeStr = formatter.date(from: createdAt)?.toString(dateStyle: .short, timeStyle: .short) ?? ""
           }
           
        } else if GlobalStruct.timeStampStyle == 2 {
           timeStr = ""
        }

        return timeStr
    }
    
    static func formattedProfileURL(status: Status) -> URL? {
        return self.formattedProfileURL(urlString: status.reblog?.account?.avatarStatic ?? status.account?.avatarStatic ?? "")
    }
    
    static func formattedProfileURL(urlString: String) -> URL? {
        if let profileURL = URL(string: urlString) {
            return profileURL
        }
        
        return nil
    }
    
    // Strips out HTML, including links, and returns the plain text of the post
    static func formattedPostText(status: Status) -> String {
        var text = (status.reblog?.content ?? status.content)
        
        if GlobalStruct.maxLines != 0 {
            text = text.replacingOccurrences(of: "<br />", with: " ")
            text = text.replacingOccurrences(of: "\n", with: " ")
        }

        if let url = status.reblog?.quotePostCard()?.url ?? status.quotePostCard()?.url {
            // Remove quote post url from text
            let regex = try! NSRegularExpression(pattern: "<a[^>]*href=\"\(url)\"[^>]*>(?!.*<a[^>]*href=\"\(url)\"[^>]*>).*?</a>", options: .caseInsensitive)
            let range = NSMakeRange(0, text.count)
            text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        
        if let url = status.reblog?.card?.url ?? status.card?.url {
            // Remove link card url from text
            do {
                let regex = try NSRegularExpression(pattern: "<a[^>]*href=\"\(url)\"[^>]*>(?!.*<a[^>]*href=\"\(url)\"[^>]*>).*?</a>", options: .caseInsensitive)
                let range = NSMakeRange(0, text.count)
                text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            } catch let error {
                log.error("PostCardModel: Unable to remove link from post text: \(error)")
            }
        }
        
        return text.stripHTML()
    }
    
    static func containsPoll(status: Status) -> Bool {
        if let _ = status.reblog?.poll ?? status.poll {
            return true
        } else {
            return false
        }
    }
    
    static func isAReply(status: Status) -> Bool {
        if status.reblog?.inReplyToID ?? status.inReplyToID != nil {
            return true
        } else {
            return false
        }
    }
}

extension PostCardModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueId)
    }
}

extension PostCardModel: Equatable {
    static func == (lhs: PostCardModel, rhs: PostCardModel) -> Bool {
        return lhs.uniqueId == rhs.uniqueId &&
        lhs.quotePostStatus == rhs.quotePostStatus &&
        lhs.poll?.voted == rhs.poll?.voted &&
        lhs.postText == rhs.postText &&
        lhs.mediaAttachments.count == rhs.mediaAttachments.count &&
        lhs.isLiked == rhs.isLiked &&
        lhs.likeCount == rhs.likeCount &&
        lhs.replyCount == rhs.replyCount &&
        lhs.repostCount == rhs.repostCount &&
        lhs.applicationName == rhs.applicationName
    }
}
