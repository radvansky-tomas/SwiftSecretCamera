//
//  TRALayerView.swift
//  SecretCamera
//
//  Created by Tomas Radvansky on 27/10/2015.
//  Copyright © 2015 Radvansky.Tomas. All rights reserved.
//

import UIKit

@IBDesignable class TRALayerView: UIView {
    //MARK: Layer parameters
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
    
}
