/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the ARKitVision sample.
*/

import UIKit
import SpriteKit
import ARKit
import Vision

//
/*
 */

class ViewController: UIViewController, UIGestureRecognizerDelegate, ARSKViewDelegate, ARSessionDelegate {
    
    //MARK: properties
   //  let defaults = UserDefaults.standard
    
    @IBOutlet weak var sceneView: ARSKView!
    
    // The view controller that displays the status and "restart experience" UI.
    private lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    // MARK: - View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Configure and present the SpriteKit scene that draws overlay content.
        let overlayScene = SKScene()
        overlayScene.scaleMode = .aspectFill
        sceneView.delegate = self
        sceneView.presentScene(overlayScene)
        sceneView.session.delegate = self
        
        // Hook up status view controller callback.
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartSession()
        }
        addLanguageChoice()
        checkPreferLanguage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    // MARK: - ARSessionDelegate
    
    // Pass camera frames received from ARKit to Vision (when not already processing one)
    /// - Tag: ConsumeARFrames
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
    }
    
    // MARK: - Vision classification
    
    // Vision classification request and model
    /// - Tag: ClassificationRequest
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Instantiate the model from its generated Swift class.
            let model = try VNCoreMLModel(for: Resnet50().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            
            // Crop input images to square area at center, matching the way the ML model was trained.
            request.imageCropAndScaleOption = .centerCrop
            
            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            request.usesCPUOnly = true
            
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    
    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")
    
    // Run the Vision+ML classifier on the current image buffer.
    /// - Tag: ClassifyCurrentImage
    private func classifyCurrentImage() {
        // Most computer vision tasks are not rotation agnostic so it is important to pass in the orientation of the image with respect to device.
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.classificationRequest])
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    // Classification results
    public var identifierString = ""
    public var secondConfidence: VNConfidence = 0.0
    private var confidence: VNConfidence = 0.0
    //translation
    public var translateText = ""
    // Handle completion of the Vision request and choose results to display.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
        let classifications = results as! [VNClassificationObservation]
        
        // let testingClass = results as! [VNClassificationObservation]
        

        
        // Show a label for the highest-confidence result (but only above a minimum confidence threshold).
        // Gives the first found classification that satisfies the condition of a confidence greater than 50%
        
        if let bestResult = classifications.first(where: { result in result.confidence > 0.5 }),
            // S - Splits up result classifications and takes the first to use as label
            let label = bestResult.identifier.split(separator: ",").first {
            // S - identifierString is the string used for the name of the classified object
            identifierString = String(label)
            // S - percent confidence in best result
            confidence = bestResult.confidence

        } else {
            
            identifierString = ""
            confidence = 0
        }
      
        /* if let secondBest = classifications.first (where: { result in result.confidence > 0.4 }),
            
            let label2 = secondBest.identifier.split(separator:",").first {
            
            
            secondConfidence = secondBest.confidence
            
        } else {
            
            confidence = 0
            
        }
        
        if let secondResult = testingclass[2]
        {
            let label = secondResult.identifier.split(separator: ",")
        }
         */
        
        //Starts API call to Cloud Google Translate API
        SwiftGoogleTranslate.shared.start (with: "AIzaSyDQ2Bm5SDnFngMskSnFxWko1MIaUJDdwpg")
        
        // Get supported languages
        if (SwiftGoogleTranslate.shared.result.isEmpty){
            SwiftGoogleTranslate.shared.languages { (languages, error) in}
        }
        
        
        //Translates object identifierString text into target specified language
        if (SwiftGoogleTranslate.shared.targetLanguageCode == "en")
        {
            self.translateText = identifierString
        }
        else{
            SwiftGoogleTranslate.shared.translate (identifierString, SwiftGoogleTranslate.shared.targetLanguageCode, "en") { (text, error) in
                if text==nil
                {
                    self.translateText = "Translation error"
                    
                }
                else
                {
                    self.translateText = text!
                }
            
            }
        }
        DispatchQueue.main.async { [weak self] in
                self?.displayClassifierResults()
        }
        
    }
    
    // Show the classification results in the UI.
    private func displayClassifierResults() {
        guard !self.identifierString.isEmpty else {
            return // No object was classified.
        }
        
        //Output message with object name and confidence
        let message = String(format: "Detected \(translateText) with %.2f", self.confidence * 100) + "% confidence"
        statusViewController.showMessage(message)
    }
    
    /*      //Output message with object name and confidence
     
    if confidence < .6
     {
     
    let message = String (format: "Which of these is the best choice?", self.confidence * 100) + "% confidence"
    statusViewController.showMessage(message)
     
     
     }


     */
    
    // MARK: - Tap gesture handler & ARSKViewDelegate
    
    // Labels for classified objects by ARAnchor UUID
    private var anchorLabels = [UUID: String]()
    
    // When the user taps, add an anchor associated with the current classification result.
    /// - Tag: PlaceLabelAtLocation
    @IBAction func placeLabelAtLocation(sender: UITapGestureRecognizer) {
        let hitLocationInView = sender.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(hitLocationInView, types: [.featurePoint, .estimatedHorizontalPlane])
        if let result = hitTestResults.first {
            
            // Add a new anchor at the tap location.
            // S - result.worldTransform is the 4x4 sim coordinates of the object
            let anchor = ARAnchor(transform: result.worldTransform)
            sceneView.session.add(anchor: anchor)
            
// ---This is where object text is turned into anchor text---
            
            // Track anchor ID to associate text with the anchor after ARKit creates a corresponding SKNode.
            // S - Changed identifierString to translateText
            anchorLabels[anchor.identifier] = translateText
        }
    }
    
    // When an anchor is added, provide a SpriteKit node for it and set its text to the classification label.
    /// - Tag: UpdateARContent
    func view(_ view: ARSKView, didAdd node: SKNode, for anchor: ARAnchor) {
        guard let labelText = anchorLabels[anchor.identifier] else {
            fatalError("missing expected associated label for anchor")
        }
        
        let label = TemplateLabelNode(text: labelText)
        // S - Makes position of anchor text label node slightly higher than the touch point
        label.position = CGPoint(x: label.position.x, y: (label.position.y + 0.03))
        node.addChild(label)

    }
    
    //
    
    // MARK: - AR Session Handling
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
            // Unhide content after successful relocalization.
            setOverlaysHidden(false)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Filter out optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        setOverlaysHidden(true)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        /*
         Allow the session to attempt to resume after an interruption.
         This process may not succeed, so the app must be prepared
         to reset the session if the relocalizing status continues
         for a long time -- see `escalateFeedback` in `StatusViewController`.
         */
        return true
    }

    private func setOverlaysHidden(_ shouldHide: Bool) {
        sceneView.scene!.children.forEach { node in
            if shouldHide {
                // Hide overlay content immediately during relocalization.
                node.alpha = 0
            } else {
                // Fade overlay content in after relocalization succeeds.
                node.run(.fadeIn(withDuration: 0.5))
            }
        }
    }

    private func restartSession() {
        statusViewController.cancelAllScheduledMessages()
        statusViewController.showMessage("RESTARTING SESSION")

        anchorLabels = [UUID: String]()
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Error handling
    
    private func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.restartSession()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK:action
    @IBAction func unwindToARView(sender: UIStoryboardSegue) {
        
    }
    
    //MARK: private function
    //Add language to LanguageChoice array
    private func addLanguageChoice ()
    {
        if SwiftGoogleTranslate.shared.LanguageChoice.isEmpty {
            SwiftGoogleTranslate.shared.LanguageChoice.append(SwiftGoogleTranslate.Language(language: "en",name: "English"))
            SwiftGoogleTranslate.shared.LanguageChoice.append(SwiftGoogleTranslate.Language(language: "ar",name: "Arabic"))
            SwiftGoogleTranslate.shared.LanguageChoice.append(SwiftGoogleTranslate.Language(language: "zh",name: "Chinese"))
            SwiftGoogleTranslate.shared.LanguageChoice.append(SwiftGoogleTranslate.Language(language: "fr",name: "French"))
            SwiftGoogleTranslate.shared.LanguageChoice.append(SwiftGoogleTranslate.Language(language: "it",name: "Italian"))
            SwiftGoogleTranslate.shared.LanguageChoice.append(SwiftGoogleTranslate.Language(language: "es",name: "Spanish"))
        }
    }
    
    
    private func checkPreferLanguage (){
        let preferLanguage = defaults.value(forKey: "preferLanguage") as? String ?? "en"
        SwiftGoogleTranslate.shared.targetLanguageCode = preferLanguage
    }
    
    
}
