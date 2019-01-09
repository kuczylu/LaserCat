//
//  ViewController.swift
//  LaserCat
//
//  Created by Lukas Kuczynski on 1/3/19.
//  Copyright © 2019 Lukas Kuczynski. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation


class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    var audioPlayer : AVAudioPlayer?
    var offsetPositions = simd_float3(0.0, 0.0, 0.0)
    var offsetAngles = simd_float3(0.0, 0.0, 0.0)
    var sessionStateMessage = "Initializing.. Tap here for info"
    var isShowingInfo = false
    
    let cmToM : Float = 0.01
    let valueLabelFormat = "%.1f"
    let angleOrder = "YXZ"
    let landscapeToPortrait = simd_float3x3(rows: [float3(0.0, -1.0, 0.0),
                                                   float3(1.0, 0.0, 0.0),
                                                   float3(0.0, 0.0, 1.0)]) // 90 degree rotation abt z

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var sessionInfoView: UIVisualEffectView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var valuesView: UIVisualEffectView!
    @IBOutlet weak var valueLabelX: UILabel!
    @IBOutlet weak var valueLabelY: UILabel!
    @IBOutlet weak var valueLabelZ: UILabel!
    @IBOutlet weak var valueLabelPan: UILabel!
    @IBOutlet weak var valueLabelTilt: UILabel!
    @IBOutlet weak var stepperX: UIStepper!
    @IBOutlet weak var stepperY: UIStepper!
    @IBOutlet weak var stepperZ: UIStepper!
    @IBOutlet weak var stepperPan: UIStepper!
    @IBOutlet weak var stepperTilt: UIStepper!
    
    
    @IBAction func toggleValuesButtonClicked(_ sender: UIButton) {
        valuesView.isHidden.toggle()
        
        if valuesView.isHidden {
            sender.setTitle("show values", for: .normal)
        } else {
            sender.setTitle("hide values", for: .normal)
        }
    }
    
    @IBAction func resetButtonClicked() {
        resetTracking()
    }
    
    @IBAction func clearButtonClicked() {

        offsetPositions = simd_float3(0.0, 0.0, 0.0)
        offsetAngles = simd_float3(0.0, 0.0, 0.0)
        
        stepperX.value = Double(offsetPositions.x)
        stepperY.value = Double(offsetPositions.y)
        stepperZ.value = Double(offsetPositions.z)
        stepperPan.value = Double(offsetAngles.y)
        stepperTilt.value = Double(offsetAngles.x)
        
        valueLabelX.text = String(format: valueLabelFormat, offsetPositions.x)
        valueLabelY.text = String(format: valueLabelFormat, offsetPositions.y)
        valueLabelZ.text = String(format: valueLabelFormat, offsetPositions.z)
        valueLabelPan.text = String(format: valueLabelFormat, offsetAngles.y)
        valueLabelTilt.text = String(format: valueLabelFormat, offsetAngles.x)
    }
    
    @IBAction func stepperValueChangedX(_ sender: UIStepper) {
        offsetPositions.x = Float(sender.value)
        valueLabelX.text = String(format: valueLabelFormat, offsetPositions.x)
    }
    
    @IBAction func stepperValueChangedY(_ sender: UIStepper) {
        offsetPositions.y = Float(sender.value)
        valueLabelY.text = String(format: valueLabelFormat, offsetPositions.y)
    }
    
    @IBAction func stepperValueChangedZ(_ sender: UIStepper) {
        offsetPositions.z = Float(sender.value)
        valueLabelZ.text = String(format: valueLabelFormat, offsetPositions.z)
    }
    
    @IBAction func stepperValueChangedPan(_ sender: UIStepper) {
        offsetAngles.y = Float(sender.value)
        valueLabelPan.text = String(format: valueLabelFormat, offsetAngles.y)
    }
    
    @IBAction func stepperValueChangedTilt(_ sender: UIStepper) {
        offsetAngles.x = Float(sender.value)
        valueLabelTilt.text = String(format: valueLabelFormat, offsetAngles.x)
    }
    
    @IBAction func tapView(_ gestureRecognizer : UITapGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        if gestureRecognizer.state == .ended {
            shootCatLaser()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("ARKit is not supported on this device")
        }
        
        // add tap capability to sessionInfoView
        let gesture = UITapGestureRecognizer(target: self, action: #selector(sessionInfoViewClicked))
        sessionInfoView.addGestureRecognizer(gesture)
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [.showFeaturePoints]
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    

    // MARK: - ARSessionDelegate
    
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionState(for: frame, trackingState: frame.camera.trackingState)
        updateSessionInfoLabel()
    }
    
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionState(for: frame, trackingState: frame.camera.trackingState)
        updateSessionInfoLabel()
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionState(for: session.currentFrame!, trackingState: camera.trackingState)
        updateSessionInfoLabel()
    }
    
    
    // MARK: ARSessionObserver
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionStateMessage = "Session failed: \(error.localizedDescription)"
        updateSessionInfoLabel()
        resetTracking()
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        sessionStateMessage = "Session was interrupted"
        updateSessionInfoLabel()
    }
    
    
    func sessionInterruptionEnded(_ session: ARSession) {
        sessionStateMessage = "Session interruption ended"
        updateSessionInfoLabel()
        resetTracking()
    }
    
    
    private func updateSessionState(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            sessionStateMessage = "Tap anywhere to lasercat! Tap here for info."
        case .notAvailable:
            sessionStateMessage = "Tracking unavailable. Tap here for info."
        case .limited(.excessiveMotion):
            sessionStateMessage = "Tracking limited - Move device more slowly. Tap here for info."
        case .limited(.insufficientFeatures):
            sessionStateMessage = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions. Tap here for info."
        case .limited(.initializing):
            sessionStateMessage = "Initializing AR session. Tap here for info."
        default:
            sessionStateMessage = "Tap here for info."
        }
    }

    
    private func updateSessionInfoLabel() {
        
        let infoMessage = "Welcome to LaserCat! Shoot catlasers at surfaces by tapping anywhere. Cats will stick when they intersect an area with enough feature points (orange dots). Change where the laser shoots from by clicking 'show values' and editing the offset values. The offset values are relative to the device camera. Delete cats and reset the tracking session by pressing 'reset'. Tap this message to return to LaserCat!"
        
        if isShowingInfo {
            sessionInfoLabel.text = infoMessage
        } else {
            sessionInfoLabel.text = sessionStateMessage
        }
    }
    
    
    @objc private func sessionInfoViewClicked() {
        isShowingInfo.toggle()
        updateSessionInfoLabel()
    }
    
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // remove cat nodes
        while let node = sceneView.scene.rootNode.childNode(withName: "cat", recursively: false) {
            node.removeFromParentNode()
        }
    }
    
    
    private func shootCatLaser() {
        
        guard let frame = sceneView.session.currentFrame else { return }
        
        // get camera position and orientation w.r.t world coordinate system
        let transform = frame.camera.transform
        let devicePosition = getPosition(transform)
        let deviceOrientation = getRotation(transform)
        
        // offset is specified in the device reference frame in meters
        // offset must be rotated into the world refrence frame before being added to the device position
        let offset = cmToM * landscapeToPortrait * offsetPositions
        let laserPosition = devicePosition + deviceOrientation * offset
        
        // offset is specified in the device reference frame in degrees
        let anglesOffset = landscapeToPortrait.transpose * offsetAngles
        let offsetRotation = getMatrixFromAngles(anglesOffset, angleOrder)
        let laserOrientation = deviceOrientation * offsetRotation.transpose
        let laserOrientationInv = laserOrientation.transpose
        
        
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else { return }
            
            let hitRadiusMin: Float = 0.02 // meters
            var laserDepthMax : Float = 0.0
            var hasSurface = false
            
            for worldPoint in map.rawFeaturePoints.points {
                let laserPoint = laserOrientationInv * (worldPoint - laserPosition)
                if (abs(laserPoint.x) < hitRadiusMin) && (abs(laserPoint.y) < hitRadiusMin)
                {
                    // more negative in z is deeper
                    if laserPoint.z < laserDepthMax {
                        laserDepthMax = laserPoint.z
                        hasSurface = true
                    }
                }
            }
            
            if(hasSurface) {
                let laserFwd = laserOrientation.columns.2
                let catNodePosition = laserPosition + laserDepthMax * laserFwd
                let catNodeRotation = laserOrientation * self.landscapeToPortrait
                let catNodeTransform = SCNMatrix4.init(self.getTransform(catNodePosition, catNodeRotation))
                
                let node = CatNode(catNodeTransform, abs(laserDepthMax))
                self.sceneView.scene.rootNode.addChildNode(node)
                
                self.playCatSound()
            }
        }
    }
    
    
    private func playCatSound() {
        
        let index = Int.random(in: 1...5)
        let resourceStr = "Sounds/catNoise" + String(index) + ".m4a"
        
        guard let path = Bundle.main.path(forResource: resourceStr, ofType: nil) else {
            print("Error creating sound file path for ", resourceStr)
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Unable to load sound file: ", url)
        }
    }
    
    
    // Utilities
    
    
    private func getRotation(_ transform: simd_float4x4) -> simd_float3x3 {
        let rotRow0 = simd_float3(x: transform.columns.0[0], y: transform.columns.1[0], z: transform.columns.2[0])
        let rotRow1 = simd_float3(x: transform.columns.0[1], y: transform.columns.1[1], z: transform.columns.2[1])
        let rotRow2 = simd_float3(x: transform.columns.0[2], y: transform.columns.1[2], z: transform.columns.2[2])
        let rotation = simd_float3x3(rows: [rotRow0, rotRow1, rotRow2])
        
        return rotation
    }
    
    
    private func getPosition(_ transform: simd_float4x4) -> simd_float3 {
        let position = simd_float3(x: transform.columns.3[0], y: transform.columns.3[1], z: transform.columns.3[2])
        
        return position
    }
    
    
    private func getMatrixFromAngles(_ angles: simd_float3, _ order: String) -> simd_float3x3 {
        
        var matrix = simd_float3x3(1.0)
        let anglesRad = degToRad(angles)
        
        let rotX = simd_float3x3(rows: [float3(1.0, 0.0, 0.0),
                                        float3(0.0, cos(anglesRad.x), -sin(anglesRad.x)),
                                        float3(0.0, sin(anglesRad.x), cos(anglesRad.x))])
        
        let rotY = simd_float3x3(rows: [float3(cos(anglesRad.y), 0.0, sin(anglesRad.y)),
                                        float3(0.0, 1.0, 0.0),
                                        float3(-sin(anglesRad.y), 0.0, cos(anglesRad.y))])
        
        let rotZ = simd_float3x3(rows: [float3(cos(anglesRad.z), -sin(anglesRad.z), 0.0),
                                        float3(sin(anglesRad.z), cos(anglesRad.z), 0.0),
                                        float3(0.0, 0.0, 1.0),])
        switch order {
        case "XYZ":
            matrix = rotX * rotY * rotZ
        case "XZY":
            matrix = rotX * rotZ * rotY
        case "YXZ":
            matrix = rotY * rotX * rotZ
        case "YZX":
            matrix = rotY * rotZ * rotX
        case "ZXY":
            matrix = rotZ * rotX * rotY
        case "ZYX":
            matrix = rotZ * rotY * rotX
        default:
            print("Invalid rotation order in getMatrixFromAngles()")
        }
        
        
        return matrix
    }
    
    
    private func radToDeg(_ vec: simd_float3) -> simd_float3 {
        return (180.0 / .pi) * vec
    }
    
    
    private func degToRad(_ vec: simd_float3) -> simd_float3 {
        return (.pi / 180.0) * vec
    }
    
    
    private func getTransform(_ position: simd_float3, _ rotation: simd_float3x3) -> simd_float4x4 {
        var transform = simd_float4x4(1.0)
        
        transform.columns.0[0] = rotation.columns.0[0]
        transform.columns.0[1] = rotation.columns.0[1]
        transform.columns.0[2] = rotation.columns.0[2]
        
        transform.columns.1[0] = rotation.columns.1[0]
        transform.columns.1[1] = rotation.columns.1[1]
        transform.columns.1[2] = rotation.columns.1[2]
        
        transform.columns.2[0] = rotation.columns.2[0]
        transform.columns.2[1] = rotation.columns.2[1]
        transform.columns.2[2] = rotation.columns.2[2]

        
        transform.columns.3[0] = position.x
        transform.columns.3[1] = position.y
        transform.columns.3[2] = position.z
        
        return transform
    }
}
