//
//  NewsFeedViewModel+Services.swift
//  Mammoth
//
//  Created by Benoit Nolens on 28/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SDWebImage

public enum NewsFeedFetchType {
    case nextPage       // append older posts (bottom)
    case previousPage   // insert newer posts (top)
    case refresh        // refresh list with newest
}

// MARK: - Services
extension NewsFeedViewModel {

    func loadListData(type: NewsFeedTypes? = nil, fetchType: NewsFeedFetchType = .refresh) async throws {
        try await loadListDataMastodon(type: type, fetchType: fetchType)
    }
        
    func loadListDataMastodon(type: NewsFeedTypes? = nil, fetchType: NewsFeedFetchType = .refresh) async throws {
        let currentType = type ?? self.type
        let requestingUser = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID
        
        if case .error(_) = self.state { return }
        
        do  {
            switch fetchType {
            // Fetch older posts
            case .nextPage:
                self.state = .loading
                self.displayLoader(forType: currentType)

                if let lastId = self.oldestItemId(forType: currentType) {
                    let (items, cursorId) = try await currentType.fetchAll(range: RequestRange.max(id: lastId, limit: 20), batchName: "next-page_batch")
  
                    let newItems = items.removeMutesAndBlocks().removeFiltered()
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }

                        // Abort if user changed in the meantime
                        guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }

                        self.cursorId = cursorId
                        
                        if let current = self.listData.forType(type: currentType) {
                            let currentIds = current.compactMap({ $0.extractUniqueId() })
                            let uniqueNewItems = newItems.filter({ !currentIds.contains($0.extractUniqueId() ?? "") }).removingDuplicates()
                            if !uniqueNewItems.isEmpty {
                                self.append(items: uniqueNewItems, forType: currentType)
                                self.hideEmpty(forType: currentType)
                            }
                            
                            self.state = .success
                            self.hideLoader(forType: currentType)
                            
                            // Preload quote posts
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                uniqueNewItems.forEach({
                                    $0.extractPostCard()?.preloadQuotePost()
                               })
                            }
                            
                            // Clear cached video players of items higher up
                            if self.snapshot.itemIdentifiers.count > 60 {
                                let firstSection = Array(self.snapshot.itemIdentifiers[0...self.snapshot.itemIdentifiers.count-40])
                                firstSection.forEach({
                                    if case .postCard(let postCard) = $0 {
                                        postCard.clearCache()
                                    }
                                })
                            }
                        } else {
                            self.set(withItems: newItems, forType: currentType)
                            self.state = .success
                            self.hideLoader(forType: currentType)
                            
                            // Preload quote posts
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                newItems.forEach({
                                    $0.extractPostCard()?.preloadQuotePost()
                                })
                            }
                        }
                        
                        if cursorId == nil {
                            self.isLoadMoreEnabled = false
                        }
                    }
                } else {
                    self.state = .success
                    self.hideLoader(forType: currentType)
                }
                
            // Fetch newer posts
            case .previousPage:
                
                if let firstId = self.newestItemId(forType: currentType) {
                    let (items, cursorId) = try await currentType.fetchAll(range: RequestRange.min(id: firstId, limit: 20), batchName: "previous-page_batch")
                    
                    let newItems = items.removeMutesAndBlocks().removeFiltered()

                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }

                        // Abort if user changed in the meantime
                        guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }

                        self.cursorId = cursorId
                        
                        if let current = self.listData.forType(type: currentType) {
                            let currentIds = current.compactMap({ $0.extractUniqueId() })
                            let newUniqueItems = newItems.filter({ !currentIds.contains($0.extractUniqueId() ?? "") }).removingDuplicates()
                            if !newUniqueItems.isEmpty {
                                self.insert(items: newUniqueItems, forType: currentType)
                                self.hideEmpty(forType: currentType)
                            }
                                                        
                            // Preload quote posts
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                newUniqueItems.forEach({
                                    $0.extractPostCard()?.preloadQuotePost()
                               })
                            }
                        } else {
                            self.set(withItems: newItems, forType: currentType)
                            
                            // Preload quote posts
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                newItems.forEach({ $0.extractPostCard()?.preloadQuotePost() })
                            }
                        }
                    }
                }
                break
                
            // Refresh list
            case .refresh:
                self.state = .loading
                self.isLoadMoreEnabled = true
                
                let (item, cursorId) = try await currentType.fetchAll(batchName: "refresh_batch")
                let newItems = item.removeMutesAndBlocks().removeFiltered()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }

                    // Abort if user changed in the meantime
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }

                    self.cursorId = cursorId
                    
                    if cursorId == nil {
                        self.isLoadMoreEnabled = false
                        self.showEmpty(forType: currentType)
                    } else {
                        self.hideEmpty(forType: currentType)
                    }
                    
                    self.set(withItems: newItems, forType: currentType)
                    self.state = .success
                    self.hideLoader(forType: currentType)
                    
                    // Preload quote posts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        newItems.forEach({
                            $0.extractPostCard()?.preloadQuotePost()
                       })
                    }
                }
            }
            
        } catch let error {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state = .error(error)
                self.displayError(feedType: self.type)
                if case .refresh = fetchType  {
                    self.isLoadMoreEnabled = true
                    self.hideLoader(forType: currentType)
                } else if case .nextPage = fetchType  {
                    self.isLoadMoreEnabled = true
                    self.hideLoader(forType: currentType)
                }
            }
            
            throw error
        }
    }
    
    func loadListDataBluesky(account: BlueskyAcctData, type: NewsFeedTypes? = nil, fetchType: NewsFeedFetchType = .refresh) async throws {
        let currentType = type ?? self.type
        
        do {
            switch fetchType {
            // Fetch older posts
            case .nextPage:
                break
                
            // Fetch newer posts
            case .previousPage:
                break // Not possible in Bluesky
                
            // Refresh list
            case .refresh:
                self.state = .loading
                self.displayLoader(forType: currentType)
                self.isLoadMoreEnabled = true
                
                let response = try await account.api.getTimeline(cursor: nil)
                
                DispatchQueue.main.async { [weak self]  in
                    guard let self else { return }
//                    self.blueskyCursor = response.cursor
                    let postCards = Self.postCardModels(fromBlueskyResponse: response, myUserID: account.userID)
                    
                    if postCards.isEmpty {
                        self.isLoadMoreEnabled = false
                    }
                    self.set(withCards: postCards, forType: currentType)
                    self.state = .success
                    self.hideLoader(forType: currentType)
                }
            }
            
        } catch let error {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state = .error(error)
                self.displayError(feedType: self.type)
                if case .refresh = fetchType  {
                    self.isLoadMoreEnabled = true
                    self.hideLoader(forType: currentType)
                } else if case .nextPage = fetchType  {
                    self.isLoadMoreEnabled = true
                    self.hideLoader(forType: currentType)
                }
            }
            
            throw error
        }
    }
    
    func startCheckingFYStatus(completion: @escaping(() -> Void)) {
        self.forYouStatus = .pending
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self.hideServerUpdated(feedType: self.type)
            self.hideServerOverload(feedType: self.type)
            let updateType = self.displayServerUpdating(feedType: self.type) // Will move it up if needed
            DispatchQueue.main.sync {
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: self.type,
                                                 updateType: updateType, onCompleted: nil)
                completion()
            }
        }
    }
    
    // Return true if there is a server updating/server updated/server overload case happening
    func loadForYouStatus(feedType: NewsFeedTypes, forceFYCheck: Bool) async throws -> Bool {
        if case .error(_) = self.state { return false }
        if feedType != .forYou { return false }
        if !forceFYCheck && forYouStatus == .idle { return false } // Only bother if unknown or in progress
        
        // Check the ForYou status from the server
        guard let remoteFullOriginalAcct = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct else { return false }
        let updatedFYStatus = try await TimelineService.forYouMe(remoteFullOriginalAcct: remoteFullOriginalAcct).forYou.status
        log.debug("For You idle check result.forYou.status: \(updatedFYStatus)")

        var updateType: NewsFeedSnapshotUpdateType? = nil
        // Check for server overload
        if updatedFYStatus == .overloaded {
            self.hideServerUpdated(feedType: feedType)
            self.hideServerUpdating(feedType: feedType)
            updateType = self.displayServerOverload(feedType: feedType) // Will move it up if needed
        }
        // Check if still Updating...
        else if updatedFYStatus == .pending {
            self.hideServerUpdated(feedType: feedType)
            self.hideServerOverload(feedType: feedType)
            updateType = self.displayServerUpdating(feedType: feedType) // Will move it up if needed
        }
        // Check if it just switched from Updating to Updated
        else if self.forYouStatus == .pending, updatedFYStatus == .idle {
            self.hideServerUpdating(feedType: feedType)
            self.hideServerOverload(feedType: feedType)
            updateType = self.displayServerUpdated(feedType: feedType)
        }
        // Check if it just switched from Overloaded to Updated
        else if self.forYouStatus == .overloaded, updatedFYStatus == .idle {
            self.hideServerUpdating(feedType: feedType)
            self.hideServerOverload(feedType: feedType)
            updateType = self.displayServerUpdated(feedType: feedType)
        }

        if let updateType {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: feedType,
                                                 updateType: updateType) {
                }
            }
        }
                
        self.forYouStatus = updatedFYStatus
        let showingUpdateRow = updateType != nil
        log.debug("loadForYouStatus showingUpdateRow:\(showingUpdateRow)")
        return showingUpdateRow
    }

    func loadLatest(feedType: NewsFeedTypes, threshold: Int? = nil) async throws {
        do {
            if case .error(_) = self.state { return }
            
            // Abord if the load-more button is in the viewport.
            // When appending the latest posts we might also clean older posts and remove the load-more button.
            // We don't want this to happen when the load-more button is visible. So we don't load any new posts 
            // in that case, but will try again a few seconds later.
            guard !(await self.isLoadMoreButtonInView(forType: feedType)) else { return }
            
            let requestingUser = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID
            
            let (item, cursorId) = try await feedType.fetchAll(range: .limit(60), batchName: "latest_batch")
            let newItems = item.removeMutesAndBlocks().removeFiltered()
            
            // Abort if user changed in the meantime
            guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
            guard !Task.isCancelled else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                self.cursorId = cursorId
                
                if let current = self.listData.forType(type: feedType) {
                    
                    // only keep newer posts - trim away what's already in the feed
                    var newItemsSlice = newItems
                    if self.isReadingNewest(forType: feedType) == nil || self.isReadingNewest(forType: feedType) == true {
                        // if reading newest, take the top item of the feed as the reference
                        let currentFirstUniqueId = current.first?.extractUniqueId()
                        if let currentFirstIndex = newItems.firstIndex(where: {$0.extractUniqueId() == currentFirstUniqueId}) {
                            newItemsSlice = Array(newItems[0...max(currentFirstIndex-1, 0)])
                            // if only one item new item is available and it's the same as the currentFirst
                            if newItems.count == 1 && currentFirstUniqueId == newItems[0].extractUniqueId() {
                                newItemsSlice = []
                            }
                        }
                    } else {
                        // if not yet reading the newest, take the one after the "read more" button as reference
                        if let currentFirstItem = self.firstOfTheOlderItems(forType: feedType),
                           let currentFirstUniqueId = currentFirstItem.extractUniqueId(),
                           let currentFirstIndex = newItems.firstIndex(where: {$0.extractUniqueId() == currentFirstUniqueId}) {
                            newItemsSlice = Array(newItems[0...max(currentFirstIndex-1, 0)])
                        
                            // if only one item new item is available and it's the same as the currentFirst
                            if newItems.count == 1 && currentFirstUniqueId == newItems[0].extractUniqueId() {
                                newItemsSlice = []
                            }
                        }
                    }
                    
                    
                    let currentIds = current.compactMap({ $0.extractUniqueId() })
                    let newUniqueItems = newItemsSlice.filter({
                        !currentIds.contains($0.extractUniqueId() ?? "")
                    }).removingDuplicates()
                    
                    if !newUniqueItems.isEmpty {
                        self.hideEmpty(forType: feedType)
                    }
                    
                    // Abort if user changed in the meantime
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
                    guard !Task.isCancelled else { return }
                    
                    if newUniqueItems.count >= (threshold ?? self.newItemsThreshold) {
                        if feedType != .mentionsIn && feedType != .mentionsOut && feedType != .activity {
                            self.stopPollingListData()
                        }
                        
                        let picUrls = newUniqueItems
                            .compactMap({ $0.extractPostCard()?.account })
                            .removingDuplicates()
                            .sorted { $0.followersCount > $1.followersCount }
                            .compactMap({ URL(string: $0.avatar) })
                        
                        if !picUrls.isEmpty {
                            self.setUnreadPics(urls: Array(picUrls[0...min(3, picUrls.count-1)]), forFeed: feedType)
                            SDWebImagePrefetcher.shared.prefetchURLs(picUrls, progress: nil, completed: nil)
                        }
                        
                        if newUniqueItems.count >= self.newestSectionLength {
                            let items = Array(newUniqueItems[0...self.newestSectionLength-1])
                            self.insertNewest(items: items,
                                              includeLoadMore: true,
                                              forType: feedType)
                        } else if newUniqueItems.count > 15 {
                            // The server might return less posts than requested, even if there are more posts available.
                            // To cover this case we optimistically display the "load more" button if > 15 posts are returned
                            self.insertNewest(items: newUniqueItems, includeLoadMore: true, forType: feedType)
                        } else {
                            self.insertNewest(items: newUniqueItems, includeLoadMore: false, forType: feedType)
                        }
                        
                        // Preload quote posts
                        newUniqueItems.forEach({
                            $0.extractPostCard()?.preloadQuotePost()
                        })
                        
                        // display a tab bar badge when new items are fetched
                        if feedType == .mentionsIn {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity2"), object: nil)
                        } else if feedType == .activity {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity"), object: nil)
                        }
                    }
                } else {
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
                    guard !Task.isCancelled else { return }
                    self.insertNewest(items: newItems,
                                      includeLoadMore: false,
                                      forType: feedType)
                }
            }
        } catch {
            guard !Task.isCancelled else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state = .error(error)
                self.displayError(feedType: self.type)
                log.error("error fetching newest posts: \(error)")
            }
            
            throw error
        }
    }
    
    func loadOlderPosts(feedType: NewsFeedTypes) async throws {
        do {
            let loadMoreLimit = 20
            let requestingUser = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID
            
            if let lastId = self.firstOfTheOlderItemsId(forType: feedType) {
                let (newItems, _) = try await feedType.fetchAll(range: RequestRange.min(id: lastId, limit: loadMoreLimit), batchName: "load-more_batch")
                
                // only keep older posts - trim away what's already in the feed
                var newItemsSlice = newItems.removeMutesAndBlocks().removeFiltered().removeMutesAndBlocks()
                
                if let currentFirstItem = self.lastItemOfTheNewestItems(forType: feedType),
                    let currentFirstId = currentFirstItem.extractUniqueId(),
                    let currentFirstIndex = newItems.firstIndex(where: {$0.extractUniqueId() == currentFirstId}) {
                    
                    if currentFirstIndex <= newItems.count-1 {
                        newItemsSlice = Array(newItems[(currentFirstIndex+1)...])
                    }
                    
                    // if only one new item is available and it's the same as the currentFirst
                    if newItems.count == 1 && currentFirstId == newItems[0].extractUniqueId() {
                        newItemsSlice = []
                    }
                }

                let newUniqueItems = newItemsSlice
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }

                    // Abort if user changed in the meantime
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
                    
                    if !newUniqueItems.isEmpty {
                        self.hideEmpty(forType: feedType)
                    }
                                        
                    // Abort if user changed in the meantime
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
                    
                    self.append(items: newUniqueItems, forType: feedType, after: .loadMore)
                    
                    if newUniqueItems.count == 0 {
                        self.hideLoadMore(feedType: feedType)
                        self.hideLoader(forType: feedType)
                        self.delegate?.didUpdateSnapshot(self.snapshot,
                                                         feedType: feedType,
                                                         updateType: .remove,
                                                         onCompleted: nil)
                    }
                }
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state = .error(error)
                self.displayError(feedType: self.type)
            }
        }
    }
    
    func preloadCards(atIndexPaths indexPaths: [IndexPath]) {
        indexPaths.forEach({
            if case .postCard(let postCard) = self.dataSource?.itemIdentifier(for: $0) {
                if postCard.quotePostStatus == .loading {
                    postCard.preloadQuotePost()
                }
                
                if postCard.mediaDisplayType == .singleVideo {
                    postCard.preloadVideo()
                }
                
                postCard.preloadImages()
            }
        })
    }
    
    func cancelPreloadCards(atIndexPaths indexPaths: [IndexPath]) {
        indexPaths.forEach({
            if case .postCard(let postCard) = self.dataSource?.itemIdentifier(for: $0) {
                postCard.cancelAllPreloadTasks()
            }
        })
    }
    
    func syncFollowStatusIfNeeded(item: NewsFeedListItem) {
        if let postCard = item.extractPostCard(), let account = postCard.account {
            if self.type.postCardCellType().shouldSyncFollowStatus(postCard: postCard) {
                DispatchQueue.main.async {
                    postCard.user!.followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: .whenUncertain)
                    if !item.deepEqual(with: .postCard(postCard)) {
                        NotificationCenter.default.post(name: PostActions.didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
                    }
                }
            }
        }
    }
    
    func startPollingListData(forFeed type: NewsFeedTypes, delay: Double = 0) {
        // In the For You case, we want to force a check of the ForYou status
        // the first time through this loop.
        let forceFYCheck: Bool = type == .forYou
        
        if self.pollingTask == nil || self.pollingTask!.isCancelled {
            self.pollingTask = Task { [weak self] in
                guard let self else { return }
                try await self.recursiveTask(retryCount: 5, frequency: self.pollingFrequency, delay: delay) { [weak self] in
                    guard let self else { return }
                    guard !NetworkMonitor.shared.isNearRateLimit else {
                        log.warning("Skipping polling task for \(type) due to rate limit")
                        return
                    }
                    // Only load the latest content if we are not showing
                    // the Updating or Updated rows.
                    //
                    // It's OK to load newer content if overloaded though (since it's likely
                    // showing Mammoth picks at that point).
                    let showingUpdateRow = try await self.loadForYouStatus(feedType:type, forceFYCheck: forceFYCheck)
                    if !showingUpdateRow || (showingUpdateRow && self.forYouStatus == .overloaded) {
                        log.debug("Calling loadLatest for feedType: \(type)")
                        try await self.loadLatest(feedType: type)
                    }
                }
            }
        }
    }
    
    func stopPollingListData() {
        self.pollingTask?.cancel()
    }
    
    func requestItemSync(forIndexPath indexPath: IndexPath, afterSeconds delay: CGFloat) {
        if let item = self.getItemForIndexPath(indexPath) {
            self.postSyncingTasks[indexPath] = Task { [weak self] in
                guard let self else { return }
                try await Task.sleep(seconds: delay)
                guard !NetworkMonitor.shared.isNearRateLimit else {
                    log.warning("Skipping syncing item due to rate limit")
                    return
                }
                
                guard !Task.isCancelled else { return }
                self.syncFollowStatusIfNeeded(item: item)
                try await self.syncItem(item: item)
            }
        }
    }
    
    func cancelItemSync(forIndexPath indexPath: IndexPath) {
        if let task = self.postSyncingTasks[indexPath], !task.isCancelled {
            task.cancel()
            self.postSyncingTasks[indexPath] = nil
        }
    }
    
    func cancelAllItemSyncs() {
        self.postSyncingTasks.forEach({ $1.cancel() })
        self.postSyncingTasks = [:]
    }
    
    func syncItem(item: NewsFeedListItem) async throws {
        guard !Task.isCancelled else { return }
        
        switch item {
        case .postCard(let postCard):
            guard !postCard.isSyncedWithOriginal else { return }
            do {
                if let status = try await StatusService.fetchStatus(id: postCard.originalId, instanceName: postCard.originalInstanceName ?? GlobalHostServer()) {
                    guard !Task.isCancelled else { return }

                    let newPostCard = postCard.mergeInOriginalData(status: status)
                    NotificationCenter.default.post(name: PostActions.didUpdatePostCardNotification, object: nil, userInfo: ["postCard": newPostCard])
                }
            } catch {
                guard !Task.isCancelled else { return }
                
                postCard.isSyncedWithOriginal = true
                
                switch error as? ClientError {
                case .mastodonError(let message):
                    if message == "Record not found" {
                        if let postCard = item.extractPostCard() {
                            let deletedPostCard = postCard
                            deletedPostCard.isDeleted = true
                            NotificationCenter.default.post(name: PostActions.didUpdatePostCardNotification, object: nil, userInfo: ["postCard": deletedPostCard])
                        }
                    }
                default:
                    NotificationCenter.default.post(name: PostActions.didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
                    break
                }
            }
            
            break
        default:
            break
        }
    }
}

// MARK: - Helpers
private extension NewsFeedViewModel {
    ///
    /// - Parameter retryCount: The amount of times the task should fail until it stops
    /// - Parameter frequency: The time in seconds waited **after** the task succeeded
    /// - Parameter delay: The time in seconds waited **before** the task is executed
    /// - Parameter task: The closure (task) called on each recursion
    func recursiveTask(retryCount: Int, frequency: Double, delay: Double = 0, task: () async throws -> Void) async throws -> Void {
        do {
            if Task.isCancelled { return }
            
            if retryCount <= 0  {
                self.pollingTask?.cancel()
                log.error("NewsFeed: recursive fetching stopped due to too many errors")
                return
            }
            
            try await Task.sleep(seconds: delay)
            if Task.isCancelled { return }
            try await task()
            try await Task.sleep(seconds: frequency)
            try await recursiveTask(retryCount: retryCount, frequency: frequency, task: task)
        } catch let error {
            if case is CancellationError = error {
                return
            }
            
            log.error("Recursive task error in \(#function): \(error)")
            try await Task.sleep(seconds: frequency / 2)
            try await recursiveTask(retryCount: retryCount-1, frequency: frequency, task: task)
        }
    }
    
    static func postCardModels(
        fromBlueskyResponse response: BlueskyAPI.FeedResponse,
        myUserID: String
    ) -> [PostCardModel] {
        let feedPosts = response.feed.compactMap { $0.value }
        
        let viewModels = feedPosts.map { feedPost in
            BlueskyPostViewModel(
                post: feedPost.post,
                myUserID: myUserID)
        }
        
        return viewModels.map {
            PostCardModel(blueskyPostVM: $0)
        }
    }
    
}
