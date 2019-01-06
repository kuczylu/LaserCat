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
    
    var offsetX = 0.0
    var offsetY = 0.0
    var offsetZ = 0.0
    var offsetPan = 0.0
    var offsetTilt = 0.0

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var sessionInfoView: UIVisualEffectView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var valuesView: UIVisualEffectView!
    @IBOutlet weak var valueLabelX: UILabel!
    @IBOutlet weak var valueLabelY: UILabel!
    @IBOutlet weak var valueLabelZ: UILabel!
    @IBOutlet weak var valueLabelPan: UILabel!
    @IBOutlet weak var valueLabelTilt: UILabel!
    
    
    @IBAction func toggleValuesButtonClicked(_ sender: UIButton) {
        let isHidden = !valuesView.isHidden
        valuesView.isHidden = isHidden
        
        if isHidden {
            sender.setTitle("show values", for: .normal)
        } else {
            sender.setTitle("hide values", for: .normal)
        }
    }
    
    
    @IBAction func resetButtonClicked() {
        resetTracking()
    }
    
    @IBAction func stepperValueChangedX(_ sender: UIStepper) {
        offsetX = sender.value
        valueLabelX.text = String(format: "%.1f", offsetX)
    }
    
    @IBAction func stepperValueChangedY(_ sender: UIStepper) {
        offsetY = sender.value
        valueLabelY.text = String(format: "%.1f", offsetY)
    }
    
    @IBAction func stepperValueChangedZ(_ sender: UIStepper) {
        offsetZ = sender.value
        valueLabelZ.text = String(format: "%.1f", offsetZ)
    }
    
    @IBAction func stepperValueChangedPan(_ sender: UIStepper) {
        offsetPan = sender.value
        valueLabelPan.text = String(format: "%.1f", offsetPan)
    }
    
    @IBAction func stepperValueChangedTilt(_ sender: UIStepper) {
        offsetTilt = sender.value
        valueLabelTilt.text = String(format: "%.1f", offsetTilt)
    }
    
    @IBAction func tapView(_ gestureRecognizer : UITapGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        if gestureRecognizer.state == .ended {
            hitTest()
            //shootLaser()
            //checkPoints()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("ARKit is not supported on this device")
        }
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
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
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
    
    
    // MARK: ARSessionObserver
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    
    func sessionInterruptionEnded(_ session: ARSession) {
        sessionInfoLabel.text = "Session interruption ended"
        resetTracking()
    }
    
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            message = "Tap anywhere to lasercat!"
        case .notAvailable:
            message = "Tracking unavailable."
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move device more slowly."
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
        case .limited(.initializing):
            message = "Initializing AR session."
        default:
            message = ""
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }

    
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // remove laser nodes
        while let node = sceneView.scene.rootNode.childNode(withName: "laser", recursively: false) {
            node.removeFromParentNode()
        }
    }
    
    
    private func shootLaser() {
        
        guard let frame = sceneView.session.currentFrame else { return }

        // get camera position and orientation w.r.t world coordinate system
        let transform = frame.camera.transform
        let devicePosition = getPosition(transform)
        let deviceOrientation = getRotation(transform)
        
        // offset is specified in the device reference frame in meters
        // offset must be rotated into the world refrence frame before being added to the device position
        let offset = simd_float3(x: Float(0.01 * offsetX), y: Float(0.01 * offsetY), z: Float(0.01 * offsetZ))
        let laserPosition = devicePosition + deviceOrientation * offset
        
        // offset is specified in the device reference frame in degrees
        let anglesOffset = simd_float3(Float(offsetTilt), Float(offsetPan), 0.0)
        let offsetRotation = getMatrixFromAngles(anglesOffset, "YXZ")
        let laserOrientation = deviceOrientation * offsetRotation.transpose
        
        let laserFwd : simd_float3 = -laserOrientation.columns.2
        let laserLength : Float = 2.0 //meters
        let laserMidPoint = laserPosition + (laserLength / 2.0) * laserFwd
        
        
        let cylinder = SCNCylinder(radius: 0.01, height: CGFloat(laserLength))
        cylinder.radialSegmentCount = 8
        let node = SCNNode(geometry: cylinder)
        let nodeRotation = simd_float3x3(columns: (laserOrientation.columns.1, laserOrientation.columns.2, laserOrientation.columns.0)) // change this to be more transparent
        node.transform = SCNMatrix4.init(getTransform(laserMidPoint, nodeRotation))
        node.name = "laser"
        
        sceneView.scene.rootNode.addChildNode(node)
        //let systemSoundID: SystemSoundID = 1016
        //AudioServicesPlaySystemSound(systemSoundID)
    }
    
    
    private func getRotation(_ transform: simd_float4x4) -> simd_float3x3 {
        let rotRow0 = simd_float3(x: transform.columns.0[0], y: transform.columns.1[0], z: transform.columns.2[0])
        let rotRow1 = simd_float3(x: transform.columns.0[1], y: transform.columns.1[1], z: transform.columns.2[1])
        let rotRow2 = simd_float3(x: transform.columns.0[2], y: transform.columns.1[2], z: transform.columns.2[2])
        let deviceOrientation = simd_float3x3(rows: [rotRow0, rotRow1, rotRow2])
        
        return deviceOrientation
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
        
        if(order == "YXZ")
        {
            matrix = rotZ * rotX * rotY
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
    
    private func checkPoints() {
        guard let frame = sceneView.session.currentFrame else { return }
        
        guard let rawPoints = frame.rawFeaturePoints else { return }
        
        print("Points Count: ", rawPoints.points.count)
        
        var status = ""
        switch frame.worldMappingStatus {
        case .notAvailable:
            status = "not available"
        case .limited:
            status = "limited"
        case .extending:
            status = "extending"
        case .mapped:
            status = "mapped"
        default:
            status = "unknown"
        }
        
        print("World mapping status is ", status)
        
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else { return }
            
            print("Total Points: ", map.rawFeaturePoints.points.count)
        }
    }
    
    private func hitTest() {
        guard let frame = sceneView.session.currentFrame else { return }
        
        let result = frame.hitTest(CGPoint(x: 0.5, y: 0.5), types: [.featurePoint, .estimatedHorizontalPlane, .estimatedHorizontalPlane])
        
        print("HIT TEST:")
        guard let firstResult = result.first else {
            print("### NO RESULT")
            return
        }

        var type = ""
        switch firstResult.type {
        case .featurePoint:
            type = "feature point"
        case .estimatedHorizontalPlane:
            type = "estimated horizontal plane"
        case .estimatedVerticalPlane:
            type = "estimated vertical plane"
        default:
            type = "no type info"
        }
        
        print("    distance: ", firstResult.distance)
        print("        type: ", type)
        
        let transform = frame.camera.transform
        let nodeRotation = getRotation(transform) // change this to be more transparent
        let nodePosition = getPosition(firstResult.worldTransform)
        
        let node = CatNode()
        node.transform = SCNMatrix4.init(getTransform(nodePosition, nodeRotation))
        node.name = "cat"
        
        sceneView.scene.rootNode.addChildNode(node)
    }
}
