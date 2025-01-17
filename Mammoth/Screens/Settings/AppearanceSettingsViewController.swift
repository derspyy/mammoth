//
//  AppearanceSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 21/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class AppearanceSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIColorPickerViewControllerDelegate {

    var tableView = UITableView()
    let btn0 = UIButton(type: .custom)
    
    let firstSection = ["Text Size"]
    let sampleStatus = {
        let currentUserAccount = AccountsManager.shared.currentUser()!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let fiveMinsAgo = formatter.string(from: Date().addingTimeInterval(-(5*60)))
        let status = Status(id: "",
                            uri: "",
                            account: currentUserAccount,
                            content: "Example post preview showing what these changes will look like on your feed. 🦣",
                            createdAt: fiveMinsAgo,
                            emojis: [],
                            repliesCount: 20,
                            reblogsCount: 3,
                            favouritesCount: 8000,
                            spoilerText: "",
                            visibility: .public,
                            mediaAttachments: [],
                            mentions: [],
                            tags: [])
        return status
    }()

    override func viewDidLayoutSubviews() {
        self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        self.navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
    }

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }

    @objc func reloadAll() {
        // tints
        let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
        if hcText == true {
            UIColor.custom.mainTextColor = .label
        } else {
            UIColor.custom.mainTextColor = .secondaryLabel
        }

        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }

        // update various elements
        self.view.backgroundColor = .custom.backgroundTint
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        self.navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        GlobalStruct.inOverlayedScreen = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GlobalStruct.inOverlayedScreen = true
    }

    @objc func reloadBars() {
        DispatchQueue.main.async {
            if GlobalStruct.hideNavBars2 {
                self.extendedLayoutIncludesOpaqueBars = true
            } else {
                self.extendedLayoutIncludesOpaqueBars = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.backgroundTint
        self.title = "Appearance"

        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)

        // nav bar
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        self.navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }

        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
        if #available(iOS 15.0, *) {
            self.tableView.allowsFocus = true
        }
        
        self.tableView = UITableView(frame: .zero, style: .insetGrouped)
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(TextSizeCell.self, forCellReuseIdentifier: "TextSizeCell")
        self.tableView.register(PostCardCell.self, forCellReuseIdentifier: "PostCardCell")
        self.tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.layer.masksToBounds = true
        self.tableView.showsVerticalScrollIndicator = false
        self.view.addSubview(self.tableView)
        self.tableView.reloadData()

        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn0.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
        btn0.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn0.layer.cornerRadius = 14
        btn0.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn0.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn0.addTarget(self, action: #selector(self.dismissTap), for: .touchUpInside)
        btn0.accessibilityLabel = "Dismiss"
    }

    // MARK: TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1    // sample cell
        case 1: return 2    // text size + slider
        case 2: return 8    // remaining options
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // sample post cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCardCell", for: indexPath) as! PostCardCell
            let postCard = PostCardModel(status: sampleStatus)
            cell.configure(postCard: postCard) {type,isActive,data in
                // Do nothing
            }
            cell.layer.borderColor = UIColor.custom.outlines.cgColor
            cell.layer.borderWidth = 0.5
            cell.isUserInteractionEnabled = false // ignore tapping on the sample post
            return cell

        case 1: // text size + slider cell
            switch indexPath.row {
            case 0:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCell.value1")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = FontAwesome.image(fromChar: "\u{f894}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)

                cell.textLabel?.text = self.firstSection[indexPath.row]
                
                if GlobalStruct.customTextSize == 0 {
                    cell.detailTextLabel?.text = "\("System")"
                } else if GlobalStruct.customTextSize > 0 {
                    cell.detailTextLabel?.text = "\("System") \("+\(Int(GlobalStruct.customTextSize))")"
                } else {
                    cell.detailTextLabel?.text = "\("System") \(Int(GlobalStruct.customTextSize))"
                }
                
                cell.backgroundColor = .custom.OVRLYSoftContrast
                cell.selectionStyle = .none
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextSizeCell", for: indexPath) as! TextSizeCell
                cell.textLabel?.numberOfLines = 0
                cell.configureSize(self.view.bounds.width)
                cell.slider.setValue(Float(GlobalStruct.customTextSize), animated: false)
                cell.slider.addTarget(self, action: #selector(self.valueChanged(_:)), for: .valueChanged)
                cell.backgroundColor = .custom.OVRLYSoftContrast
                cell.selectionStyle = .none
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
                
            default: return UITableViewCell()
            }
            
        case 2: // remaining cells
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
                cell.txtLabel.text = "Theme"
                cell.imageV.image = FontAwesome.image(fromChar: "\u{f1fc}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                switch GlobalStruct.overrideTheme {
                case 1:
                    cell.txtLabel2.text = "Light"
                case 2:
                    cell.txtLabel2.text = "Dark"
                default:
                    cell.txtLabel2.text = "System"
                }

                var gestureActions: [UIAction] = []
                let op1 = UIAction(title: "System", image: FontAwesome.image(fromChar: "\u{f042}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal), identifier: nil) { action in
                    GlobalStruct.overrideTheme = 0
                    UserDefaults.standard.set(0, forKey: "overrideTheme")
                    FontAwesome.setColorTheme(theme: ColorTheme.systemDefault)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "overrideTheme"), object: nil)
                    self.tableView.reloadRows(at: [indexPath], with: .none)

                }
                if GlobalStruct.overrideTheme == 0 {
                    op1.state = .on
                }
                gestureActions.append(op1)
                let op2 = UIAction(title: "Light", image: FontAwesome.image(fromChar: "\u{e0c9}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal), identifier: nil) { action in
                    GlobalStruct.overrideTheme = 1
                    UserDefaults.standard.set(1, forKey: "overrideTheme")
                    FontAwesome.setColorTheme(theme: ColorTheme.light)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "overrideTheme"), object: nil)
                    self.tableView.reloadRows(at: [indexPath], with: .none)

                }
                if GlobalStruct.overrideTheme == 1 {
                    op2.state = .on
                }
                gestureActions.append(op2)
                let op3 = UIAction(title: "Dark", image: FontAwesome.image(fromChar: "\u{f186}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal), identifier: nil) { action in
                    GlobalStruct.overrideTheme = 2
                    UserDefaults.standard.set(2, forKey: "overrideTheme")
                    FontAwesome.setColorTheme(theme: ColorTheme.dark)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "overrideTheme"), object: nil)
                    self.tableView.reloadRows(at: [indexPath], with: .none)

                }
                if GlobalStruct.overrideTheme == 2 {
                    op3.state = .on
                }
                gestureActions.append(op3)
                cell.bgButton.showsMenuAsPrimaryAction = true
                cell.bgButton.menu = UIMenu(title: "", image: UIImage(systemName: "sun.max"), options: [.displayInline], children: gestureActions)
                cell.accessoryView = .none
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                cell.bgButton.backgroundColor = .clear
                return cell

            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
                cell.txtLabel.text = "Names"
                cell.accessibilityLabel = "Names"
                
                cell.imageV.image = FontAwesome.image(fromChar: "\u{f5b7}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                if GlobalStruct.displayName == .full {
                    cell.txtLabel2.text = "Full"
                } else if GlobalStruct.displayName == .usernameOnly {
                    cell.txtLabel2.text = "Username"
                } else if GlobalStruct.displayName == .usertagOnly {
                    cell.txtLabel2.text = "Usertag"
                } else {
                    cell.txtLabel2.text = "None" // .none
                }
                
                var gestureActions: [UIAction] = []
                let image1 = FontAwesome.image(fromChar: "\u{f47f}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                let op1 = UIAction(title: "Full", image: image1, identifier: nil) { action in
                    
                    GlobalStruct.displayName = .full
                    UserDefaults.standard.set(GlobalStruct.displayName.rawValue, forKey: "displayName")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
                if GlobalStruct.displayName == .full {
                    op1.state = .on
                }
                
                gestureActions.append(op1)
                let image2 = FontAwesome.image(fromChar: "\u{f007}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                let op2 = UIAction(title: "Username", image: image2, identifier: nil) { action in
                    
                    GlobalStruct.displayName = .usernameOnly
                    UserDefaults.standard.set(GlobalStruct.displayName.rawValue, forKey: "displayName")
                
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
                if GlobalStruct.displayName == .usernameOnly {
                    op2.state = .on
                }
                
                gestureActions.append(op2)
                let image3 = FontAwesome.image(fromChar: "\u{40}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                let op3 = UIAction(title: "Usertag", image: image3, identifier: nil) { action in
                    
                    GlobalStruct.displayName = .usertagOnly
                    UserDefaults.standard.set(GlobalStruct.displayName.rawValue, forKey: "displayName")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
                if GlobalStruct.displayName == .usertagOnly {
                    op3.state = .on
                }
                
                gestureActions.append(op3)
                let image4 = FontAwesome.image(fromChar: "\u{f656}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                let op4 = UIAction(title: "None", image: image4, identifier: nil) { action in
                    
                    GlobalStruct.displayName = .none
                    UserDefaults.standard.set(GlobalStruct.displayName.rawValue, forKey: "displayName")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
                if GlobalStruct.displayName == .none {
                    op4.state = .on
                }
                
                gestureActions.append(op4)
                cell.bgButton.showsMenuAsPrimaryAction = true
                cell.bgButton.menu = UIMenu(title: "", image: UIImage(systemName: "person.crop.square.fill.and.at.rectangle"), options: [.displayInline], children: gestureActions)
                cell.accessoryView = .none
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                cell.bgButton.backgroundColor = .clear
                return cell

            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
                cell.txtLabel.text = "Maximum lines"
                cell.accessibilityLabel = "Maximum lines"
                
                cell.imageV.image = FontAwesome.image(fromChar: "\u{f7a4}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                if GlobalStruct.maxLines == 0 {
                    cell.txtLabel2.text = "None"
                } else {
                    cell.txtLabel2.text = "\(GlobalStruct.maxLines)"
                }
                
                var gestureActions: [UIAction] = []
                let actionValues = [0, 2, 4, 6, 8, 10]
                for actionValue in actionValues {
                    let title = (actionValue==0) ? "None" : "\(actionValue)"
                    let op1 = UIAction(title: title, image: nil, identifier: nil) { action in
                        GlobalStruct.maxLines = actionValue
                        UserDefaults.standard.set(GlobalStruct.maxLines, forKey: "maxLines")
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                    }
                    if GlobalStruct.maxLines == actionValue {
                        op1.state = .on
                    }
                    gestureActions.append(op1)
                }
                cell.bgButton.showsMenuAsPrimaryAction = true
                cell.bgButton.menu = UIMenu(title: "", image: UIImage(systemName: "person.crop.square.fill.and.at.rectangle"), options: [.displayInline], children: gestureActions)
                cell.accessoryView = .none
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                cell.bgButton.backgroundColor = .clear
                return cell
                
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = "Circle profile icons"
                cell.imageView?.image = FontAwesome.image(fromChar: "\u{f2bd}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)

                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "circleProfiles") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "circleProfiles") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                
                switchView.onTintColor = .custom.gold
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchCircleProfiles(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell

            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = "Content warning overlays"
                cell.imageView?.image = FontAwesome.image(fromChar: "\u{f05e}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "showCW") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "showCW") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchShowCW(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell

            case 5:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = "Blur sensitive content"
                cell.imageView?.image = FontAwesome.image(fromChar: "\u{f071}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "blurSensitiveContent") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "blurSensitiveContent") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: true)
                }
                switchView.onTintColor = .custom.gold
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchBlurSensitiveContent(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell

            case 6:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = "Auto-play videos & GIFs"
                cell.imageView?.image = FontAwesome.image(fromChar: "\u{f04b}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "autoPlayVideos") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "autoPlayVideos") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: true)
                }
                switchView.onTintColor = .custom.gold
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchAutoPlayingVideos(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
                
            case 7:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.text = "Translation language"
                cell.imageView?.image = UIImage(systemName: "globe")
                cell.imageView?.image = FontAwesome.image(fromChar: "\u{f0ac}").withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
                                
            default: return UITableViewCell()
            }
            
        default: return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 2:
            switch indexPath.row {
            case 7:
                let vc = TranslationSettingsViewController()
                navigationController?.pushViewController(vc, animated: true)
            default:
                break
            }
        default:
            break
        }
    }

    @objc func valueChanged(_ sender: UISlider) {
        let step: Float = 1
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue

        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) {
            if sender.value == 0 {
                cell.detailTextLabel?.text = "\("System Size")"
            } else if sender.value < 0 {
                cell.detailTextLabel?.text = "\("System Size") \(Int(sender.value))"
            } else {
                cell.detailTextLabel?.text = "\("System Size") \("+\(Int(sender.value))")"
            }
        }

        GlobalStruct.customTextSize = CGFloat(sender.value)
        UserDefaults.standard.set(GlobalStruct.customTextSize, forKey: "customTextSize")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        
        self.tableView.reloadData()
    }
    
    @objc func switchShowCW(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.showCW = true
            UserDefaults.standard.set(true, forKey: "showCW")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        } else {
            GlobalStruct.showCW = false
            UserDefaults.standard.set(false, forKey: "showCW")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        }
    }
    
    @objc func switchBlurSensitiveContent(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.blurSensitiveContent = true
            UserDefaults.standard.set(true, forKey: "blurSensitiveContent")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        } else {
            GlobalStruct.blurSensitiveContent = false
            UserDefaults.standard.set(false, forKey: "blurSensitiveContent")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        }
    }
    
    @objc func switchCircleProfiles(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.circleProfiles = true
            UserDefaults.standard.set(true, forKey: "circleProfiles")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "tabBarProfileIcon"), object: nil)
        } else {
            GlobalStruct.circleProfiles = false
            UserDefaults.standard.set(false, forKey: "circleProfiles")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "tabBarProfileIcon"), object: nil)
        }
    }
    
    @objc func switchAutoPlayingVideos(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.autoPlayVideos = true
            UserDefaults.standard.set(true, forKey: "autoPlayVideos")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        } else {
            GlobalStruct.autoPlayVideos = false
            UserDefaults.standard.set(false, forKey: "autoPlayVideos")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        }
    }
    
}
