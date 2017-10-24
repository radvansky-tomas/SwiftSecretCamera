//
//  ViewController.swift
//  SecretCamera
//
//  Created by Tomas Radvansky on 27/10/2015.
//  Copyright © 2015 Radvansky.Tomas. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreImage
import ImageIO
import AssetsLibrary
import MobileCoreServices

//@objc protocol CameraSessionControllerDelegate {
//    optional func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
//}

class ViewController: UIViewController,AVCaptureFileOutputRecordingDelegate {
    
    
    @IBOutlet var takePhotoGR: UITapGestureRecognizer!
    
    @IBOutlet var recordVideoGR: UILongPressGestureRecognizer!
    
    @IBOutlet weak var cameraIndicator: TRAButton!
    
    @IBOutlet weak var tutorialView: UIView!
    
    @IBOutlet var doubleTap: UITapGestureRecognizer!
    @IBOutlet var oneTap: UITapGestureRecognizer!
    //var sessionDelegate: CameraSessionControllerDelegate?
    let settings:SettingsHelper = SettingsHelper()
    var inBurstMode:Bool = false
    
    // MARK: Private properties
    var session: AVCaptureSession!
    var sessionQueue: dispatch_queue_t!
    var camera: AVCaptureDevice!
    var cameraInput: AVCaptureDeviceInput!
    var cameraOutput: AVCaptureVideoDataOutput!
    var stillImageOutput: AVCaptureStillImageOutput!
    var camereFileOutput:AVCaptureMovieFileOutput!
    var runtimeErrorHandlingObserver: AnyObject?
    var shouldPresentGallery:Bool = false
    var videoTrialTimer:NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        takePhotoGR.requireGestureRecognizerToFail(self.recordVideoGR)
        self.oneTap.requireGestureRecognizerToFail(self.doubleTap)
        #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
            return
        #endif
        self.session = AVCaptureSession()
        // ensure that our app is allowed to use the camera
        self.authorizeCamera()
        
        // grab the (rear facing) camera
        self.configureCamera()
        
        
        self.sessionQueue = dispatch_queue_create("CameraSessionController Session", DISPATCH_QUEUE_SERIAL)
        
        // dispatch sync will block until all actions are finished
        // this way, we prevent ourselves from starting the AVCaptureSession until after
        // the asynchronous configuriation steps have completed
        dispatch_sync(self.sessionQueue, {
            self.session.beginConfiguration()
            self.setSessionPreset()
            self.addVideoInput()
            //self.addVideoOutput()
            self.addStillImageOutput()
            self.addVideoFileOutput()
            self.session.commitConfiguration()
            self.session.startRunning()
        })
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        settings.lightDisplay()
        if segue.identifier == "SettingsSegue"
        {
            let navVC:UINavigationController = segue.destinationViewController as! UINavigationController
            let dest:SettingsViewController = navVC.viewControllers[0] as! SettingsViewController
            dest.maxZoom = Float(camera.activeFormat.videoMaxZoomFactor)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.settings.dimDisplay()
        turnTorch(settings.getLED())
        setZoom(settings.getZOOM())
        if (settings.getTutorial())
        {
            settings.lightDisplay()
            tutorialView.hidden = false
            tutorialView.alpha = 1.0
        }
        else
        {
            settings.dimDisplay()
            tutorialView.hidden = true
            tutorialView.alpha = 0.0
        }
    }
    
    @IBAction func tutorialTapped(sender: AnyObject) {
        tutorialView.hidden = true
        tutorialView.alpha = 0.0
        settings.setTutorial(false)
        settings.dimDisplay()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func recordVideoPress(sender: UITapGestureRecognizer) {
        if sender.state == .Began
        {
            if let file:NSURL = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingString("video.mov"))
            {
                print("Should start recording..." + file.absoluteString)
                if settings.shouldStopVideoCapture()
                {
                    print("Trial video started")
                    self.videoTrialTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(ViewController.stopTrialVideo), userInfo: nil, repeats: false)
                }
                self.camereFileOutput.startRecordingToOutputFileURL(file, recordingDelegate: self)
            }
        }
        else if sender.state == .Ended
        {
            print("Should stop recording...")
            if settings.shouldStopVideoCapture()
            {
                self.videoTrialTimer?.invalidate()
                self.videoTrialTimer = nil
            }
            if self.camereFileOutput.recording
            {
                self.camereFileOutput.stopRecording()
            }
        }
    }
    
    func stopTrialVideo()
    {
        self.videoTrialTimer?.invalidate()
        self.videoTrialTimer = nil
        print("Should stop trial recording...")
        if self.camereFileOutput.recording
        {
            self.camereFileOutput.stopRecording()
        }
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if (error != nil)
        {
            print(error.debugDescription)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(outputFileURL) { (url:NSURL!, assetError:NSError!) in
                if (assetError != nil)
                {
                    print(assetError.debugDescription)
                }
                do
                {
                    try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
                    //So its all succesfull, show indicator
                    dispatch_async(dispatch_get_main_queue(), {
                        if self.settings.shouldStopVideoCapture()
                        {
                            self.showIndicator(-1)
                        }
                        else
                        {
                            self.showIndicator(0)
                        }
                    })
                }
                catch
                {
                    
                }
                
            }
        }
        
    }
    
    
    @IBAction func takePhotoTap(sender: AnyObject) {
        //Burst photos
        inBurstMode = true
        let burst:Int = settings.getBURST()
        if burst==0
        {
            inBurstMode = false
        }
        for photos in 0...(settings.getBURST())
        {
            if burst>0
            {
                if photos == settings.getBURST()
                {
                    inBurstMode = false
                    print("Burst mode off")
                }
                sleep(1)
            }
            
            saveImage()
            print("Photo n\(photos+1)")
            
            
        }
    }
    
    
    func setZoom(value:Float)
    {
        do
        {
            try self.camera.lockForConfiguration()
            self.camera.videoZoomFactor = CGFloat(value)
            self.camera.unlockForConfiguration()
        }
        catch
        {
            
        }
    }
    
    func turnTorch(value:Bool){
        do
        {
            if self.camera.hasTorch {
                try self.camera.lockForConfiguration()
                if value
                {
                    self.camera.torchMode = .On
                }
                else
                {
                    self.camera.torchMode = .Off
                }
                self.camera.unlockForConfiguration()
            }
        }
        catch
        {
            
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
        if error == nil {
            if inBurstMode == false
            {
                self.showIndicator(1)
            }
        } else {
            print("Saving error!")
        }
    }
    
    func showIndicator(type:Int)
    {
        switch type {
        case -1:
            //Trial
            self.cameraIndicator.setTitle("Trial Video", forState: .Normal)
            break
        case 0:
            //Camera
            self.cameraIndicator.setTitle("Video", forState: .Normal)
            break
        case 1:
            //Image
            self.cameraIndicator.setTitle("", forState: .Normal)
            break
        default:
            self.cameraIndicator.setTitle("", forState: .Normal)
            break
        }
        settings.lightDisplay()
        //Show square for a while
        self.cameraIndicator.alpha = 0.0
        self.cameraIndicator.hidden = false
        UIView.animateWithDuration(0.5, delay: 0.0, options: .AllowUserInteraction, animations: {
            self.cameraIndicator.alpha = 1.0
            }, completion: { (completed:Bool) -> Void in
                UIView.animateWithDuration(0.3, delay: 1.0, options: .AllowUserInteraction, animations: {
                    self.cameraIndicator.alpha = 0.0
                    }, completion: { (completed:Bool) in
                        if completed
                        {
                            self.cameraIndicator.hidden = false
                            self.settings.dimDisplay()
                            if self.shouldPresentGallery
                            {
                                //present gallery
                                UIApplication.sharedApplication().openURL(NSURL(string: "photos-redirect://")!)
                            }
                        }
                })
                
        })
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let keys:String = keyPath
        {
            switch keys {
            case "adjustingFocus":
                print("adjustingFocus: \(self.camera.adjustingFocus)")
                self.checkIsAdjusting()
            case "adjustingExposure":
                print("adjustingExposure: \(self.camera.adjustingExposure)")
                self.checkIsAdjusting()
            case "adjustingExposure":
                print("adjustingWhiteBalance: \(self.camera.adjustingWhiteBalance)")
                self.checkIsAdjusting()
            default:
                break
            }
        }
    }
    
    // call this any time the 3 attributes update, so we can see if we're looking
    // at a frame that the camera hardware has decided it's happy with
    func checkIsAdjusting() {
        //println("checking!")
        if (!self.camera.adjustingFocus &&
            !self.camera.adjustingWhiteBalance) {
            print("we have a winner!")
        }
    }
    
    
    func authorizeCamera() {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
            (granted: Bool) -> Void in
            // If permission hasn't been granted, notify the user.
            if !granted {
                dispatch_async(dispatch_get_main_queue(), {
                    let alertVC:UIAlertController = UIAlertController(title: "Could not use camera!", message: "This application does not have permission to use camera. Please update your privacy settings.", preferredStyle: .Alert)
                    alertVC.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(alertVC, animated: true, completion: nil)
                })
            }
        });
    }
    
    
    func configureCamera() {
        // initialize the camera
        self.camera = ViewController.deviceWithMediaType(AVMediaTypeVideo, position: AVCaptureDevicePosition.Back)
        
        // Configure autofocus
        do
        {
            try self.camera.lockForConfiguration()
            self.camera.focusMode = .ContinuousAutoFocus
            self.camera.unlockForConfiguration()
        }
        catch
        {
            
        }
    }
    
    
    func setFocusPoint(point: CGPoint) {
        print("setting autofocus point to (\(point.x), \(point.y))")
        do
        {
            try self.camera.lockForConfiguration()
            self.camera.focusPointOfInterest = point
            self.camera.unlockForConfiguration()
        }
        catch
        {
            
        }
    }
    
    // static class function
    class func deviceWithMediaType(mediaType: String, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType)
        var captureDevice: AVCaptureDevice = devices.first as! AVCaptureDevice
        
        for object: AnyObject in devices {
            let device = object as! AVCaptureDevice
            if device.position == position {
                captureDevice = device
                break
            }
        }
        
        return captureDevice
    }
    
    
    // get the highest quality video stream possible
    // TODO maybe if image processing performance differs on different devices
    // we can try modify this based on the device...
    func setSessionPreset() {
        //        self.session.sessionPreset = AVCaptureSessionPresetHigh
        self.session.sessionPreset = AVCaptureSessionPreset1280x720
    }
    
    
    // Setup rear facing input and add the feed to our AVCaptureSession
    func addVideoInput() -> Bool {
        var success: Bool = false
        do
        {
            self.cameraInput = try AVCaptureDeviceInput(device: self.camera)
            if session.canAddInput(self.cameraInput) {
                self.session.addInput(self.cameraInput)
                success = true
            }
        }
        catch
        {
            print("Error addVideoInput")
        }
        return success
    }
    
    
    // Setup capture output for the video device input
        func addVideoOutput() {
            let settings: [String: Int] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
    
            self.cameraOutput = AVCaptureVideoDataOutput()
            self.cameraOutput.videoSettings = settings
            self.cameraOutput.alwaysDiscardsLateVideoFrames = true
    
            self.cameraOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
    
            if self.session.canAddOutput(self.cameraOutput) {
                self.session.addOutput(self.cameraOutput)
            }
        }
    
    func addVideoFileOutput() {
        
        self.camereFileOutput = AVCaptureMovieFileOutput()
        
        if self.session.canAddOutput(self.camereFileOutput) {
            self.session.addOutput(self.camereFileOutput)
        }
    }
    
    
    func addStillImageOutput() {
        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        print("image stabilization?: \(self.stillImageOutput.stillImageStabilizationSupported)")
        
        if self.session.canAddOutput(self.stillImageOutput) {
            self.session.addOutput(self.stillImageOutput)
        }
        else
        {
            print("error addStillImageOutput")
        }
    }
    
    
    func startCamera() {
        dispatch_async(self.sessionQueue, {
            let weakSelf: ViewController? = self
            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(
                AVCaptureSessionRuntimeErrorNotification,
                object: self.sessionQueue,
                queue: nil,
                usingBlock: {
                    (note: NSNotification!) -> Void in
                    
                    let strongSelf: ViewController = weakSelf!
                    
                    dispatch_async(strongSelf.sessionQueue, {
                        strongSelf.session.startRunning()
                    })
            })
        })
        self.session.startRunning()
    }
    
    
    func teardownCamera() {
        dispatch_async(self.sessionQueue, {
            self.session.stopRunning()
            NSNotificationCenter.defaultCenter().removeObserver(self.runtimeErrorHandlingObserver!)
        })
    }
    
    func focusAndExposeAtPoint(point: CGPoint) {
        dispatch_async(self.sessionQueue, {
            let device: AVCaptureDevice = self.cameraInput.device
            do
            {
                try device.lockForConfiguration()
                if device.focusPointOfInterestSupported && device.isFocusModeSupported(AVCaptureFocusMode.AutoFocus) {
                    device.focusPointOfInterest = point
                    device.focusMode = AVCaptureFocusMode.AutoFocus
                }
                
                if device.exposurePointOfInterestSupported && device.isExposureModeSupported(AVCaptureExposureMode.AutoExpose) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = AVCaptureExposureMode.AutoExpose
                }
                
                device.unlockForConfiguration()
                
            }
            catch
            {
                
            }
            
        })
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), closure)
    }
    
    // AVCaptureVideoDataOutputSampleBufferDelegate delegate method
    //    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
    //
    //        self.sessionDelegate?.cameraSessionDidOutputSampleBuffer?(sampleBuffer, fromConnection:connection)
    //        if (shouldTakePicture)
    //        {
    //
    //            shouldTakePicture = false
    //        }
    //    }
    
    func saveImage()
    {
        if let stillOutput = self.stillImageOutput {
            // we do this on another thread so that we don't hang the UI
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                //find the video connection
                var videoConnection : AVCaptureConnection?
                for connecton in stillOutput.connections {
                    //find a matching input port
                    for port in connecton.inputPorts!{
                        if port.mediaType == AVMediaTypeVideo {
                            videoConnection = connecton as? AVCaptureConnection
                            break //for port
                        }
                    }
                    
                    if videoConnection  != nil {
                        break// for connections
                    }
                }
                if videoConnection  != nil {
                    stillOutput.captureStillImageAsynchronouslyFromConnection(videoConnection){
                        (imageSampleBuffer : CMSampleBuffer!, _) in
                        
                        let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                        if let image: UIImage = UIImage(data: imageDataJpeg)
                        {
                            if self.settings.shouldRemoveWatermark()
                            {
                                UIImageWriteToSavedPhotosAlbum(image, self, #selector(ViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
                            }
                            else
                            {
                                print("Add Watermark")
                                //Add watermark
                                let newImageView = UIImageView(image : image)
                                let labelView = UILabel(frame: newImageView.frame) //adjust frame to change position of water mark or text
                                labelView.textColor = UIColor.redColor()
                                labelView.font = UIFont.boldSystemFontOfSize(60.0)
                                labelView.text = "Free Trial Version!"
                                labelView.textAlignment = .Center
                                newImageView.addSubview(labelView)
                                UIGraphicsBeginImageContext(newImageView.frame.size)
                                newImageView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
                                let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
                                UIGraphicsEndImageContext()
                                
                                UIImageWriteToSavedPhotosAlbum(watermarkedImage, self, #selector(ViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
                            }
                        }
                        
                    }
                }
            }
        }
        
    }
    
    //    func captureImageFromBuffer(sampleBuffer:CMSampleBufferRef) -> UIImage{
    //
    //        // Sampling Bufferから画像を取得
    //        let imageBuffer:CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
    //
    //        // pixel buffer のベースアドレスをロック
    //        CVPixelBufferLockBaseAddress(imageBuffer, 0)
    //
    //        let baseAddress:UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
    //
    //        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
    //        let width:Int = CVPixelBufferGetWidth(imageBuffer)
    //        let height:Int = CVPixelBufferGetHeight(imageBuffer)
    //
    //
    //        // 色空間
    //        let colorSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
    //
    //        // swift 2.0
    //        let newContext:CGContextRef = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,  CGImageAlphaInfo.PremultipliedFirst.rawValue|CGBitmapInfo.ByteOrder32Little.rawValue)!
    //
    //        let imageRef:CGImageRef = CGBitmapContextCreateImage(newContext)!
    //        let resultImage = UIImage(CGImage: imageRef, scale: 1.0, orientation: UIImageOrientation.Right)
    //
    //        return resultImage
    //    }
    //
    //MARK:- Img Picker
    
    
    @IBAction func doubleTapCorner(sender: AnyObject) {
        //Open galery
        UIApplication.sharedApplication().openURL(NSURL(string: "photos-redirect://")!)
    }
    
    @IBAction func oneTapCorner(sender: AnyObject) {
        //Override animation
        shouldPresentGallery = true
    }
    
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }
}

