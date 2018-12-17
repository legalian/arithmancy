//
//  ViewController.swift
//  Calcuplot
//
//  Created by Parker on 10/22/18.
//  Copyright © 2018 Parker. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.sceneView.debugOptions =
//  ARSCNDebugOptionShowWorldOrigin |
//  ARSCNDebugOptionShowFeaturePoints;
        
//        ARWorldTrackingConfiguration.PlaneDetection.horizontal = true;
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        //SCNScene(named: "art.scnassets/ship.scn")!
        // Set the scene to the view
        sceneView.scene = scene
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        addTapGestureToSceneView()
        addQRCodeListener()
    }
    
    func addCustomGeometry(x:Float,y:Float,z:Float) {
        let vertices: [SCNVector3] = [
            SCNVector3(   0, 1,   0),
            SCNVector3(-0.5, 0, 0.5),
            SCNVector3( 0.5, 0, 0.5),
            SCNVector3( 0.5, 0,-0.5),
            SCNVector3(-0.5, 0,-0.5),
            SCNVector3(   0,-1,   0),
        ]
    
        let source = SCNGeometrySource(vertices: vertices)
        
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
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        let geometry = SCNGeometry(sources: [source], elements: [element])
        
        let node = SCNNode(geometry: geometry)
        
        node.scale = SCNVector3(0.2,0.2,0.2);
        
        node.position = SCNVector3(x,y,z);

        let scnView = sceneView as SCNView
        
        scnView.scene?.rootNode.addChildNode(node)
        
        let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 5))
        node.runAction(rotateAction)
    }
    
    
    
    
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        // 1
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//
//        // 2
//        let width = CGFloat(planeAnchor.extent.x)
//        let height = CGFloat(planeAnchor.extent.z)
//        let plane = SCNPlane(width: width, height: height)
//
//        // 3
//        plane.materials.first?.diffuse.contents = UIColor.cyan
//
//        // 4
//        let planeNode = SCNNode(geometry: plane)
//
//        // 5
//        let x = CGFloat(planeAnchor.center.x)
//        let y = CGFloat(planeAnchor.center.y)
//        let z = CGFloat(planeAnchor.center.z)
//        planeNode.position = SCNVector3(x,y,z)
//        planeNode.eulerAngles.x = -.pi / 2
//
//        // 6
//        node.addChildNode(planeNode)
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        // 1
//        guard let planeAnchor = anchor as?  ARPlaneAnchor,
//            let planeNode = node.childNodes.first,
//            let plane = planeNode.geometry as? SCNPlane
//            else { return }
//
//        // 2
//        let width = CGFloat(planeAnchor.extent.x)
//        let height = CGFloat(planeAnchor.extent.z)
//        plane.width = width
//        plane.height = height
//
//        // 3
//        let x = CGFloat(planeAnchor.center.x)
//        let y = CGFloat(planeAnchor.center.y)
//        let z = CGFloat(planeAnchor.center.z)
//        planeNode.position = SCNVector3(x, y, z)
//    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal;
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }




    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addShipToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    func addQRCodeListener() {
//        let barcodeRequest = VNDetectBarcodesRequest(completionHandler: { request, error in
//            guard let results = request.results else { return }
//            // Loopm through the found results
//            for result in results {
//                // Cast the result to a barcode-observation
//                if let barcode = result as? VNBarcodeObservation {
//                    // Print barcode-values
//                    print("Symbology: \(barcode.symbology.rawValue)")
//                    if let desc = barcode.barcodeDescriptor as? CIQRCodeDescriptor {
//                        let content = String(data: desc.errorCorrectedPayload, encoding: .utf8)
//                        // FIXME: This currently returns nil. I did not find any docs on how to encode the data properly so far.
//                        print("Payload: \(String(describing: content))")
//                        print("Error-Correction-Level: \(desc.errorCorrectionLevel)")
//                        print("Symbol-Version: \(desc.symbolVersion)")
//                    }
//                }
//            }
//        })
//        
//        // Create an image handler and use the CGImage your UIImage instance.
//        guard let image = myImage.cgImage else { return }
//        let handler = VNImageRequestHandler(cgImage: image, options: [:])
//
//        // Perform the barcode-request. This will call the completion-handler of the barcode-request.
//        guard let _ = try? handler.perform([barcodeRequest]) else {
//            return print("Could not perform barcode-request!")
//        }
//        
        
    }
    
    @objc func addShipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        print("alsdkfjlaskdjf")
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .estimatedHorizontalPlane)
        
        guard let hitTestResult = hitTestResults.first else { return }
        let x = hitTestResult.worldTransform.columns.3.x
        let y = hitTestResult.worldTransform.columns.3.y
        let z = hitTestResult.worldTransform.columns.3.z
        
        addCustomGeometry(x:x,y:y,z:z)
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}
