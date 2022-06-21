//
//  PSMRight.swift
//  ARPersistence
//
//  Created by Akhil Deo on 6/21/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
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
    var isCameraBtnPressed: Bool
    var network: UDPClient
    var ip_address: String
    var sendTransform: String
    var stringDict: Dictionary<String, String>
    
    @IBAction func cameraBtnPressed(_ sender: Any) {
        isCameraBtnPressed = true
    }
    
    @IBAction func cameraBtnReleased(_ sender: Any) {
        isCameraBtnPressed = false
    }
    
    init(ip_address: String) {
        self.ip_address = MyVariables.ip_address
        network = UDPClient(address: ip_address, port: 8080)!
        isCameraBtnPressed = false
        sendTransform = ""
        stringDict = ["x": "",
                      "y": "",
                      "z": "",
                      "roll": "",
                      "pitch": "",
                      "yaw": "",
                      "slider": "",
                      "cameraBtn": "",
                      "arm": ""]
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.ip_address = MyVariables.ip_address
        print(ip_address)
        network = UDPClient(address: ip_address, port: 8080)!
        isCameraBtnPressed = false
        sendTransform = ""
        stringDict = ["x": "",
                      "y": "",
                      "z": "",
                      "roll": "",
                      "pitch": "",
                      "yaw": "",
                      "slider": "",
                      "cameraBtn": "",
                      "arm": ""]
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
        if (MyVariables.sceneViewExists == false) {
            // Start the view's AR session.
            sceneView.session.delegate = self
            sceneView.session.run(defaultConfiguration)
            
            sceneView.debugOptions = [ .showFeaturePoints ]
        } else {
            sceneView = MyVariables.sceneView
        }
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MyVariables.sceneView = sceneView
        if (MyVariables.sceneViewExists == false) {
            MyVariables.sceneViewExists = true
        }
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    
    // MARK: - transferring/printing world (xyz rpm) values
    
    //Only for debugging
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
        stringDict["x"] = "{\"x\": \(String(describing: (session.currentFrame?.camera.transform)!.columns.3.x)),"
        stringDict["y"] = " \"y\": \(String(describing: (session.currentFrame?.camera.transform)!.columns.3.y)),"
        stringDict["z"] = " \"z\": \(String(describing: (session.currentFrame?.camera.transform)!.columns.3.z)),"
        stringDict["roll"] = " \"roll\": \(String(describing: (session.currentFrame?.camera.eulerAngles)!.z)),"
        stringDict["pitch"] = " \"pitch\": \(String(describing: (session.currentFrame?.camera.eulerAngles)!.x)),"
        stringDict["yaw"] = " \"yaw\": \(String(describing: (session.currentFrame?.camera.eulerAngles)!.y)),"
        stringDict["slider"] = " \"slider\": \(String(describing: gripperSlider.value)),"
        stringDict["cameraBtn"] = " \"cameraBtn\": \(String(describing: isCameraBtnPressed))}"
        sendTransform = (stringDict["x"]! + stringDict["y"]! + stringDict["z"]! + stringDict["roll"]! + stringDict["pitch"]! + stringDict["yaw"]! + stringDict["slider"]! + stringDict["cameraBtn"]!)
//        print(sendTransform)
        self.network.send(sendTransform.data(using: .utf8)!)

        
    }
    
    func sendTransformationSliderRight(_ session: ARSession) {
        self.network.send("{\"slider\":  \(String(describing: gripperSlider.value))}".data(using: .utf8)!)

    }

    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed
        switch frame.worldMappingStatus {
        case .extending, .mapped:
          //  saveExperienceButton.isEnabled = true
            //printTransformationRight(session)
            sendTransformationRight(session)
        default:
            //saveExperienceButton.isEnabled = false
            sendTransformationSliderRight(session)

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
            
        case (.normal, _) where !isRelocalizingMap:
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

}
