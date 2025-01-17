//
//  DiscoveryViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class DiscoveryViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(UserCardCell.self, forCellReuseIdentifier: UserCardCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        return tableView
    }()

    // searchBar for the iPad aux column
    private lazy var searchBar: UISearchBar = {
        let searchBar: UISearchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()

    // searchController for everything *except* the iPad aux column
    private lazy var searchController: UISearchController = {
        return UISearchController(searchResultsController: nil)
    }()

    
    private lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        return loader;
    }()

    private var viewModel: DiscoveryViewModel
    private var throttledDecelarationEndTask: Task<Void, Error>?

    required init(viewModel: DiscoveryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.title = "Users"
        self.navigationItem.title = "Users"

        if viewModel.position != .aux {
            self.searchController.delegate = self
            self.searchController.searchBar.delegate = self
            self.searchController.searchResultsUpdater = self
            self.searchController.navigationItem.hidesSearchBarWhenScrolling = false
            self.searchController.obscuresBackgroundDuringPresentation = false
            self.searchController.hidesNavigationBarDuringPresentation = false
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onThemeChange),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if viewModel.position == .aux {
            searchBar.resignFirstResponder()
        }
        
        self.throttledDecelarationEndTask?.cancel()
    }
    
    @objc private func onThemeChange() {
        self.tableView.reloadData()
    }
}

// MARK: UI Setup
private extension DiscoveryViewController {
    func setupUI() {
        view.addSubview(tableView)
        view.addSubview(loader)
        
        if viewModel.position == .aux {
            view.addSubview(searchBar)
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                searchBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                searchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([
            (viewModel.position == .aux
            ? self.tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor)
            : self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor)),
            
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            self.loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        
    }
    
    func showSearchFieldLoader() {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        if viewModel.position == .aux {
            self.searchBar.searchTextField.leftView = loader
        }
    }
    
    func hideSearchFieldLoader()  {
        if viewModel.position == .aux {
            self.searchBar.searchTextField.leftView = UISearchBar().searchTextField.leftView
        }
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate
extension DiscoveryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(forSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.hasHeader(forSection: section) {
            return 29
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let userCard = viewModel.getInfo(forIndexPath: indexPath)
        let cell = self.tableView.dequeueReusableCell(withIdentifier: UserCardCell.reuseIdentifier, for: indexPath) as! UserCardCell
        cell.configure(info: userCard, actionButtonType: .none) {  [weak self] (type, isActive, data) in
            guard let self else { return }
            PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: userCard, data: data)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.hasHeader(forSection: section) {
            let header = SectionHeader(buttonTitle: nil)
            header.configure(labelText: viewModel.getSectionTitle(for: section))
            return header
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userCard = viewModel.getInfo(forIndexPath: indexPath)
        let vc = ProfileViewController(user: userCard, screenType: userCard.isSelf ? .own : .others)
        if vc.isBeingPresented {} else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let task = self.throttledDecelarationEndTask, !task.isCancelled {
            self.throttledDecelarationEndTask?.cancel()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.viewModel.shouldSyncFollowStatus() {
            self.throttledDecelarationEndTask = Task { [weak self] in
                guard let self else { return }
                try await Task.sleep(seconds: 1.2)
                if !Task.isCancelled {
                    if let indexPaths = self.tableView.indexPathsForVisibleRows {
                        self.viewModel.syncFollowStatus(forIndexPaths: indexPaths)
                    }
                }
            }
        }
    }
}

// MARK: UISearchControllerDelegate
extension DiscoveryViewController: UISearchControllerDelegate {    
}

// MARK: UISearchResultsUpdating
extension DiscoveryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
    }
}


// MARK: UISearchBarDelegate
extension DiscoveryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(query: searchText, fullSearch: false)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.cancelSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let query = searchBar.text {
            viewModel.search(query: query, fullSearch: true)
        }
    }
}

// MARK: RequestDelegate
extension DiscoveryViewController: RequestDelegate {
    func didUpdate(with state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                self.showSearchFieldLoader()
                if self.viewModel.numberOfItems(forSection: 0) == 0 {
                    self.loader.isHidden = false
                    self.loader.startAnimating()
                }
                break
            case .success:
                self.hideSearchFieldLoader()
                self.loader.stopAnimating()
                self.loader.isHidden = true
                self.tableView.reloadData()
                break
            case .error(let error):
                self.hideSearchFieldLoader()
                self.loader.stopAnimating()
                self.loader.isHidden = true
                log.error("Error on DiscoveryViewController didUpdate: \(state) - \(error)")
                break
            }
        }
    }
    
    func didUpdateCard(at indexPath: IndexPath) {
        if self.tableView.cellForRow(at: indexPath) != nil {
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    func didDeleteCard(at indexPath: IndexPath) {
        self.tableView.deleteRows(at: [indexPath], with: .bottom)
    }
}

extension DiscoveryViewController: JumpToNewest {
    @objc func jumpToNewest() {
        self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
