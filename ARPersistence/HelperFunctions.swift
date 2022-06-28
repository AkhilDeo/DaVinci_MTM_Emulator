//
//  HelperFunctions.swift
//  ARPersistence
//
//  Created by Akhil Deo on 6/27/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import ARKit

// for ecm,  joint 1 controls yaw, joint 2 controls pitch, joint 3 controls insertion, and joint 4 controls the roll
func sendCameraTransformation(_ priorCurValues: Dictionary<String, Float>, _ curValues: Dictionary<String, Float>) {
    
}

func clutchOffsetCalculation(_ lastValues: Dictionary<String, Float>, _ curValues: Dictionary<String, Float>) {
    MyVariables.clutchOffset["x"]! += (lastValues["x"]! - curValues["x"]!)
    MyVariables.clutchOffset["y"]! += (lastValues["y"]! - curValues["y"]!)
    MyVariables.clutchOffset["z"]! += (lastValues["z"]! - curValues["z"]!)
    MyVariables.clutchOffset["roll"]! += (lastValues["roll"]! - curValues["roll"]!)
    MyVariables.clutchOffset["pitch"]! += (lastValues["pitch"]! - curValues["pitch"]!)
    MyVariables.clutchOffset["yaw"]! += (lastValues["yaw"]! - curValues["yaw"]!)
}

func updateValues(_ session: ARSession, _ values: inout Dictionary<String, Float>) {
    values["x"] = (session.currentFrame?.camera.transform)!.columns.3.x
    values["y"] = (session.currentFrame?.camera.transform)!.columns.3.y
    values["z"] = (session.currentFrame?.camera.transform)!.columns.3.z
    values["roll"] = (session.currentFrame?.camera.eulerAngles)!.z
    values["pitch"] = (session.currentFrame?.camera.eulerAngles)!.x
    values["yaw"] = (session.currentFrame?.camera.eulerAngles)!.y
}
