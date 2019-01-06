//
//  CatNode.swift
//  LaserCat
//
//  Created by Lukas Kuczynski on 1/6/19.
//  Copyright © 2019 Lukas Kuczynski. All rights reserved.
//

import Foundation
import SceneKit


class CatNode: SCNNode {
    
    override init() {
        super.init()
        
        // load cat child nodes from scene
        guard let catScene = SCNScene(named: "Assets.scnassets/cat.scn") else {
            fatalError("Program terminated: no cat scene found")
        }
        
        for node in catScene.rootNode.childNodes as [SCNNode] {
            self.addChildNode(node)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
