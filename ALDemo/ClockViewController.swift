//
//  ClockViewController.swift
//  ALDemo
//
//  Created by 解 磊 on 2017/3/7.
//  Copyright © 2017年 AppLeg Corp. All rights reserved.
//

import UIKit

class ClockViewController: UIViewController {

    @IBOutlet weak var clockView: ClockView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var clockWidthConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.actionFromSlider(self.slider)
        self.actionFromDatePicker(self.datePicker)
    }
    
    @IBAction func actionFromSlider(_ sender: UISlider) {
        if let constraint = self.clockWidthConstraint {
            self.clockView.superview?.removeConstraint(constraint)
        }
        
        self.clockWidthConstraint = self.clockView.widthAnchor.constraint(equalTo: (self.clockView.superview?.widthAnchor)!, multiplier: CGFloat(sender.value))
        self.clockWidthConstraint?.isActive = true
    }
    
    @IBAction func actionFromDatePicker(_ sender: UIDatePicker) {
        self.clockView.date = sender.date
    }

}
