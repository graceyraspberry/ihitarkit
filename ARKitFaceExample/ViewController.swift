/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit
import Foundation
import Dispatch

class ViewController: UIViewController, ARSessionDelegate {
    
    // MARK: Outlets

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var tabBar: UITabBar!
    
    // View Controller State
//    var isRecording = false
    
//    var writer : AVAssetWriter?
//    var videoInput : AVAssetWriterInput?
//    var buffer : AVAssetWriterInputPixelBufferAdaptor?
    
    var initialTime : TimeInterval?
    var gotInitial = false
    
    // my test
    var snapshotArray:[[String:Any]] = [[String:Any]]()
    var lastTime:TimeInterval = 0
    var isRecording:Bool = false;
    
    
    var pixelBufferAdaptor:AVAssetWriterInputPixelBufferAdaptor?
    var videoInput:AVAssetWriterInput?;
    var assetWriter:AVAssetWriter?;
    
    // Button Functionality
    func startRecording() {
        self.lastTime = 0;
        self.isRecording = true;
    }
        
    func stopRecording() {
        self.isRecording = false;
        self.saveVideo(withName: "test", imageArray: self.snapshotArray, fps: 30, size: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height));
    }


    @IBAction func callVideoPlayer(_ sender: Any) {
        
        if !self.isRecording
        {
            self.startRecording()
            print("Beginning recording")
            self.isRecording = true
            
        } else
        {
            self.stopRecording()
            print("Recording Done.")
            self.isRecording = false
            
            // visualize
//            UIView.setAnimationsEnabled(false)
//            self.performSegue(withIdentifier: "goVisualizer", sender: self)
            let visualizer = VisualizerLauncher()
            visualizer.showVideoPlayer(url: (assetWriter?.outputURL)!)
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       let destVC : VisualizerViewController = segue.destination as! VisualizerViewController
        destVC.url = (assetWriter?.outputURL)!

    }
    
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        if (!gotInitial)
//        {
//            gotInitial = true
//            initialTime = frame.timestamp
//        }
//        
//        var time = frame.timestamp - initialTime!
//        if isRecording
//        {
//            if (videoInput?.isReadyForMoreMediaData)!
//            {
//                print("Time stamp: \(time)")
//                let cmTime = CMTime(seconds: time, preferredTimescale: 1)
//                buffer!.append(frame.capturedImage, withPresentationTime: cmTime)
//            }
//        }
//    }
    
    // Recorder Functions
//    func startRecording()
//    {
//
//        if (writer?.startWriting())!
//        {
//
//            writer?.startSession(atSourceTime: CMTime.zero)
//            self.isRecording = true
//
//        }
//
//    }
//
//    func stopRecording()
//    {
//        writer?.finishWriting()
//        {
//            self.videoInput?.markAsFinished()
//            print("Finished Writing")
//            self.isRecording = false
//        }
//    }
    
    // MARK: Properties

    var contentControllers: [VirtualContentType: VirtualContentController] = [:]
    
    var selectedVirtualContent: VirtualContentType! {
        didSet {
            guard oldValue != nil, oldValue != selectedVirtualContent
                else { return }
            
            // Remove existing content when switching types.
            contentControllers[oldValue]?.contentNode?.removeFromParentNode()
            
            // If there's an anchor already (switching content), get the content controller to place initial content.
            // Otherwise, the content controller will place it in `renderer(_:didAdd:for:)`.
            if let anchor = currentFaceAnchor, let node = sceneView.node(for: anchor),
                let newContent = selectedContentController.renderer(sceneView, nodeFor: anchor) {
                node.addChildNode(newContent)
            }
        }
    }
    var selectedContentController: VirtualContentController {
        if let controller = contentControllers[selectedVirtualContent] {
            return controller
        } else {
            let controller = selectedVirtualContent.makeController()
            contentControllers[selectedVirtualContent] = controller
            return controller
        }
    }
    
    var currentFaceAnchor: ARFaceAnchor?
    
    //local storage
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
//        //recording
//        let generator = WriterGenerator()
//        let settings = generator.getTestAssetWriter()
//        self.writer = settings["writer"] as! AVAssetWriter
//        self.videoInput = settings["input"] as! AVAssetWriterInput
//        self.buffer = settings["buffer"] as! AVAssetWriterInputPixelBufferAdaptor
        
        // Set the initial face content.
        tabBar.selectedItem = tabBar.items!.first!
        selectedVirtualContent = VirtualContentType(rawValue: tabBar.selectedItem!.tag)
    }
    
    func generateAssetWriter(outputURL : URL) -> AVAssetWriter
   {
       let writer = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
       return writer!
   }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension ViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let contentType = VirtualContentType(rawValue: item.tag)
            else { fatalError("unexpected virtual content tag") }
        selectedVirtualContent = contentType
    }
}

extension ViewController: ARSCNViewDelegate {
        
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        currentFaceAnchor = faceAnchor
        
        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        if node.childNodes.isEmpty, let contentNode = selectedContentController.renderer(renderer, nodeFor: faceAnchor) {
            node.addChildNode(contentNode)
        }
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard anchor == currentFaceAnchor,
            let contentNode = selectedContentController.contentNode,
            contentNode.parent == node
            else { return }
        
        selectedContentController.renderer(renderer, didUpdate: contentNode, for: anchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        func didUpdateAtTime(time: TimeInterval) {
            
            if self.isRecording {
                if self.lastTime == 0 || (self.lastTime + 1/31) < time {
                    DispatchQueue.main.async { [weak self] () -> Void in
                        
                        print("UPDATE AT TIME : \(time)");
                        guard self != nil else { return }
                        self!.lastTime = time;
                        let snapshot:UIImage = self!.sceneView.snapshot()
                        
                        let scale = CMTimeScale(NSEC_PER_SEC)
                        
                        self!.snapshotArray.append([
                            "image":snapshot,
                            "time": CMTime(value: CMTimeValue((self?.sceneView.session.currentFrame!.timestamp)! * Double(scale)), timescale: scale)
                        ]);
                        
                    }
                }
            }
        }
    }



    // MARK: SAVE VIDEO FUNCTIONALITY
    public func saveVideo(withName:String, imageArray:[[String:Any]], fps:Int, size:CGSize) {
            
            self.createURLForVideo(withName: withName) { (videoURL) in
                self.prepareWriterAndInput(imageArray:imageArray, size:size, videoURL: videoURL, completionHandler: { (error) in
                    
                    guard error == nil else {
                        // it errored.
                        return
                    }
                    
                    self.createVideo(imageArray: imageArray, fps: fps, size:size, completionHandler: { _ in
                        print("[F] saveVideo :: DONE");
                        
                        guard error == nil else {
                            // it errored.
                            return
                        }
                        
                        self.finishVideoRecordingAndSave();
                        
                    });
                });
            }
            
        }
        
        private func createURLForVideo(withName:String, completionHandler:@escaping (URL)->()) {
            // Clear the location for the temporary file.
            let temporaryDirectoryURL:URL = URL.init(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true);
            let targetURL:URL = temporaryDirectoryURL.appendingPathComponent("\(withName).mp4")
            // Delete the file, incase it exists.
            do {
                try FileManager.default.removeItem(at: targetURL);
                
            } catch let error {
                NSLog("Unable to delete file, with error: \(error)")
            }
            // return the URL
            completionHandler(targetURL);
        }
        
        private func prepareWriterAndInput(imageArray:[[String:Any]], size:CGSize, videoURL:URL, completionHandler:@escaping(Error?)->()) {
            
            do {
                self.assetWriter = try AVAssetWriter(outputURL: videoURL, fileType: AVFileType.mp4)
                
                let videoOutputSettings: Dictionary<String, Any> = [
                    AVVideoCodecKey : AVVideoCodecType.h264,
                    AVVideoWidthKey : size.width,
                    AVVideoHeightKey : size.height
                ];
        
                self.videoInput  = AVAssetWriterInput (mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
                self.videoInput!.expectsMediaDataInRealTime = true
                self.assetWriter!.add(self.videoInput!)
                
                // Create Pixel buffer Adaptor
                
                let sourceBufferAttributes:[String : Any] = [
                    (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
                    (kCVPixelBufferWidthKey as String): Float(size.width),
                    (kCVPixelBufferHeightKey as String): Float(size.height)] as [String : Any]
                
                self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.videoInput!, sourcePixelBufferAttributes: sourceBufferAttributes);
        
                self.assetWriter?.startWriting();
                self.assetWriter?.startSession(atSourceTime: CMTime.zero);
                completionHandler(nil);
            }
            catch {
                print("Failed to create assetWritter with error : \(error)");
                completionHandler(error);
            }
        }
        
        private func createVideo(imageArray:[[String:Any]], fps:Int, size:CGSize, completionHandler:@escaping(String?)->()) {
            
            var currentframeTime:CMTime = CMTime.zero;
            var currentFrame:Int = 0;
            
            let startTime:CMTime = (imageArray[0])["time"] as! CMTime;
            
            while (currentFrame < imageArray.count) {
                
                // When the video input is ready for more media data...
                if (self.videoInput?.isReadyForMoreMediaData)!  {
                    print("processing current frame :: \(currentFrame)");
                    // Get current CG Image
                    let currentImage:UIImage = (imageArray[currentFrame])["image"] as! UIImage;
                    let currentCGImage:CGImage? = currentImage.cgImage;
                    
                    guard currentCGImage != nil else {
                        completionHandler("failed to get current cg image");
                        return
                    }
                    
                    // Create the pixel buffer
                    self.createPixelBufferFromUIImage(image: currentImage) { (error, pixelBuffer) in
                        
                        guard error == nil else {
                            completionHandler("failed to get pixelBuffer");
                            return
                        }
                        
                        // Calc the current frame time
                        currentframeTime = (imageArray[currentFrame])["time"] as! CMTime - startTime;
                        
                        print("SECONDS : \(currentframeTime.seconds)")
                        
                        print("Current frame time :: \(currentframeTime)");
                        
                        // Add pixel buffer to video input
                        self.pixelBufferAdaptor!.append(pixelBuffer!, withPresentationTime: currentframeTime);
                        
                        // increment frame
                        currentFrame += 1;
                    }
                }
            }
            
            // FINISHED
            completionHandler(nil);
        }
        
        
        private func createPixelBufferFromUIImage(image:UIImage, completionHandler:@escaping(String?, CVPixelBuffer?) -> ()) {
            //https://stackoverflow.com/questions/44400741/convert-image-to-cvpixelbuffer-for-machine-learning-swift
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            var pixelBuffer : CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
            guard (status == kCVReturnSuccess) else {
                completionHandler("Failed to create pixel buffer", nil)
                return
            }
            
            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
            
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            
            context?.translateBy(x: 0, y: image.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            
            UIGraphicsPushContext(context!)
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            
            completionHandler(nil, pixelBuffer)
        }
        
        
        private func finishVideoRecordingAndSave() {
            self.videoInput!.markAsFinished();
            self.assetWriter?.finishWriting(completionHandler: {
                print("output url : \(self.assetWriter?.outputURL)");
                
                PHPhotoLibrary.requestAuthorization({ (status) in
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: (self.assetWriter?.outputURL)!)
                    }) { saved, error in
                        
                        if saved {
                            let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(defaultAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                        // Clear the original array
                        self.snapshotArray.removeAll();
                        // Clear memory
                        FileManager.default.clearTempMemory();
                    }
                })
            })
        }
}

