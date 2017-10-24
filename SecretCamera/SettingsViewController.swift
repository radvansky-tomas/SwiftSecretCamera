//
//  SettingsViewController.swift
//  SecretCamera
//
//  Created by Tomas Radvansky on 30/03/2016.
//  Copyright © 2016 Radvansky.Tomas. All rights reserved.
//

import UIKit
import RMStore
import MZFormSheetPresentationController

class SettingsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let settings:SettingsHelper = SettingsHelper()
    let defaultStore:RMStore = RMStore.defaultStore()
    
    var appproducts:Array<SKProduct> = Array<SKProduct> ()
    var maxZoom:Float = 2.0
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProducts()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
         self.settings.lightDisplay()
    }
    
    func loadProducts()
    {
        let products:Set<NSObject>! = [settings.unlimitedVideoID,settings.watermarkID]
        defaultStore.requestProducts(products, success: { (products:[AnyObject]!, invalidProductIdentifiers:[AnyObject]!) in
            print(products.description)
            self.appproducts = products as! Array<SKProduct>
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        }) { (error:NSError!) in
            print(error.description)
            self.appproducts.removeAll()
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell", forIndexPath: indexPath)
                let headerLabel:UILabel = cell.viewWithTag(100) as! UILabel
                headerLabel.text = "General Settings"
                return cell
                
            case 1:
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailCell", forIndexPath: indexPath)
                cell.textLabel?.text = "LED"
                if settings.getLED() == true
                {
                    cell.detailTextLabel?.text = "On"
                }
                else
                {
                    cell.detailTextLabel?.text = "Off"
                }
                return cell
                
            case 2:
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailCell", forIndexPath: indexPath)
                cell.textLabel?.text = "Zoom"
                cell.detailTextLabel?.text = String(format: "%.1fx",settings.getZOOM())
                return cell
                
            case 3:
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailCell", forIndexPath: indexPath)
                cell.textLabel?.text = "Video Quality"
                cell.detailTextLabel?.text = String(format: "%.f%%",settings.getVIDEO()*100)
                return cell
                
            case 4:
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailCell", forIndexPath: indexPath)
                cell.textLabel?.text = "Burst Photo"
                let burst:Int = settings.getBURST()
                if burst == 0
                {
                    cell.detailTextLabel?.text = "Off"
                }
                else
                {
                    cell.detailTextLabel?.text = "\(burst) photo/s"
                }
                return cell
                
            default:
                return UITableViewCell()
            }
            
        case 1:
            if indexPath.row == 0
            {
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell", forIndexPath: indexPath)
                let headerLabel:UILabel = cell.viewWithTag(100) as! UILabel
                headerLabel.text = "In-App Purchases"
                return cell
            }
            else if indexPath.row == self.appproducts.count + 1
            {
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("RestoreCell", forIndexPath: indexPath)
                let restoreBtn:UIButton = cell.viewWithTag(100) as! UIButton
                restoreBtn.addTarget(self, action: #selector(SettingsViewController.restoreBtnClicked(_:)), forControlEvents: .TouchUpInside)
                return cell
            }
            else
            {
                if self.appproducts.count > 0
                {
                    let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailCell", forIndexPath: indexPath)
                    
                    let product:SKProduct = self.appproducts[indexPath.row-1]
                    let keychainPersistence:RMStoreKeychainPersistence = defaultStore.transactionPersistor as! RMStoreKeychainPersistence
                    cell.textLabel?.text  = product.localizedTitle
                    if keychainPersistence.isPurchasedProductOfIdentifier(product.productIdentifier)
                    {
                        cell.detailTextLabel?.text = "Owned"
                    }
                    else
                    {
                        let numberformatter:NSNumberFormatter = NSNumberFormatter()
                        numberformatter.numberStyle = .CurrencyStyle
                        numberformatter.formatterBehavior = .Behavior10_4
                        numberformatter.locale = product.priceLocale
                        
                        print(product.localizedDescription)
                        cell.detailTextLabel?.text = numberformatter.stringFromNumber(product.price)
                    }
                    return cell
                }
            }
            break
        case 2:
            switch indexPath.row {
            case 0:
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell", forIndexPath: indexPath)
                let headerLabel:UILabel = cell.viewWithTag(100) as! UILabel
                headerLabel.text = "About Application"
                return cell
            case 1:
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailCell", forIndexPath: indexPath)
                cell.textLabel?.text = "Credits"
                cell.detailTextLabel?.text = "Tomas Radvansky"
                return cell
            case 2:
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailCell", forIndexPath: indexPath)
                cell.textLabel?.text = "Version"
                if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
                    cell.detailTextLabel?.text = version
                }
                else
                {
                    cell.detailTextLabel?.text = ""
                }
                
                return cell
            case 3:
                let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailCell", forIndexPath: indexPath)
                cell.textLabel?.text = "Show Tutorial"
                cell.detailTextLabel?.text = ""
                return cell
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
        return UITableViewCell()
    }
    
    
    func restoreBtnClicked(sender:UIButton!)
    {
        defaultStore.restoreTransactionsOnSuccess({ (transactions:[AnyObject]!) in
            print(transactions.description)
        }) { (error:NSError!) in
            print(error.localizedDescription)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0
        {
            return 5
        }
        else if section == 1
        {
            return 2 + self.appproducts.count
        }
        else
        {
            return 4
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 1:
                settings.setLED(!settings.getLED())
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                break
            case 2:
                let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier("EditCellNVC") as! UINavigationController
                let editVC:EditCellViewController = navigationController.viewControllers[0] as! EditCellViewController
                editVC.navTitle = "Select Zoom"
                editVC.min = 1.0
                editVC.max = self.maxZoom
                editVC.initValue = settings.getZOOM()
                editVC.format = "%.1fx"
                editVC.successBlock = {(controller:EditCellViewController, value:Float) in
                    controller.dismissViewControllerAnimated(true, completion: {
                        self.settings.setZOOM(value)
                        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                    })
                }
                
                editVC.cancelBlock = {(controller:EditCellViewController) in
                    controller.dismissViewControllerAnimated(true, completion: nil)
                }
                
                let formSheetController = MZFormSheetPresentationViewController(contentViewController: navigationController)
                formSheetController.presentationController?.contentViewSize = CGSizeMake(300, 200)
                formSheetController.presentationController?.shouldCenterVertically = true
                formSheetController.presentationController?.shouldCenterHorizontally = true
                formSheetController.presentationController?.shouldDismissOnBackgroundViewTap = false
                
                self.presentViewController(formSheetController, animated: true, completion: nil)
                break
            case 3:
                let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier("EditCellNVC") as! UINavigationController
                let editVC:EditCellViewController = navigationController.viewControllers[0] as! EditCellViewController
                editVC.navTitle = "Select Video Quality"
                editVC.min = 0.0
                editVC.max = 100.0
                editVC.initValue = settings.getVIDEO()*100
                editVC.format = "%.f%%"
                editVC.successBlock = {(controller:EditCellViewController, value:Float) in
                    controller.dismissViewControllerAnimated(true, completion: {
                        self.settings.setVIDEO(value/100.0)
                        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                    })
                }
                
                editVC.cancelBlock = {(controller:EditCellViewController) in
                    controller.dismissViewControllerAnimated(true, completion: nil)
                }
                
                let formSheetController = MZFormSheetPresentationViewController(contentViewController: navigationController)
                formSheetController.presentationController?.contentViewSize = CGSizeMake(300, 200)
                formSheetController.presentationController?.shouldCenterVertically = true
                formSheetController.presentationController?.shouldCenterHorizontally = true
                formSheetController.presentationController?.shouldDismissOnBackgroundViewTap = false
                
                self.presentViewController(formSheetController, animated: true, completion: nil)
                break
            case 4:
                let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier("EditCellNVC") as! UINavigationController
                let editVC:EditCellViewController = navigationController.viewControllers[0] as! EditCellViewController
                editVC.navTitle = "Burst Photos"
                editVC.min = 0.0
                editVC.max = 5.0
                editVC.initValue = Float(settings.getBURST())
                editVC.format = "%.fx"
                editVC.successBlock = {(controller:EditCellViewController, value:Float) in
                    controller.dismissViewControllerAnimated(true, completion: {
                        self.settings.setBURST(Int(value))
                        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                    })
                }
                
                editVC.cancelBlock = {(controller:EditCellViewController) in
                    controller.dismissViewControllerAnimated(true, completion: nil)
                }
                
                let formSheetController = MZFormSheetPresentationViewController(contentViewController: navigationController)
                formSheetController.presentationController?.contentViewSize = CGSizeMake(300, 200)
                formSheetController.presentationController?.shouldCenterVertically = true
                formSheetController.presentationController?.shouldCenterHorizontally = true
                formSheetController.presentationController?.shouldDismissOnBackgroundViewTap = false
                
                self.presentViewController(formSheetController, animated: true, completion: nil)
                break
            default:
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                break
            }
            break
        case 1:
            if indexPath.row > 0 && indexPath.row < (1 + self.appproducts.count)
            {
                let product:SKProduct = self.appproducts[indexPath.row-1]
                let numberformatter:NSNumberFormatter = NSNumberFormatter()
                numberformatter.numberStyle = .CurrencyStyle
                numberformatter.formatterBehavior = .Behavior10_4
                numberformatter.locale = product.priceLocale
                let alertVC:UIAlertController = UIAlertController(title: "In-App Purchase", message: product.localizedDescription, preferredStyle: .Alert)
                alertVC.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action:UIAlertAction) in
                    //
                }))
                alertVC.addAction(UIAlertAction(title: numberformatter.stringFromNumber(product.price), style: .Destructive, handler: { (action:UIAlertAction) in
                    self.defaultStore.addPayment(product.productIdentifier, success: { (transaction:SKPaymentTransaction!) in
                        self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                        }, failure: { (transaction:SKPaymentTransaction!, error:NSError!) in
                            print(error.localizedDescription)
                    })
                }))
                self.presentViewController(alertVC, animated: true, completion: nil)
            }
            break
        case 2:
            switch indexPath.row {
            case 1:
                //Open my linkedin
                break
            case 2:
                //Open rate app
                if RateMyApp.sharedInstance.shouldShowAlert(true)
                {
                    self.dismissViewControllerAnimated(true, completion: {
                        RateMyApp.sharedInstance.showRatingAlert()
                    })
                }
                
                break
            case 3:
                settings.setTutorial(true)
                self.dismissViewControllerAnimated(true, completion: nil)
                break
            default:
                break
            }
            break
        default:
            break
        }
    }
    
    @IBAction func cameraBtnClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
