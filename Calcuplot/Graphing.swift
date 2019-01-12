//
//  Graphing.swift
//  Calcuplot
//
//  Created by Parker on 1/5/19.
//  Copyright © 2019 Parker. All rights reserved.
//

import Foundation
import SceneKit

func cross(_ a:SCNVector3,_ b:SCNVector3) -> SCNVector3 {return SCNVector3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)}
func -(_ a:SCNVector3,_ b:SCNVector3) -> SCNVector3 {return SCNVector3(a.x-b.x,a.y-b.y,a.z-b.z)}
func +(_ a:SCNVector3,_ b:SCNVector3) -> SCNVector3 {return SCNVector3(a.x+b.x,a.y+b.y,a.z+b.z)}
func *(_ a:SCNVector3,_ b:Float) -> SCNVector3 {return SCNVector3(a.x*b,a.y*b,a.z*b)}
func /(_ a:SCNVector3,_ b:Float) -> SCNVector3 {return a*(1/b)}
func magnitude(_ a:SCNVector3) -> Float {return sqrt(a.x*a.x+a.y*a.y+a.z*a.z)}


//func encaps(_ points:inout [SCNVector3],_ r:Float,_ a:SCNVector3,_ b:SCNVector3,_ c:SCNVector3) {
//    let udv = SCNVector3(a.y-b.y,b.x-a.x,0)
//    let dv = udv/magnitude(udv)
//    points.append(b+dv*r)
//    points.append(b-dv*r)
//}

func encircle(_ points:inout [SCNVector3],_ s:Int,_ r:Float,_ b:SCNVector3,_ ba:SCNVector3,_ bc:SCNVector3,_ ac:SCNVector3) {
    let uup = cross(ba,bc)
    let uou = cross(ac,uup)
    let up = uup/magnitude(uup)
    let ou = uou/magnitude(uou)
    let dt = 2*3.1415926/Float(s)
    for t in 0..<s {
        points.append(b+up*r*sin(dt*Float(t))+ou*r*cos(dt*Float(t)))
    }
}

func addpanel(_ inds:inout [UInt16],_ a:Int,_ b:Int,_ c:Int,_ d:Int) {
    inds.append(UInt16(a))
    inds.append(UInt16(b))
    inds.append(UInt16(c))
    inds.append(UInt16(b))
    inds.append(UInt16(c))
    inds.append(UInt16(d))
}




class GraphingView: UIViewController {
    @IBOutlet var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    
    func shouldAutorotate() -> Bool {
        return true
    }

    func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        scnView = self.view as! SCNView
        scnScene = SCNScene()
        scnView.scene = scnScene
        
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
        
        
        
        scnView.allowsCameraControl = true
        scnView.allowsCameraControl = false
        // 3
        scnView.autoenablesDefaultLighting = true
//        addCustomGeometry()
        add3DGeometry()
    }
    
    
    
    func addCustomGeometry() {
        let vertices: [SCNVector3] = [
            SCNVector3(   0, 1,   0),
            SCNVector3(-0.5, 0, 0.5),
            SCNVector3( 0.5, 0, 0.5),
            SCNVector3( 0.5, 0,-0.5),
            SCNVector3(-0.5, 0,-0.5),
            SCNVector3(   0,-1,   0),
        ]
        let indices: [UInt16] = [
            0, 1, 2,
            2, 3, 0,
            3, 4, 0,
            4, 1, 0,
            1, 5, 2,
            2, 5, 3,
            3, 5, 4,
            4, 5, 1
        ]
        let node = SCNNode(geometry:SCNGeometry(sources:[SCNGeometrySource(vertices: vertices)],elements:[SCNGeometryElement(indices: indices, primitiveType: .triangles)]))
//        node.scale = SCNVector3(1,1,1);
//        node.position = SCNVector3(0,0,0);
        scnView.scene?.rootNode.addChildNode(node)
//        let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 5))
//        node.runAction(rotateAction)
    }
    func add3DGeometry() {
        var samples: [SCNVector3] = []
        var vertices: [SCNVector3] = []
        var indices: [UInt16] = []
        
        samples.append(SCNVector3(-2,4,0))
        samples.append(SCNVector3(-1,1,0))
        samples.append(SCNVector3(-0,0,0))
        samples.append(SCNVector3(1,1,0))
        samples.append(SCNVector3(2,4,0))
        
        let s = 6
        let r : Float = 0.5
        if samples.count<3 {return}
        encircle(&vertices,s,r,samples[0],
            samples[1]-samples[0],
            samples[1]-samples[2],
            samples[0]-samples[1])
        for t in 1..<samples.count-1 {encircle(&vertices,s,r,samples[t],samples[t]-samples[t-1],samples[t]-samples[t+1],samples[t-1]-samples[t+1])}
        encircle(&vertices,s,r,samples[samples.count-1],
            samples[samples.count-2]-samples[samples.count-3],
            samples[samples.count-2]-samples[samples.count-1],
            samples[samples.count-2]-samples[samples.count-1])
        for t in 0..<samples.count-1 {for g in 0..<s {addpanel(&indices,t*s+g,t*s+(g+1)%s,t*s+s+g,t*s+s+(g+1)%s)}}
        
        
        let node = SCNNode(geometry:SCNGeometry(sources:[SCNGeometrySource(vertices: vertices)],elements:[SCNGeometryElement(indices: indices, primitiveType:.triangles)]))
//        node.scale = SCNVector3(1,1,1);
//        node.position = SCNVector3(0,0,0);
        scnView.scene?.rootNode.addChildNode(node)
//        let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 5))
//        node.runAction(rotateAction)
    }
    
}


