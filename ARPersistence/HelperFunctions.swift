//
//  HelperFunctions.swift
//  ARPersistence
//
//  Created by Akhil Deo on 6/27/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import ARKit

var yawString: String = ""
var pitchString: String = ""
var insertString: String = ""
var rollString: String = ""
var insertVal: Float = 0.0
let cameraString: String = " \"camera\": \"true\"}"
var ip_address = "0.0.0.0"
var network: UDPClient? = nil
var camera_jp: Array<Float> = [0.0, 0.0, 0.0, 0.0]
var clutchOffset: Dictionary<String, Float> = ["x": 0.0,
                                                      "y": 0.0,
                                                       "z": 0.0,
                                                      "roll": 0.0,
                                                      "pitch": 0.0,
                                                      "yaw": 0.0 ]

// for ecm,  joint 1 controls yaw, joint 2 controls pitch, joint 3 controls inser3tion, and joint 4 controls the roll
func sendCameraTransformation(_ priorCurValues: Dictionary<String, Float>, _ curValues: Dictionary<String, Float>) {
    if (anglePermissible(priorCurValues, curValues)) {
        camera_jp[0] += (curValues["yaw"]! - priorCurValues["yaw"]!)
        camera_jp[1] += (curValues["pitch"]! - priorCurValues["pitch"]!)
        camera_jp[2] += distance(priorCurValues, curValues)
        camera_jp[3] += (curValues["roll"]! - priorCurValues["roll"]!)
        
        rollString = "{\"roll\": \(String(describing: camera_jp[3])),"
        pitchString = " \"pitch\": \(String(describing: camera_jp[1])),"
        yawString = " \"yaw\": \(String(describing: camera_jp[0])),"
        insertString = " \"insert\": \(String(describing: camera_jp[2])),"
        network!.send((rollString + pitchString + yawString + insertString + cameraString).data(using: .utf8)!)
    }
    
}

func anglePermissible(_ priorCurValues: Dictionary<String, Float>, _ curValues: Dictionary<String, Float>)  -> Bool {
    let xDist = curValues["x"]! - priorCurValues["x"]!
    let yDist = curValues["y"]! - priorCurValues["y"]!
    let zDist = curValues["z"]! - priorCurValues["z"]!
    if (abs(xDist) > 2 * abs(zDist) || abs(yDist) > 2 * abs(zDist)) {
        return false
    }
    return true
}

func distance(_ priorCurValues: Dictionary<String, Float>, _ curValues: Dictionary<String, Float>) -> Float {
    let xDist = curValues["x"]! - priorCurValues["x"]!
    let yDist = curValues["y"]! - priorCurValues["y"]!
    let zDist = curValues["z"]! - priorCurValues["z"]!
    let dist = sqrt(xDist * xDist + yDist * yDist + zDist * zDist)
    return zDist > 0 ? dist : -1 * dist
}

func clutchOffsetCalculation(_ lastValues: Dictionary<String, Float>, _ curValues: Dictionary<String, Float>) {
    clutchOffset["x"]! += (lastValues["x"]! - curValues["x"]!)
    clutchOffset["y"]! += (lastValues["y"]! - curValues["y"]!)
    clutchOffset["z"]! += (lastValues["z"]! - curValues["z"]!)
    clutchOffset["roll"]! += (lastValues["roll"]! - curValues["roll"]!)
    clutchOffset["pitch"]! += (lastValues["pitch"]! - curValues["pitch"]!)
    clutchOffset["yaw"]! += (lastValues["yaw"]! - curValues["yaw"]!)
}

func updateValues(_ session: ARSession, _ values: inout Dictionary<String, Float>) {
    values["x"] = (session.currentFrame?.camera.transform)!.columns.3.x
    values["y"] = (session.currentFrame?.camera.transform)!.columns.3.y
    values["z"] = (session.currentFrame?.camera.transform)!.columns.3.z
    values["roll"] = (session.currentFrame?.camera.eulerAngles)!.z
    values["pitch"] = (session.currentFrame?.camera.eulerAngles)!.x
    values["yaw"] = (session.currentFrame?.camera.eulerAngles)!.y
}
