//
//  FeedEditorViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class FeedEditorViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(FeedEditorCell.self, forCellReuseIdentifier: FeedEditorCell.reuseIdentifier)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        tableView.register(EmptyFeedCell.self, forCellReuseIdentifier: EmptyFeedCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.dragDelegate = self
        tableView.backgroundColor = .custom.background
        tableView.separatorStyle = .none
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delaysContentTouches = false
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        return tableView
    }()
    
    private var viewModel: FeedEditorViewModel
    
    required init(viewModel: FeedEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.backButtonTitle = nil
        
        self.setupUI()
    }
    
    convenience init() {
        let viewModel = FeedEditorViewModel()
        self.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshList),
                                               name: didChangeFeedTypeItemsNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
        
        if self.isModal {
            if #available(iOS 16.0, *) {
                let closeBtn = UIBarButtonItem(title: "Done", image: nil, target: self, action: #selector(self.onClosePressed))
                closeBtn.setTitleTextAttributes([
                    NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18, weight: .semibold)],
                                                for: .normal)
                closeBtn.setTitleTextAttributes([
                    NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18, weight: .semibold)],
                                                for: .highlighted)
                self.navigationItem.setRightBarButton(closeBtn, animated: false)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        FeedsManager.shared.consolidate()
        ListManager.shared.fetchLists()
        HashtagManager.shared.fetchFollowingTags()
    }
    
    @objc func onClosePressed() {
        self.dismiss(animated: true)
    }
    
    @objc func refreshList() {
        self.tableView.reloadData()
    }
    
    func setupUI() {
        self.view.addSubview(self.tableView)
        
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
    }
}

extension FeedEditorViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(forSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let feedTypeItem = self.viewModel.getInfo(forIndexPath: indexPath),
            let cell = self.tableView.dequeueReusableCell(withIdentifier: FeedEditorCell.reuseIdentifier, for: indexPath) as? FeedEditorCell {
            cell.configure(feedTypeItem: feedTypeItem) { item, action in
                triggerHapticImpact(style: .light)
                
                switch action {
                case .enable:
                    FeedsManager.shared.enable(item)
                    self.tableView.reloadData()
                case .disable:
                    FeedsManager.shared.disable(item)
                    self.tableView.reloadData()
                case .delete:
                    switch item.type {
                    case .hashtag(let tag):
                        let alert = UIAlertController(title: "Unfollow hashtag", message: "This hashtag is already hidden, would you like to unfollow it entirely?", preferredStyle: .alert)
                        alert.view.tintColor = .custom.highContrast
                        alert.addAction(UIAlertAction(title: "Unfollow", style: .destructive , handler: { (UIAlertAction) in
                            HashtagManager.shared.unfollowHashtag(tag.name.lowercased(), completion: { _ in })
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: { (UIAlertAction) in
                        }))
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                        
                    case .channel(let channel):
                        let alert = UIAlertController(title: "Unsubscribe from smart list", message: "This smart list is already hidden, would you like to unsubscribe from it entirely?", preferredStyle: .alert)
                        alert.view.tintColor = .custom.highContrast
                        alert.addAction(UIAlertAction(title: "Unsubscribe", style: .destructive , handler: { (UIAlertAction) in
                            ChannelManager.shared.unsubscribeFromChannel(channel)
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: { (UIAlertAction) in
                        }))
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                        
                    case .list(let list):
                        let alert = UIAlertController(title: "Delete list", message: "Are you sure you want to permanently delete this list?", preferredStyle: .alert)
                        alert.view.tintColor = .custom.highContrast
                        alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler: { (UIAlertAction) in
                            ListManager.shared.deleteList(list.id) { success in
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                                }
                            }
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: { (UIAlertAction) in
                        }))
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                        
                    case .community(let instanceName):
                        let alert = UIAlertController(title: "Unsubscribe from instance", message: "This instance is already hidden, would you like to unsubscribe from it entirely?", preferredStyle: .alert)
                        alert.view.tintColor = .custom.highContrast
                        alert.addAction(UIAlertAction(title: "Unsubscribe", style: .destructive , handler: { (UIAlertAction) in
                            InstanceManager.shared.unpinInstance(instanceName)
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: { (UIAlertAction) in
                        }))
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                        
                    default:
                        break
                    }
                }
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 25
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            // Return a UIView here to create a spacing between the two sections.
            // tableView:heightForHeaderInSection returns the height of the header
            return UIView(frame: .zero)
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if let feedTypeItem = self.viewModel.getInfo(forIndexPath: indexPath) {
            return feedTypeItem.isDraggable
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if let feedTypeItem = self.viewModel.getInfo(forIndexPath: proposedDestinationIndexPath) {
            let canMoveHere = feedTypeItem.isDraggable
            return canMoveHere ? proposedDestinationIndexPath : sourceIndexPath
        }
        
        return sourceIndexPath
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        if let feedTypeItem = self.viewModel.getInfo(forIndexPath: indexPath) {
            guard feedTypeItem.isDraggable else { return [] }
            dragItem.localObject = feedTypeItem
        }
        
        return [ dragItem ]
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.viewModel.moveItem(fromIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }
}

// MARK: Appearance changes
internal extension FeedEditorViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if (traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)) {
                 configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
             }
         }
    }
}

