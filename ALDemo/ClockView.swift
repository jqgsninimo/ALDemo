//
//  ClockView.swift
//  Test
//
//  Created by 解 磊 on 16/4/14.
//  Copyright © 2016年 Mirror Life Corp. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(argb: UInt32) {
        self.init(
            red: CGFloat(argb >> 16 & 0xff) / 0xff,
            green: CGFloat(argb >> 8 & 0xff) / 0xff,
            blue: CGFloat(argb & 0xff) / 0xff,
            alpha: CGFloat(argb >> 24 & 0xff) / 0xff
        )
    }
}

class ClockView: UIView {
    fileprivate let hourLabelHeightRatio: CGFloat = 18.0 / 150
    fileprivate let centerViewSizeRatio: CGFloat = 8.0 / 150
    fileprivate let hourHandViewSizeRatio = CGSize(width: 3.0 / 150, height: 70.0 / 150)
    fileprivate let minuteHandViewSizeRatio = CGSize(width: 3.0 / 150, height: 130.0 / 150)
    fileprivate let dayColor = (background: UIColor(argb: 0xFFEFEFF4), foreground: UIColor.black)
    fileprivate let nightColor = (background: UIColor.black, foreground: UIColor.white)
    
    fileprivate let dialView = UIView()
    fileprivate let hourHandView = UIStackView()
    fileprivate let minuteHandView = UIStackView()
    fileprivate let centerView = UIView()
    fileprivate var hourLabels = [UILabel]()
    
    var date = Date() {
        didSet {
            self.adjustView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.generateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.generateView()
    }
    
    override func layoutSubviews() {
        let size = min(self.bounds.width, self.bounds.height)
        self.dialView.layer.cornerRadius = size / 2
        self.centerView.layer.cornerRadius = size * self.centerViewSizeRatio / 2
        
        self.hourLabels.forEach {
            $0.font = UIFont(name: "HelveticaNeue-Light", size: size * self.hourLabelHeightRatio)
        }
        
        if !self.hourLabels.isEmpty {
        }
    }
    
    fileprivate func generateView() {
        self.backgroundColor = UIColor.clear
        
        self.dialView.layer.allowsEdgeAntialiasing = true
        self.addSubview(self.dialView)
        self.dialView.translatesAutoresizingMaskIntoConstraints = false
        self.dialView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.dialView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.dialView.widthAnchor.constraint(equalTo: self.dialView.heightAnchor).isActive = true
        self.dialView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor).isActive = true
        self.dialView.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor).isActive = true
        [self.dialView.widthAnchor.constraint(equalTo: self.widthAnchor),
            self.dialView.widthAnchor.constraint(equalTo: self.widthAnchor)].forEach {
                $0.priority -= 1
                $0.isActive = true
        }
        
        self.centerView.layer.allowsEdgeAntialiasing = true
        self.dialView.addSubview(self.centerView)
        self.centerView.translatesAutoresizingMaskIntoConstraints = false
        self.centerView.centerXAnchor.constraint(equalTo: self.dialView.centerXAnchor).isActive = true
        self.centerView.centerYAnchor.constraint(equalTo: self.dialView.centerYAnchor).isActive = true
        self.centerView.widthAnchor.constraint(equalTo: self.dialView.widthAnchor, multiplier: self.centerViewSizeRatio).isActive = true
        self.centerView.heightAnchor.constraint(equalTo: self.dialView.heightAnchor, multiplier: self.centerViewSizeRatio).isActive = true
        
        for hour in 1...12 {
            let hourLabel = UILabel()
            hourLabel.text = String(hour)
            hourLabel.textAlignment = .center
            hourLabel.font = UIFont(name: "HelveticaNeue-Light", size: 10)
            
            self.dialView.addSubview(hourLabel)
            hourLabel.translatesAutoresizingMaskIntoConstraints = false
            hourLabel.heightAnchor.constraint(equalTo: self.dialView.heightAnchor, multiplier: self.hourLabelHeightRatio).isActive = true
            hourLabel.widthAnchor.constraint(equalTo: hourLabel.heightAnchor, multiplier: 2).isActive = true
            
            let centerXMultiplier = 1 + (1 - self.hourLabelHeightRatio * 2) * sin(CGFloat.pi * 2 / 12 * CGFloat(hour))
            let centerYMultiplier = 1 - (1 - self.hourLabelHeightRatio * 2) * cos(CGFloat.pi * 2 / 12 * CGFloat(hour))
            NSLayoutConstraint(item: hourLabel, attribute: .centerX, relatedBy: .equal, toItem: self.centerView, attribute: .centerX, multiplier: centerXMultiplier, constant: 0).isActive = true
            NSLayoutConstraint(item: hourLabel, attribute: .centerY, relatedBy: .equal, toItem: self.centerView, attribute: .centerY, multiplier: centerYMultiplier, constant: 0).isActive = true
            
            self.hourLabels.append(hourLabel)
        }
        
        [self.hourHandView, self.minuteHandView].forEach {
            $0.axis = .vertical
            $0.alignment = .fill
            $0.distribution = .fillEqually
            $0.addArrangedSubview(UIView())
            $0.addArrangedSubview(UIView())
            $0.arrangedSubviews.first?.layer.allowsEdgeAntialiasing  = true
        }
        self.dialView.addSubview(self.hourHandView)
        self.hourHandView.translatesAutoresizingMaskIntoConstraints = false
        self.hourHandView.widthAnchor.constraint(equalTo: self.dialView.widthAnchor, multiplier: self.hourHandViewSizeRatio.width).isActive = true
        self.hourHandView.heightAnchor.constraint(equalTo: self.dialView.heightAnchor, multiplier: self.hourHandViewSizeRatio.height).isActive = true
        self.hourHandView.centerXAnchor.constraint(equalTo: self.centerView.centerXAnchor).isActive = true
        self.hourHandView.centerYAnchor.constraint(equalTo: self.centerView.centerYAnchor).isActive = true
        
        self.dialView.addSubview(self.minuteHandView)
        self.minuteHandView.translatesAutoresizingMaskIntoConstraints = false
        self.minuteHandView.widthAnchor.constraint(equalTo: self.dialView.widthAnchor, multiplier: self.minuteHandViewSizeRatio.width).isActive = true
        self.minuteHandView.heightAnchor.constraint(equalTo: self.dialView.heightAnchor, multiplier: self.minuteHandViewSizeRatio.height).isActive = true
        self.minuteHandView.centerXAnchor.constraint(equalTo: self.centerView.centerXAnchor).isActive = true
        self.minuteHandView.centerYAnchor.constraint(equalTo: self.centerView.centerYAnchor).isActive = true
        
        self.adjustView()
    }
    
    func adjustView() {
        let dateComponents = (Calendar.current as NSCalendar).components([.hour, .minute], from: self.date)
        let hour = dateComponents.hour
        let minute = dateComponents.minute
        
        var color = self.nightColor
        if hour! > 6 && hour! < 18 {
            color = self.dayColor
        }
        self.dialView.backgroundColor = color.background
        self.hourHandView.arrangedSubviews[0].backgroundColor = color.foreground
        self.minuteHandView.arrangedSubviews[0].backgroundColor = color.foreground
        self.centerView.backgroundColor = color.foreground
        self.hourLabels.forEach { $0.textColor = color.foreground }
        
        self.hourHandView.transform = CGAffineTransform(rotationAngle: (CGFloat(hour!) * 60 + CGFloat(minute!)) / (12 * 60) * CGFloat.pi * 2)
        self.minuteHandView.transform = CGAffineTransform(rotationAngle: CGFloat(minute!) / 60 * CGFloat.pi * 2)
    }
}
