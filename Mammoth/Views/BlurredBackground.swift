//
//  BlurredBackground.swift
//  Mammoth
//
//  Created by Benoit Nolens on 04/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class BlurredBackground: UIView {
    static let blurEffectDimmed = UIBlurEffect(style: .regular)
    static let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    
    private let blurEffectView: UIVisualEffectView
    
    private let underlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var isDimmed: Bool = false
    
    init(dimmed: Bool = false, underlayAlpha: CGFloat? = nil) {
        if dimmed {
            blurEffectView = UIVisualEffectView(effect: Self.blurEffectDimmed)
        } else {
            blurEffectView = UIVisualEffectView(effect: Self.blurEffect)
        }
        
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: .zero)
        
        self.isDimmed = dimmed
        self.addSubview(underlay)
        self.addSubview(blurEffectView)
        
        if (self.traitCollection.userInterfaceStyle == .light) {
            underlay.backgroundColor = .custom.background.darker(by: 0.65)?.withAlphaComponent(underlayAlpha ?? (self.isDimmed ? 0.75 : 0.35))
        } else {
            underlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: underlayAlpha ?? (self.isDimmed ? 0.85 : 0.45))
        }
        
        NSLayoutConstraint.activate([
            underlay.topAnchor.constraint(equalTo: self.topAnchor),
            underlay.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            underlay.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            underlay.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if (traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)) {
                 if (self.traitCollection.userInterfaceStyle == .light) {
                     underlay.backgroundColor = .custom.background.darker(by: 0.65)?.withAlphaComponent(self.isDimmed ? 0.75 : 0.35)
                 } else {
                     underlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: self.isDimmed ? 0.85 : 0.45)
                 }
             }
         }
    }
    
}
