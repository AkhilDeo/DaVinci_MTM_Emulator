//
//  MyVariables.swift
//  ARPersistence
//
//  Created by Akhil Deo on 6/21/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

struct MyVariables {
    static var ip_address = "0.0.0.0"
    static var network: UDPClient? = nil
        
    // for ecm,  joint 1 controls yaw, joint 2 controls pitch, joint 3 controls insertion, and joint 4 controls the roll
    static var camera_jp: Array<Float> = [0.0, 0.0, 0.0, 0.0]
    static var clutchOffset: Dictionary<String, Float> = ["x": 0.0,
                                                          "y": 0.0,
                                                           "z": 0.0,
                                                          "roll": 0.0,
                                                          "pitch": 0.0,
                                                          "yaw": 0.0 ]
}
