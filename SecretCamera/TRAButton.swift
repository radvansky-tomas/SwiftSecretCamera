//
//  TRAButton.swift
//  QuitClock
//
//  Created by Tomas Radvansky on 12/01/2016.
//  Copyright © 2016 Tomas Radvansky. All rights reserved.
//

import UIKit
@IBDesignable
class TRAButton: UIButton {
    @IBInspectable var tintColorEnabled: Bool = false {
        didSet {
            if tintColorEnabled
            {
                if self.imageView?.image != nil
                {
                    if tintColorEnabled
                    {
                        self.setImage(self.imageView!.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: UIControlState.Normal)
                    }
                    else
                    {
                        self.setImage(self.imageView!.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal), forState: UIControlState.Normal)
                    }
                }
            }
        }
    }
    
    @IBInspectable
    var borderColor:UIColor = UIColor.clearColor() {
        didSet {
            self.layer.borderColor = borderColor.CGColor
        }
    }
    @IBInspectable
    var borderWidth:CGFloat = 0.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    @IBInspectable
    var cornerRadius:CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable
    var rounded:Bool = false {
        didSet {
            if rounded
            {
                self.layer.cornerRadius = self.frame.size.width / 2
                self.layer.masksToBounds = true
            }
            else
            {
                self.layer.cornerRadius = 0
                self.layer.masksToBounds = false
            }
        }
    }
    
    override var highlighted: Bool {
        didSet {
            if highlighted {
                self.alpha = 0.7
            }
            else
            {
                self.alpha = 1.0
            }
        }
    }
    
}
