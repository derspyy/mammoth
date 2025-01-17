//
//  ProfileHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 13/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ProfileHeader: UIView {
    
    // MARK: - Properties
    private let wrapperStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 13, bottom: 5, trailing: 13)
        return stackView
    }()
    
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 8
        stackView.layer.cornerCurve = .continuous
        stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 35, leading: 0, bottom: 13, trailing: 0)
        return stackView
    }()
    
    private let extraInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 13
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 8
        stackView.layer.cornerCurve = .continuous
        stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 17, leading: 16, bottom: 17, trailing: 16)
        return stackView
    }()
    
    private var extraInfoConstraints: [NSLayoutConstraint]?
    
    private let profilePicBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = PostCardProfilePic.ProfilePicSize.big.cornerRadius()
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let profilePic = PostCardProfilePic(withSize: .big)
    
    private let headerTitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 21
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 4, weight: .bold)
        label.textColor = UIColor.label
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    private let userTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        label.textColor = .custom.softContrast
        label.textAlignment = .center
        return label
    }()
    
    private let descriptionLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .light)
        label.textColor = .custom.mediumContrast
        label.lineSpacing = GlobalStruct.customLineSize
        label.numberOfLines = 0
        label.textAlignment = .center
        label.enabledTypes = [.mention, .hashtag, .url, .email]
        label.mentionColor = .custom.highContrast
        label.hashtagColor = .custom.highContrast
        label.URLColor = .custom.highContrast
        label.emailColor = .custom.highContrast
        label.linkWeight = .semibold
        label.isOpaque = true
        label.urlMaximumLength = 30
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.custom.highContrast, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .semibold)
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.custom.outlines.cgColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        return button
    }()
    
    private let statsStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = 0
        return stackView
    }()
    
    private let followersButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.custom.softContrast, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular)
        button.titleLabel?.textAlignment = .left
        button.contentVerticalAlignment = .top
        return button
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular)
        label.textColor = .custom.softContrast
        label.textAlignment = .left
        return label
    }()
    
    var user: UserCardModel?
    var screenType: ProfileViewModel.ProfileScreenType?
    var onButtonPress: UserCardButtonCallback?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension ProfileHeader {
    func setupUI() {
        self.backgroundColor = .clear
        self.addSubview(wrapperStackView)
        
        wrapperStackView.addArrangedSubview(mainStackView)
        
        self.addSubview(profilePicBackground)
        profilePicBackground.addSubview(profilePic)
        profilePicBackground.backgroundColor = .custom.blurredOVRLYNeut
        
        let blurredBackgroundMain = BlurredBackground()
        mainStackView.addSubview(blurredBackgroundMain)
        blurredBackgroundMain.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            blurredBackgroundMain.topAnchor.constraint(equalTo: mainStackView.topAnchor),
            blurredBackgroundMain.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            blurredBackgroundMain.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            blurredBackgroundMain.bottomAnchor.constraint(equalTo: mainStackView.bottomAnchor),
        ])
        
        let blurredBackgroundExtra = BlurredBackground()
        extraInfoStackView.addSubview(blurredBackgroundExtra)
        blurredBackgroundExtra.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            blurredBackgroundExtra.topAnchor.constraint(equalTo: extraInfoStackView.topAnchor),
            blurredBackgroundExtra.leadingAnchor.constraint(equalTo: extraInfoStackView.leadingAnchor),
            blurredBackgroundExtra.trailingAnchor.constraint(equalTo: extraInfoStackView.trailingAnchor),
            blurredBackgroundExtra.bottomAnchor.constraint(equalTo: extraInfoStackView.bottomAnchor),
        ])
        
        NSLayoutConstraint.activate([
            wrapperStackView.topAnchor.constraint(equalTo: self.topAnchor),
            wrapperStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -wrapperStackView.layoutMargins.bottom),
            wrapperStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: wrapperStackView.layoutMargins.left),
            wrapperStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -wrapperStackView.layoutMargins.right),
            
            mainStackView.topAnchor.constraint(equalTo: wrapperStackView.topAnchor, constant: 82),
            mainStackView.leadingAnchor.constraint(equalTo: wrapperStackView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: wrapperStackView.trailingAnchor),
            
            profilePicBackground.widthAnchor.constraint(equalTo: self.profilePic.widthAnchor, constant: 3 * 2),
            profilePicBackground.heightAnchor.constraint(equalTo: self.profilePic.heightAnchor, constant: 3 * 2),
            profilePicBackground.topAnchor.constraint(equalTo: self.topAnchor),
            profilePicBackground.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            profilePic.centerXAnchor.constraint(equalTo: self.profilePicBackground.centerXAnchor),
            profilePic.centerYAnchor.constraint(equalTo: self.profilePicBackground.centerYAnchor)
        ])
        
        mainStackView.addArrangedSubview(headerTitleStackView)
        headerTitleStackView.addArrangedSubview(nameLabel)
        headerTitleStackView.addArrangedSubview(userTagLabel)
        
        mainStackView.addArrangedSubview(contentStackView)
        contentStackView.addArrangedSubview(actionButton)
        
        contentStackView.addArrangedSubview(statsStack)
        
        statsStack.addArrangedSubview(self.followersButton)
        statsStack.addArrangedSubview(self.statsLabel)
        
        statsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        followersButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            headerTitleStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
        ])
        
        actionButton.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 420, constant: -(contentStackView.layoutMargins.left + contentStackView.layoutMargins.right))
        
        self.profilePic.onPress = self.profilePicTapped
        self.profilePic.isContextMenuEnabled = false
        self.followersButton.addTarget(self, action: #selector(self.onFollowersTapped), for: .touchUpInside)
        
        // When a description starts with a hashtag or mention the formatting is not correct.
        // Defining the attributes again in this custom configurateLinkAttribute callback fixes it.
        self.descriptionLabel.configureLinkAttribute = { (activeType, attributes: [NSAttributedString.Key: Any], _) in
            switch activeType {
            case .url, .mention, .email, .hashtag:
                var newAttributes: [NSAttributedString.Key: Any] = [:]
                newAttributes[.foregroundColor] = UIColor.custom.highContrast
                newAttributes[.underlineStyle] = nil
                newAttributes[.paragraphStyle] = attributes[.paragraphStyle]
                newAttributes[.font] = attributes[.font]
                return newAttributes
            default:
                return attributes
            }
        }
    }
    
    func profilePicTapped(_ type: PostCardButtonType,
                                _ isActive: Bool,
                                _ data: PostCardButtonCallbackData?) -> Void {
        let photo = SKPhoto(url: self.user?.imageURL ?? "")
        let originImage = self.profilePic.profileImageView.image ?? UIImage()
        let browser = SKPhotoBrowser(originImage: originImage, photos: [photo], animatedFromView: self.profilePic.profileImageView, imageText: "", imageText2: 0, imageText3: 0, imageText4: "")
        SKPhotoBrowserOptions.enableSingleTapDismiss = false
        SKPhotoBrowserOptions.displayCounterLabel = false
        SKPhotoBrowserOptions.displayBackAndForwardButton = false
        SKPhotoBrowserOptions.displayAction = false
        SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
        SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
        SKPhotoBrowserOptions.displayCloseButton = false
        SKPhotoBrowserOptions.displayStatusbar = false
        getTopMostViewController()?.present(browser, animated: true, completion: {})
    }
    
    @objc func onFollowingTapped() {
        if let user = self.user {
            self.onButtonPress?(.openFollowing, .user(user))
        }
    }
    
    @objc func onFollowersTapped() {
        if let user = self.user {
            self.onButtonPress?(.openFollowers, .user(user))
        }
    }
}

// MARK: - Configuration
extension ProfileHeader {
    func configure(user: UserCardModel, screenType: ProfileViewModel.ProfileScreenType) {
        // Only re-configure if the user changed
        guard self.user != user else { return }
        
        self.user = user
        self.screenType = screenType
        
        self.profilePic.configure(user: user)
        
        if let name = user.richName {
            self.nameLabel.attributedText = formatRichText(string: name, label: self.nameLabel, emojis: user.emojis)
        } else {
            self.nameLabel.text = user.name
        }
        
        self.userTagLabel.attributedText = self.formatUserTag(user: user)
        
        if let description = user.richDescription {
            self.descriptionLabel.attributedText = formatRichText(string: description, label: self.descriptionLabel, emojis: user.emojis)
        } else {
            self.descriptionLabel.text = user.description
        }

        if let description = user.description, !description.isEmpty {
            if !contentStackView.arrangedSubviews.contains(descriptionLabel) {
                contentStackView.insertArrangedSubview(descriptionLabel, at: 0)
                descriptionLabel.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 420, constant: -(contentStackView.layoutMargins.left + contentStackView.layoutMargins.right))
            }
            
            self.descriptionLabel.mentionColor = .custom.highContrast
            self.descriptionLabel.hashtagColor = .custom.highContrast
            self.descriptionLabel.URLColor = .custom.highContrast
            self.descriptionLabel.emailColor = .custom.highContrast
            self.descriptionLabel.textColor = .custom.highContrast
            
            // Post text link handlers
            self.descriptionLabel.handleURLTap { url in
                self.onButtonPress?(.link, .url(url))
            }
            self.descriptionLabel.handleHashtagTap { hashtag in
                self.onButtonPress?(.link, .hashtag(hashtag))
            }
            self.descriptionLabel.handleMentionTap { mention in
                if let (range, _, _) = self.descriptionLabel.selectedElement {
                    if let url = self.user?.richDescription?.attribute(.link, at: range.location, effectiveRange: nil) as? URL {
                        self.onButtonPress?(.link, .mention("@\(mention)@\(url.host ?? "")"))
                        return
                    }
                }
                
                self.onButtonPress?(.link, .mention(mention))
            }
            self.descriptionLabel.handleEmailTap { email in
                self.onButtonPress?(.link, .email(email))
            }
            
        } else {
            if contentStackView.arrangedSubviews.contains(descriptionLabel) {
                contentStackView.removeArrangedSubview(descriptionLabel)
                descriptionLabel.removeFromSuperview()
                descriptionLabel.constraints.forEach({ $0.isActive = false })
            }
        }
        
        if screenType == .own {
            let buttonLabel = NSMutableAttributedString(string: "Edit Profile")
            let imageAttachment = NSTextAttachment()
            let caretImage = FontAwesome.image(fromChar: "\u{f0d7}", size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .bold).withRenderingMode(.alwaysTemplate)
            imageAttachment.image = caretImage
            imageAttachment.bounds = CGRect(x: 0, y: -3, width: caretImage.size.width, height: caretImage.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            buttonLabel.append(NSAttributedString(string: "  "))
            buttonLabel.append(imageString)
            
            actionButton.setAttributedTitle(buttonLabel, for: .normal)
            actionButton.showsMenuAsPrimaryAction = true
            actionButton.menu = self.createContextMenu()
        } else {
            switch user.followStatus {
            case .unknown:
                fallthrough
            case .inProgress:
                fallthrough
            case .unfollowRequested:
                fallthrough
            case .notFollowing:
                if let followedBy = self.user?.relationship?.followedBy, followedBy {
                    actionButton.setTitle("Follow back", for: .normal)
                } else {
                    actionButton.setTitle("Follow", for: .normal)
                }
                actionButton.removeTarget(self, action: #selector(self.unfollowTapped), for: .touchUpInside)
                actionButton.addTarget(self, action: #selector(self.followTapped), for: .touchUpInside)
                break
            case .followRequested:
                fallthrough
            case .following:
                actionButton.setTitle("Unfollow", for: .normal)
                actionButton.removeTarget(self, action: #selector(self.followTapped), for: .touchUpInside)
                actionButton.addTarget(self, action: #selector(self.unfollowTapped), for: .touchUpInside)
                break
            case .followAwaitingApproval:
                actionButton.setTitle("Awaiting approval", for: .normal)
                actionButton.removeTarget(self, action: #selector(self.followTapped), for: .touchUpInside)
                actionButton.addTarget(self, action: #selector(self.unfollowTapped), for: .touchUpInside)
                break
            case .none:
                actionButton.setTitle("Follow", for: .normal)
                actionButton.removeTarget(self, action: #selector(self.unfollowTapped), for: .touchUpInside)
                actionButton.addTarget(self, action: #selector(self.followTapped), for: .touchUpInside)
            }
        }
        
        self.statsLabel.text = " - Joined \(user.joinedOn?.toString(dateStyle: .short, timeStyle: .none) ?? "")"
        if user.followersCount == "1" {
            self.followersButton.setTitle("\(user.followersCount) follower", for: .normal)
        } else {
            self.followersButton.setTitle("\(user.followersCount) followers", for: .normal)
        }
        
        // Clear all fields
        if let infoConstraints = self.extraInfoConstraints {
            extraInfoStackView.arrangedSubviews.forEach({
                extraInfoStackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            })
            
            wrapperStackView.removeArrangedSubview(extraInfoStackView)
            extraInfoStackView.removeFromSuperview()
            NSLayoutConstraint.deactivate(infoConstraints)
        }
        
        // Set all fields
        if let fields = user.fields, !fields.isEmpty {
            wrapperStackView.addArrangedSubview(extraInfoStackView)
            
            extraInfoConstraints = [
                extraInfoStackView.trailingAnchor.constraint(equalTo: wrapperStackView.trailingAnchor)
            ]
            
            NSLayoutConstraint.activate(extraInfoConstraints!)
            
            fields.enumerated().forEach({ index, data in
                let field = ProfileField(field: data)
                field.onButtonPress = self.onButtonPress
                field.translatesAutoresizingMaskIntoConstraints = false
                extraInfoStackView.addArrangedSubview(field)
                
                extraInfoConstraints?.append(field.leadingAnchor.constraint(equalTo: extraInfoStackView.leadingAnchor, constant: 16))
                extraInfoConstraints?.append(field.trailingAnchor.constraint(equalTo: extraInfoStackView.trailingAnchor, constant: -16))
                                
                if index < fields.count - 1 {
                    let seperator = ProfileFieldSeperator()
                    seperator.translatesAutoresizingMaskIntoConstraints = false
                    extraInfoStackView.addArrangedSubview(seperator)
                    extraInfoConstraints?.append(seperator.leadingAnchor.constraint(equalTo: extraInfoStackView.leadingAnchor, constant: 16))
                    extraInfoConstraints?.append(seperator.trailingAnchor.constraint(equalTo: extraInfoStackView.trailingAnchor, constant: -16))
                    extraInfoConstraints?.append(seperator.heightAnchor.constraint(equalToConstant: 1))
                }
            })
            
            NSLayoutConstraint.activate(extraInfoConstraints!)
        }
        
        self.onThemeChange()
    }
    
    func optimisticUpdate(image: UIImage) {
        self.profilePic.optimisticUpdate(image: image)
    }
    
    func onThemeChange() {
        profilePicBackground.backgroundColor = .custom.blurredOVRLYNeut
        self.profilePicBackground.layer.cornerRadius = PostCardProfilePic.ProfilePicSize.big.cornerRadius()
        self.profilePic.onThemeChange()
        
        if let user = self.user {
            self.userTagLabel.attributedText = self.formatUserTag(user: user)
        }
        
        self.descriptionLabel.mentionColor = .custom.highContrast
        self.descriptionLabel.hashtagColor = .custom.highContrast
        self.descriptionLabel.URLColor = .custom.highContrast
        self.descriptionLabel.emailColor = .custom.highContrast
        
        self.nameLabel.textColor = .custom.highContrast
        self.userTagLabel.textColor = .custom.softContrast
        
        self.actionButton.layer.borderColor = UIColor.custom.outlines.cgColor
        
        if let screenType = self.screenType, screenType == .own {
            let buttonLabel = NSMutableAttributedString(string: "Edit Profile")
            let imageAttachment = NSTextAttachment()
            let caretImage = FontAwesome.image(fromChar: "\u{f0d7}", size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .bold).withRenderingMode(.alwaysTemplate)
            imageAttachment.image = caretImage
            imageAttachment.bounds = CGRect(x: 0, y: -3, width: caretImage.size.width, height: caretImage.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            buttonLabel.append(NSAttributedString(string: "  "))
            buttonLabel.append(imageString)
            
            actionButton.setAttributedTitle(buttonLabel, for: .normal)
        }
        
        self.extraInfoStackView.arrangedSubviews.forEach { view in
            if let field = view as? ProfileField {
                field.onThemeChange()
            }
        }
        
        if screenType == .own {
            self.actionButton.menu = self.createContextMenu()
        }
    }
    
    @objc func followTapped() {
        actionButton.setTitle("Unfollow", for: .normal)
        triggerHapticImpact(style: .light)
        
        if  let userCard = self.user, let account = userCard.account {
            Task {
                do {
                    let _ = try await FollowManager.shared.followAccountAsync(account)

                    DispatchQueue.main.async {
                        self.user?.syncFollowStatus()
                    }
                    
                    if userCard.followStatus != .followRequested {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadTableSuggestions"), object: nil)
                        }
                    }
                } catch let error {
                    log.error("Follow error: \(error)")
                }
            }
        }
    }
    
    @objc func unfollowTapped() {
        actionButton.setTitle("Follow", for: .normal)
        triggerHapticImpact(style: .light)
        
        if let userCard = self.user, let account = userCard.account {
            Task {
                do {
                    let _ = try await FollowManager.shared.unfollowAccountAsync(account)
                    
                    DispatchQueue.main.async {
                        self.user?.syncFollowStatus()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadTableSuggestions"), object: nil)
                    }
                } catch let error {
                    log.error("Unfollow error: \(error)")
                }
            }
        }
    }
    
    func formatUserTag(user: UserCardModel) -> NSAttributedString {
        let userTag = NSMutableAttributedString(string: "")
  
        if user.isLocked {
            let imageAttachment = NSTextAttachment()
            let lockImage = FontAwesome.image(fromChar: "\u{f023}", color: UIColor.custom.softContrast, size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2)
            imageAttachment.image = lockImage
            imageAttachment.bounds = CGRect(x: 0, y: -2, width: lockImage.size.width, height: lockImage.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            userTag.append(imageString)
            userTag.append(NSAttributedString(string: " "))
        }
        
        if user.isBot {
            let imageAttachment = NSTextAttachment()
            let botImage = FontAwesome.image(fromChar: "\u{f544}", color: UIColor.custom.softContrast, size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2)
            imageAttachment.image = botImage
            imageAttachment.bounds = CGRect(x: 0, y: -2, width: botImage.size.width, height: botImage.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            userTag.append(imageString)
            userTag.append(NSAttributedString(string: " "))
        }
        
        userTag.append(NSAttributedString(string: user.userTag))
        
        return userTag
    }
}

// MARK: Appearance changes
internal extension ProfileHeader {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
         self.onThemeChange()
    }
}

// MARK: - Context menu creators
extension ProfileHeader {
    func createContextMenu() -> UIMenu {                
        let options = [
            createContextMenuAction("Edit Avatar", .editAvatar),
            createContextMenuAction("Edit Header", .editHeader),
            createContextMenuAction("Edit Details", .editDetails),
            createContextMenuAction("Edit Info and Links", .editInfoAndLink),
        ]
        
        return UIMenu(title: "Edit Profile", options: [.displayInline], children: options)
    }

    private func createContextMenuAction(_ title: String, _ buttonType: UserCardButtonType) -> UIAction {
        var color: UIColor = .black
        if GlobalStruct.overrideTheme == 1 || self.traitCollection.userInterfaceStyle == .light {
            color = .black
        } else if GlobalStruct.overrideTheme == 2 || self.traitCollection.userInterfaceStyle == .dark  {
            color = .white
        }
        
        let action = UIAction(title: title,
                              image: buttonType.icon(symbolConfig: userCardSymbolConfig)?.withTintColor(color),
                              identifier: nil) { [weak self] _ in
            guard let self else { return }
            if let user = self.user {
                self.onButtonPress?(buttonType, .user(user))
            }
        }
        action.accessibilityLabel = title
        return action
    }
}

// MARK: - Profile field
final class ProfileField: UIStackView {
    
    private let valueStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular)
        label.textColor = .custom.feintContrast
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    private let verifiedImage = UIImageView(image: FontAwesome.image(fromChar: "\u{e416}", size: 15, weight: .bold).withConfiguration(userCardSymbolConfig).withTintColor(.custom.mediumContrast, renderingMode: .alwaysTemplate))
        
    private let descriptionLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular)
        label.textColor = .custom.mediumContrast
        label.textAlignment = .left
        label.numberOfLines = 0
        label.enabledTypes = [.mention, .hashtag, .url, .email]
        label.urlMaximumLength = 120
        label.mentionColor = .custom.mediumContrast
        label.hashtagColor = .custom.mediumContrast
        label.URLColor = .custom.mediumContrast
        label.emailColor = .custom.mediumContrast
        label.linkWeight = .regular
        label.isOpaque = true
        return label
    }()
    
    var onButtonPress: UserCardButtonCallback?
    
    init(field: HashType) {
        super.init(frame: .zero)
        setupUI()
        
        titleLabel.text = field.name
        
        if let verifiedAt = field.verifiedAt, !verifiedAt.isEmpty {
            valueStack.insertArrangedSubview(verifiedImage, at: 0)
            verifiedImage.tintColor = .custom.mediumContrast
            verifiedImage.contentMode = .scaleAspectFit
            verifiedImage.transform = CGAffineTransform(translationX: 0, y: 4)
            verifiedImage.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
            verifiedImage.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        }
        
        if let description = parseRichText(text: field.value.stripHTML()) {
            descriptionLabel.attributedText = formatRichText(string: description, label: descriptionLabel, emojis: nil)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI()  {
        self.axis = .vertical
        self.alignment = .top
        self.distribution = .fill
        self.spacing = 4
        self.backgroundColor = .clear
        
        self.addArrangedSubview(titleLabel)
        self.addArrangedSubview(valueStack)
        
        valueStack.addArrangedSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            valueStack.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
        ])
        
        descriptionLabel.handleURLTap { url in
            self.onButtonPress?(.link, .url(url))
        }
        descriptionLabel.handleHashtagTap { hashtag in
            self.onButtonPress?(.link, .hashtag(hashtag))
        }
        descriptionLabel.handleMentionTap { mention in
            self.onButtonPress?(.link, .mention(mention))
        }
        descriptionLabel.handleEmailTap { email in
            self.onButtonPress?(.link, .email(email))
        }
    }
    
    func onThemeChange() {
        self.titleLabel.textColor = .custom.feintContrast
        self.descriptionLabel.mentionColor = .custom.mediumContrast
        self.descriptionLabel.hashtagColor = .custom.mediumContrast
        self.descriptionLabel.URLColor = .custom.mediumContrast
        self.descriptionLabel.emailColor = .custom.mediumContrast
    }
}

final class ProfileFieldSeperator: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.label.withAlphaComponent(0.1)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


