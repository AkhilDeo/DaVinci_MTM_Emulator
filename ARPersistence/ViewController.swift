/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit

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
            MyVariables.network = UDPClient(address: ip_address, port: 8080)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "PSMRight")
            self.present(nextViewController, animated:true, completion:nil)
        }
        
    }
    
    
    @IBAction func goToLeftController(_ sender: UIButton) {
        
        if ipAddressInput.text != "" && ip.isValidIPAddress(ipAddressInput.text!) {
            self.ip_address = ipAddressInput.text ?? "227.215.14.176"
            MyVariables.ip_address = self.ip_address
            MyVariables.network = UDPClient(address: ip_address, port: 8080)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "PSMLeft")
            self.present(nextViewController, animated:true, completion:nil)
        }
        
    }
    
}
