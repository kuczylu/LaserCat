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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("ARKit is not supported on this device")
        }
        
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
    }
}
