//
//  ProfileViewSettingsButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 14/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

final class ProfileViewSettingsButton: UIButton {
    
    let onButtonPress: UserCardButtonCallback?
    var blurEffectView: BlurredBackground?
    var icon: UIImageView?
    var user: UserCardModel? {
        didSet {
            self.updateContextMenu()
        }
    }
    
    init(_ onButtonPress: @escaping UserCardButtonCallback) {
        self.onButtonPress = onButtonPress
        super.init(frame: .zero)
        setupUI()
        
        self.showsMenuAsPrimaryAction = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateContextMenu),
                                               name: didChangeListsNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateContextMenu),
                                               name: didChangeModerationNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onFollowStatusUpdate),
                                               name: didChangeFollowStatusNotification,
                                               object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
        self.layer.cornerRadius = 37 / 2
        self.clipsToBounds = true
        
        self.blurEffectView = BlurredBackground()
        self.blurEffectView!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.blurEffectView!)
        
        self.icon = UIImageView(image: UserCardButtonType.settings.icon()?.withRenderingMode(.alwaysTemplate))
        self.icon!.tintColor = .custom.highContrast
        icon!.translatesAutoresizingMaskIntoConstraints = false
        icon!.isUserInteractionEnabled = false
        self.addSubview(icon!)
        
        NSLayoutConstraint.activate([
            blurEffectView!.topAnchor.constraint(equalTo: self.topAnchor),
            blurEffectView!.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            blurEffectView!.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurEffectView!.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            blurEffectView!.widthAnchor.constraint(equalToConstant: 37.0),
            blurEffectView!.heightAnchor.constraint(equalToConstant: 37.0),
            
            icon!.centerXAnchor.constraint(equalTo: blurEffectView!.centerXAnchor),
            icon!.centerYAnchor.constraint(equalTo: blurEffectView!.centerYAnchor, constant: 1)
        ])
        
        self.onThemeChange()
    }
    
    @objc func onFollowStatusUpdate() {
        if let account = self.user?.account {
            self.user = UserCardModel(account: account)
        }
    }
    
    @objc func updateContextMenu() {
        DispatchQueue.main.async {
            self.menu = self.createContextMenu()
        }
    }
}

// MARK: - Configuration
extension ProfileViewSettingsButton {
    func onThemeChange() {
    }
    
    func didScroll(scrollView: UIScrollView) {
        let startOffset = 100.0 - scrollView.safeAreaInsets.top
        let endOffset = 110.0 - scrollView.safeAreaInsets.top
        if scrollView.contentOffset.y > startOffset && scrollView.contentOffset.y < endOffset {
            let opacity = 1 - Float(min(max((scrollView.contentOffset.y - startOffset) / (endOffset - startOffset), 0), 1))
            self.blurEffectView?.layer.opacity = opacity
        } else if scrollView.contentOffset.y >= endOffset {
            self.blurEffectView?.layer.opacity = 0
        } else {
            self.blurEffectView?.layer.opacity = 1
        }
    }
}

// MARK: Appearance changes
internal extension ProfileViewSettingsButton {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if (traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)) {
                 self.onThemeChange()
                 self.menu = self.createContextMenu()
            }
         }
    }
}


// MARK: - Context menu creators
extension ProfileViewSettingsButton {
    func createContextMenu() -> UIMenu {
        if let user = self.user {
            if user.isSelf {
                let options = [
                    createContextMenuAction("Share profile", .share, isActive: true, data: nil),
                    
                    createContextMenuAction("Favorites", .likes, isActive: true, data: nil),
                    createContextMenuAction("Bookmarks", .bookmarks, isActive: true, data: nil),
                    
                    createContextMenuAction("Filters", .filters, isActive: true, data: nil),
                    createContextMenuAction("Muted", .muted, isActive: true, data: nil),
                    createContextMenuAction("Blocked", .blocked, isActive: true, data: nil),
                    
                    createContextMenuAction("Settings", .settings, isActive: true, data: nil),
                ]
                
                return UIMenu(title: "", options: [.displayInline], children: options)
            } else {
                
                if user.followStatus == .following {
                    
                    let options = [
                        
                        createContextMenuAction("Mention", .mention, isActive: true, data: nil),
                        
                        (user.relationship?.notifying == nil || user.relationship?.notifying == false
                        ? createContextMenuAction("Enable Notifications", .enableNotifications, isActive: true, data: nil)
                        : createContextMenuAction("Disable Notifications", .disableNotifications, isActive: true, data: nil)),
                                                
                        (user.relationship?.showingReblogs == nil || user.relationship?.showingReblogs == false
                        ? createContextMenuAction("Enable Reposts", .enableReposts, isActive: true, data: nil)
                        : createContextMenuAction("Disable Reposts", .disableReposts, isActive: true, data: nil)),
                        
                        UIMenu(title: "Manage Lists", image: MAMenu.list.image.withRenderingMode(.alwaysTemplate), options: [], children: [
                            UIMenu(title: MAMenu.addToList.title, image: MAMenu.addToList.image, options: [], children: ListManager.shared.allLists(includeTopFriends: false).map({
                                createContextMenuAction($0.title, .addToList, isActive: true, data: UserCardButtonCallbackData.list($0.id))
                            })),
                            UIMenu(title: MAMenu.removeFromList.title, image: MAMenu.removeFromList.image, options: [], children: ListManager.shared.allLists(includeTopFriends: false).map({
                                createContextMenuAction($0.title, .removeFromList, isActive: true, data: UserCardButtonCallbackData.list($0.id))
                            })),
                            createContextMenuAction("Create new List", .createNewList, isActive: true, data: nil)
                        ]),
                        
                        (user.isMuted
                         ? createContextMenuAction("Unmute", .unmute, isActive: true, data: nil)
                         : UIMenu(title: "Mute @\(user.username)", image: MAMenu.muteOneDay.image.withRenderingMode(.alwaysTemplate), options: [], children: [
                            createContextMenuAction("Mute 1 Day", .muteOneDay, isActive: true, data: nil),
                            createContextMenuAction("Mute Forever", .muteForever, isActive: true, data: nil)
                        ])),
                        
                        (user.isBlocked
                         ? createContextMenuAction("Unblock", .unblock, isActive: true, data: nil)
                         : createContextMenuAction("Block", .block, isActive: true, data: nil)),
                        
                        createContextMenuAction("Share Link", .share, isActive: true, data: nil)
                    ]
                    
                    return UIMenu(title: "", options: [.displayInline], children: options)
                } else {
                    let options = [
                        createContextMenuAction("Mention", .mention, isActive: true, data: nil),
                        
                        (user.isMuted
                         ? createContextMenuAction("Unmute", .unmute, isActive: true, data: nil)
                         : UIMenu(title: "Mute @\(user.username)", image: MAMenu.muteOneDay.image.withRenderingMode(.alwaysTemplate), options: [], children: [
                            createContextMenuAction("Mute 1 Day", .muteOneDay, isActive: true, data: nil),
                            createContextMenuAction("Mute Forever", .muteForever, isActive: true, data: nil)
                        ])),
                        
                        (user.isBlocked
                         ? createContextMenuAction("Unblock", .unblock, isActive: true, data: nil)
                         : createContextMenuAction("Block", .block, isActive: true, data: nil)),
                        
                        createContextMenuAction("Share Link", .share, isActive: true, data: nil)
                    ]
                    
                    return UIMenu(title: "", options: [.displayInline], children: options)
                }
            }
        }
        
        log.error("[ProfileViewController]: created an empty UIMenu")
        return UIMenu()
    }
    
    private func createContextMenuAction(_ title: String, _ buttonType: UserCardButtonType, isActive: Bool, data: UserCardButtonCallbackData?) -> UIAction {
        var color: UIColor = .black
        if GlobalStruct.overrideTheme == 1 || self.traitCollection.userInterfaceStyle == .light {
            color = .black
        } else if GlobalStruct.overrideTheme == 2 || self.traitCollection.userInterfaceStyle == .dark  {
            color = .white
        }
        
        if buttonType == .block {
            color = UIColor.systemRed
        }
        
        let action = UIAction(title: title,
                              image: buttonType.icon(symbolConfig: postCardSymbolConfig)?.withTintColor(color),
                              identifier: nil, attributes: buttonType == .block ? .destructive : UIMenuElement.Attributes()) { [weak self] _ in
            guard let self else { return }
            self.onButtonPress?(buttonType, data)
        }
        action.accessibilityLabel = title
        return action
    }
}
