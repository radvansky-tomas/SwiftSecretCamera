//
//  EditCellViewController.swift
//  SecretCamera
//
//  Created by Tomas Radvansky on 11/04/2016.
//  Copyright © 2016 Radvansky.Tomas. All rights reserved.
//

import UIKit

class EditCellViewController: UIViewController {

    @IBOutlet weak var sliderView: UISlider!
    var min:Float = 0.0
    var max:Float = 1.0
    var format:String = "%f"
    var initValue:Float = 0.0
    var successBlock: ((controller:EditCellViewController, value:Float) -> ())?
    var cancelBlock: ((controller:EditCellViewController) -> ())?
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    
    var navTitle:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.minLabel.text = String(format:format,min)
        self.maxLabel.text = String(format:format,max)
        self.sliderView.minimumValue = min
        self.sliderView.maximumValue = max
        self.sliderView.value = self.initValue
        self.updateTitle()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTitle()
    {
        self.navigationItem.title = "\(navTitle) - \(String(format:format,self.sliderView.value))"
    }
    
    @IBAction func sliderChanged(sender: AnyObject) {
        self.updateTitle()
    }
    
    @IBAction func cancelBtnClicked(sender: AnyObject) {
      self.cancelBlock?(controller: self)
    }
    @IBAction func saveBtnClicked(sender: AnyObject) {
        self.successBlock?(controller: self,value: self.sliderView.value)
    }
}
