//
//  CatNode.swift
//  LaserCat
//
//  Created by Lukas Kuczynski on 1/6/19.
//  Copyright © 2019 Lukas Kuczynski. All rights reserved.
//

import Foundation
import SceneKit

// Watchcout! setting delegate to self then deleting node w/ animation may have retain cycle issues
class CatNode: SCNNode, CAAnimationDelegate {
    
    init(_ catTransform: SCNMatrix4, _ laserLength: Float) {
        super.init()
        
        // load cat child nodes from scene
        guard let catScene = SCNScene(named: "Assets.scnassets/cat.scn") else {
            fatalError("Program terminated: no cat scene found")
        }
        
        for node in catScene.rootNode.childNodes as [SCNNode] {
            self.addChildNode(node)
        }
        
        self.transform = catTransform
        self.name = "cat"
        
        let laserNode = getLaserNode(laserLength)
        self.addChildNode(laserNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func getLaserNode(_ length: Float) -> SCNNode {
        let cylinder = SCNCylinder(radius: 0.01, height: CGFloat(length))
        cylinder.radialSegmentCount = 8
        cylinder.firstMaterial?.diffuse.contents = UIColor.green
        let node = SCNNode(geometry: cylinder)
        node.simdPosition = simd_float3(0.0, 0.0, 0.5 * length)
        node.simdRotation = simd_float4(1.0, 0.0, 0.0, .pi / 2.0)
        node.name = "laser"
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 3.0 //seconds
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.delegate = self
        node.addAnimation(animation, forKey: "opacityFade")
        
        return node
    }
    
    // MARK: - CAAnimationDelegate
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // ??? check here if correct animation
        anim.delegate = nil // fixes retain issue??
        while let node = self.childNode(withName: "laser", recursively: false) {
            node.removeFromParentNode()
        }
    }
}


