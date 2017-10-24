//
//  SettingsHelper.swift
//  SecretCamera
//
//  Created by Tomas Radvansky on 11/04/2016.
//  Copyright © 2016 Radvansky.Tomas. All rights reserved.
//

import UIKit
import RMStore

class SettingsHelper: NSObject {
    //Settings constants
    let ledSetting:String = "LED_SETTING"
    let zoomSetting:String = "ZOOM_SETTING"
    let videoSetting:String = "VIDEO_QUALITY_SETTING"
    let burstSetting:String = "BURST_PHOTO_SETTING"
    let tutorialSetting:String = "TUTORIAL_SETTING"
    //Products constants
    let unlimitedVideoID:String = "com.tomas.radvansky.secretcamera.video"
    let watermarkID:String = "com.tomas.radvansky.secretcamera.watermark"
    //Display
    let displaySetting:String = "DISPLAY_SETTING"
    let displayStatus:String = "DISPLAY_STATUS_SETTING"
    
    let defaultSettings:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    let defaultStore:RMStore = RMStore.defaultStore()
    
    func dimDisplay()
    {
        UIScreen.mainScreen().brightness = 0.0
        defaultSettings.setBool(false, forKey: displayStatus)
        defaultSettings.synchronize()
    }
    
    func lightDisplay()
    {
        UIScreen.mainScreen().brightness = getOldBrightness()
        defaultSettings.setBool(true, forKey: displayStatus)
        defaultSettings.synchronize()
    }
    
    func getOldBrightness()->CGFloat
    {
        if let value:Float = defaultSettings.floatForKey(displaySetting)
        {
            return CGFloat(value)
        }
        else
        {
            //defaul value
            setOldBrightness(1.0)
            return 1.0
        }
    }
    
    func setOldBrightness(value:CGFloat)
    {
        defaultSettings.setFloat(Float(value), forKey: displaySetting)
        defaultSettings.synchronize()
    }
    
    func getTutorial()->Bool
    {
        if let value:Bool = defaultSettings.boolForKey(tutorialSetting)
        {
            return value
        }
        else
        {
            //defaul value
            setTutorial(true)
            return true
        }
    }
    
    func setTutorial(value:Bool)
    {
        defaultSettings.setBool(value, forKey: tutorialSetting)
        defaultSettings.synchronize()
    }
    
    func getLED()->Bool
    {
        if let value:Bool = defaultSettings.boolForKey(ledSetting)
        {
            return value
        }
        else
        {
            //defaul value
            setLED(false)
            return false
        }
    }
    
    func setLED(value:Bool)
    {
        defaultSettings.setBool(value, forKey: ledSetting)
        defaultSettings.synchronize()
    }
    
    func getBURST()->Int
    {
        if let value:Int = defaultSettings.integerForKey(burstSetting)
        {
            return value
        }
        else
        {
            //defaul value
            setBURST(0)
            return 0
        }
    }
    
    func setBURST(value:Int)
    {
        defaultSettings.setInteger(value, forKey: burstSetting)
        defaultSettings.synchronize()
    }
    
    func getVIDEO()->Float
    {
        if let value:Float = defaultSettings.floatForKey(videoSetting)
        {
            return value
        }
        else
        {
            //defaul value
            setVIDEO(1.0)
            return 1.0
        }
    }
    
    func setVIDEO(value:Float)
    {
        defaultSettings.setFloat(value, forKey: videoSetting)
        defaultSettings.synchronize()
    }
    
    func getZOOM()->Float
    {
        if let value:Float = defaultSettings.floatForKey(zoomSetting)
        {
            return value
        }
        else
        {
            //defaul value
            setZOOM(1.0)
            return 1.0
        }
    }
    
    func setZOOM(value:Float)
    {
        defaultSettings.setFloat(value, forKey: zoomSetting)
        defaultSettings.synchronize()
    }
    
    func shouldRemoveWatermark()->Bool
    {
        let keychainPersistence:RMStoreKeychainPersistence = defaultStore.transactionPersistor as! RMStoreKeychainPersistence
        return keychainPersistence.isPurchasedProductOfIdentifier(self.watermarkID)
    }
    
    func shouldStopVideoCapture()->Bool
    {
        let keychainPersistence:RMStoreKeychainPersistence = defaultStore.transactionPersistor as! RMStoreKeychainPersistence
        return !keychainPersistence.isPurchasedProductOfIdentifier(self.unlimitedVideoID)
    }
    
    
}
