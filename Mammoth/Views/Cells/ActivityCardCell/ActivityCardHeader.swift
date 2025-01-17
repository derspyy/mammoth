//
//  ActivityCardHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 01/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ActivityCardHeader: UIView {
    
    // MARK: - Properties
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
        
    private let headerTitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let rightAttributesStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.label
        label.numberOfLines = 1
        return label
    }()
    
    private let pinIcon: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let config = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .light)
        let icon = UIImage(systemName: "pin.fill", withConfiguration: config)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        imageView.contentMode = .right
        imageView.image = icon
        return imageView
    }()

    private let actionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.custom.feintContrast
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.custom.feintContrast
        return label
    }()
    
    private var activity: ActivityCardModel?
    public var onPress: PostCardButtonCallback?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.activity = nil
        self.onPress = nil
        self.titleLabel.text = nil
        self.actionLabel.text = nil
        self.dateLabel.text = nil
        
        if self.rightAttributesStack.contains(self.pinIcon) {
            self.rightAttributesStack.removeArrangedSubview(self.pinIcon)
            self.pinIcon.removeFromSuperview()
        }
        setupUIFromSettings()
    }
}


// MARK: - Setup UI
private extension ActivityCardHeader {
    func setupUI() {
        self.isOpaque = true
        self.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        mainStackView.addArrangedSubview(headerTitleStackView)
        mainStackView.addArrangedSubview(rightAttributesStack)
        
        rightAttributesStack.addArrangedSubview(dateLabel)
        
        // Don't compress but let siblings fill the space
        titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        
        // Don't compress but let siblings fill the space
        dateLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 752), for: .horizontal)
        
        headerTitleStackView.addArrangedSubview(titleLabel)
        headerTitleStackView.addArrangedSubview(actionLabel)
        
        setupUIFromSettings()
    }
    
    func setupUIFromSettings() {
        actionLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        dateLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
    }

}

// MARK: - Configuration
extension ActivityCardHeader {
    func configure(activity: ActivityCardModel) {
        self.activity = activity

        if let name = activity.user.richName {
            self.titleLabel.attributedText = formatRichText(string: name, label: self.titleLabel, emojis:activity.user.emojis)
        } else {
            self.titleLabel.text = activity.user.name
        }
        
        self.actionLabel.text = self.mapTypeToAction(activity: activity)
        self.dateLabel.text = activity.time
    }
    
   private func mapTypeToAction(activity: ActivityCardModel) -> String {
        switch activity.type {
        case .favourite:
            return "liked"
        case .follow:
            return "followed you"
        case .follow_request:
            return "follow request"
        case .poll:
            return "poll ended"
        case .reblog:
            return "reposted"
        case .status:
            return "posted"
        case .update:
            return "updated"
        case .direct:
            return "mentioned you"
        case .mention:
            if let postCard = activity.postCard, postCard.isPrivateMention {
                return "mentioned you"
            }
            return "mentioned you"
        }
    }
    
    func onThemeChange() {}
}

// MARK: - Handlers
extension ActivityCardHeader {
    @objc func profileTapped() {
        self.onPress?(.profile, true, nil)
    }
}
