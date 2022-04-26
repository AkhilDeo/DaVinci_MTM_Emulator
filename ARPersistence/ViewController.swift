/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit

class PSMRight: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var snapshotThumbnail: UIImageView!
    @IBOutlet weak var gripperSlider: UISlider!
    @IBOutlet weak var gripperValLabel: UILabel!
    @IBOutlet weak var cameraButton: RoundedButton!
    var network: UDPClient
    var ip_address: String

    
    init(ip_address: String) {
        //cv = ContentView()
       // self.ip_address = ip_address
        self.ip_address = MyVariables.ip_address
        network = UDPClient(address: ip_address, port: 8080)!
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        //cv = ContentView()
        self.ip_address = MyVariables.ip_address
        print(ip_address)
        network = UDPClient(address: ip_address, port: 8080)!
       super.init(coder: aDecoder)
    }
    
    // MARK: - View Life Cycle
    
    // Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        gripperSlider.transform = CGAffineTransform(rotationAngle: (CGFloat.pi / -2))
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Start the view's AR session.
        sceneView.session.delegate = self
        sceneView.session.run(defaultConfiguration)
        
        sceneView.debugOptions = [ .showFeaturePoints ]
        //network = UDPClient(address: cv.ip_address, port: 8080)!

        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    

    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    func printTransformationRight(_ session: ARSession) {
        let currentTransform = session.currentFrame?.camera.transform
        let x = currentTransform!.columns.3.x
        let y = currentTransform!.columns.3.y
        let z = currentTransform!.columns.3.z
        print("x: \(String(describing: x))")
        print("y: \(String(describing: y))")
        print("z: \(String(describing: z))")
        let currentAngles = session.currentFrame?.camera.eulerAngles
        let pitch = currentAngles!.x
        let yaw = currentAngles!.y
        let roll = currentAngles!.z
        print("roll: \(String(describing: roll))")
        print("pitch: \(String(describing: pitch))")
        print("yaw: \(String(describing: yaw))")
    }
    
    func sendTransformationRight(_ session: ARSession) {
        //let network = UDPClient(address: cv.ip_address, port: 8080)
        let currentTransform = session.currentFrame?.camera.transform
        //let network2 = UDPClient(address: cv.ip_address, port: 8080)!

        // Variables
        let x = currentTransform!.columns.3.x
        let y = currentTransform!.columns.3.y
        let z = currentTransform!.columns.3.z
        let currentAngles = session.currentFrame?.camera.eulerAngles
        let pitch = currentAngles!.x
        let yaw = currentAngles!.y
        let roll = currentAngles!.z
        let gripSlide = gripperSlider.value

        
        let xString: String = "x: \(String(describing: x))"
        let yString: String = " y: \(String(describing: y))"
        let zString: String = " z: \(String(describing: z))"
        let rollString: String = " roll: \(String(describing: roll))"
        let pitchString: String = " pitch: \(String(describing: pitch))"
        let yawString: String = " yaw: \(String(describing: yaw))"
        let sliderString: String = " slider:  \(String(describing: gripSlide))"

            // Put your code which should be executed with a delay here
        let sendTransform: String = xString + yString + zString + rollString + pitchString + yawString + sliderString
        self.network.send(sendTransform.data(using: .utf8)!)

        
    }

    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed
        switch frame.worldMappingStatus {
        case .extending, .mapped:
          //  saveExperienceButton.isEnabled = true
            printTransformationRight(session)
            sendTransformationRight(session)
        default:
            //saveExperienceButton.isEnabled = false
            print("No idea what to do")

        }
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """
        gripperValLabel.text = ("Gripper Value: \(String(describing: round(gripperSlider.value * 1000) / 10) + "%")")
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking(nil)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    // MARK: - Persistence: Saving and Loading
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    

    // Called opportunistically to verify that map data can be loaded from filesystem.
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    


    // MARK: - AR session management
    
    var isRelocalizingMap = false

    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    @IBAction func resetTracking(_ sender: UIButton?) {
        sceneView.session.run(defaultConfiguration, options: [.resetTracking, .removeExistingAnchors])
        isRelocalizingMap = false
    }
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        snapshotThumbnail.isHidden = true
        switch (trackingState, frame.worldMappingStatus) {
        case (.normal, .mapped),
             (.normal, .extending):
            message = "Mapped or Extending"
            
        case (.normal, _) where mapDataFromFile != nil && !isRelocalizingMap:
            message = "Move around to map the environment"
//        case (.normal, _) where mapDataFromFile == nil:
//            message = "Move around to map the environment."
//
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            snapshotThumbnail.isHidden = false
            
        default:
            message = trackingState.localizedFeedback
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    // MARK: - Placing AR Content
    
    /// - Tag: PlaceObject
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        // Disable placing objects when the session is still relocalizing
            return
        
    }

}

class PSMLeft: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var snapshotThumbnail: UIImageView!
    @IBOutlet weak var gripperSlider: UISlider!
    @IBOutlet weak var gripperValLabel: UILabel!
    @IBOutlet weak var clutchButton: RoundedButton!
    // MARK: - View Life Cycle

    
    // Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Hack to wait until everything is set up
        gripperSlider.transform = CGAffineTransform(rotationAngle: (CGFloat.pi / -2))
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Start the view's AR session.
        sceneView.session.delegate = self
        sceneView.session.run(defaultConfiguration)
        
        sceneView.debugOptions = [ .showFeaturePoints ]

        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    

    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    func printTransformation(_ session: ARSession) {
        let currentTransform = session.currentFrame?.camera.transform
        let x = currentTransform?.columns.3.x
        let y = currentTransform?.columns.3.y
        let z = currentTransform?.columns.3.z
        print("x: \(String(describing: x))")
        print("y: \(String(describing: y))")
        print("z: \(String(describing: z))")
        let currentAngles = session.currentFrame?.camera.eulerAngles
        let pitch = currentAngles?.x
        let yaw = currentAngles?.y
        let roll = currentAngles?.z
        print("roll: \(String(describing: roll))")
        print("pitch: \(String(describing: pitch))")
        print("yaw: \(String(describing: yaw))")
    }
    
    
    func sendTransformation(_ session: ARSession) {
       // let cv = ContentView()
        //let network = UDPClient(address: cv.ip_address, port: 8080)
        let currentTransform = session.currentFrame?.camera.transform
        
        // Variables
        let x = currentTransform?.columns.3.x
        let y = currentTransform?.columns.3.y
        let z = currentTransform?.columns.3.z
        let currentAngles = session.currentFrame?.camera.eulerAngles
        let pitch = currentAngles?.x
        let yaw = currentAngles?.y
        let roll = currentAngles?.z
        
        let xString = "x: \(String(describing: x))"
        let yString = " y: \(String(describing: y))"
        let zString = " z: \(String(describing: z))"
        let rollString = " roll: \(String(describing: roll))"
        let pitchString = " pitch: \(String(describing: pitch))"
        let yawString = " yaw: \(String(describing: yaw))"

            // Put your code which should be executed with a delay here
            let sendTransform = xString + yString + zString + rollString + pitchString + yawString
        //network?.send(sendTransform.data(using: .utf8)!)
        //network?.close()

        
    }

    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed

        switch frame.worldMappingStatus {
        case .extending, .mapped:
          //  saveExperienceButton.isEnabled = true
            printTransformation(session)
            sendTransformation(session)
            
        default:
            //saveExperienceButton.isEnabled = false
            //print("")
            print("Map not good rn")

        }
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """
        gripperValLabel.text = ("Gripper Value: \(String(describing: round(gripperSlider.value * 1000) / 10) + "%")")
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    @available(iOS 13.0, *)
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking(nil)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }

    // MARK: - AR session management
    
    var isRelocalizingMap = false

    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.isCollaborationEnabled = true
        }
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    @IBAction func resetTracking(_ sender: UIButton?) {
        sceneView.session.run(defaultConfiguration, options: [.resetTracking, .removeExistingAnchors])
        isRelocalizingMap = false
    }
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        snapshotThumbnail.isHidden = true
        switch (trackingState, frame.worldMappingStatus) {
        case (.normal, .mapped),
             (.normal, .extending):
            message = "Mapped or Extending"
            
        case (.normal, _) where !isRelocalizingMap:
            message = "Move around to map the environment"
            
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            message = "Move your device to location shown in image."
            snapshotThumbnail.isHidden = false
            
        default:
            message = trackingState.localizedFeedback
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    // MARK: - Placing AR Content
    
    /// - Tag: PlaceObject
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        // Disable placing objects when the session is still relocalizing
            return
        
    }

}

struct MyVariables {
    static var ip_address = "0.0.0.0"
}

class ContentView: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    var ip_address: String
    @IBOutlet weak var ipAddressInput: UITextField!
    @IBOutlet weak var leftPSMControllerButton: UIButton!
    @IBOutlet weak var rightPSMControllerButton: UIButton!
    var network: UDPClient = UDPClient(address: "227.215.14.176", port: 8080)!
    var ip: ValidIPAddress = ValidIPAddress()
    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)


    
    init() {
        self.ip_address = ""
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.ip_address = "227.215.14.176"
       super.init(coder: aDecoder)
    }
    
    @IBAction func goToRightController(_ sender: UIButton) {
        
        if ipAddressInput.text != "" && ip.isValidIPAddress(ipAddressInput.text!) {
            self.ip_address = ipAddressInput.text ?? "227.215.14.176"
            MyVariables.ip_address = self.ip_address
            let psmright = PSMRight(ip_address: ip_address)
            psmright.ip_address = ip_address
            psmright.network = UDPClient(address: ip_address, port: 8081)!
            psmright.network.send("Data".data(using: .utf8)!)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "PSMRight")
            self.present(nextViewController, animated:true, completion:nil)
        }
        
    }
    
    
    @IBAction func goToLeftController(_ sender: UIButton) {
        if ipAddressInput.text != "" && ip.isValidIPAddress(ipAddressInput.text!) {
            ip_address = ipAddressInput.text!
            network.send("Hello World".data(using: .utf8)!)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "PSMLeft")
            self.present(nextViewController, animated:true, completion:nil)
        }
    }
    
}
