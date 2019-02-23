//
//  ViewController.swift
//  Basketball
//
//  Created by Давид on 20/02/2019.
//  Copyright © 2019 Давид. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    // MARK: - @IBOutlet Properties
    
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Properties
    
    var hoopAdded = false
    
    // MARK: - UIViewController Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Default lighning
       // sceneView.autoenablesDefaultLighting = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Set the scene to the view
        sceneView.scene = SCNScene()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Detected vertical planes
        configuration.planeDetection = .vertical

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSession Methods
    
    func session(_ session: ARSession, didFailWithError error: Error) {
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
    }
    
    // MARK: - Methods
    
    func addHoop(result: ARHitTestResult) {
        let hoopNode = SCNScene(named: "art.scnassets/Hoop.scn")!.rootNode.childNodes[0]

        hoopNode.eulerAngles.x = -.pi / 2

        print(#function, hoopNode.childNodes.count)

        hoopNode.physicsBody = SCNPhysicsBody(
            type: .static,
            shape: SCNPhysicsShape(
                node: hoopNode ,
                options: [
                    SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
            )
        )

        let node = SCNNode()
        node.addChildNode(hoopNode)
        node.simdTransform = result.worldTransform
        
//        let scene = SCNScene(named: "art.scnassets/Hoop.scn")
//        guard let node = scene?.rootNode.childNode(withName: "hoop", recursively: false ) else { return }
//
//        node.simdTransform = result.worldTransform
//
//        node.eulerAngles.x = 0
//
//        node.physicsBody = SCNPhysicsBody(
//            type: .static,
//            shape: SCNPhysicsShape(
//                node: node,
//                options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
//            )
//        )
        
        sceneView.scene.rootNode.addChildNode(node)
        
    }
    
    func createWall(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        
        let geometry = SCNPlane(width: width, height: height)
        
        let node = SCNNode()
        node.geometry = geometry
        
        node.eulerAngles.x = -Float.pi / 2
        node.opacity = 0.25
        
        return node
    }
    
    func createBasketball() {
        guard let frame = sceneView.session.currentFrame else { return }
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.1))
        
        ball.geometry?.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
        
        ball.opacity = 0.5
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {   // ставим в очередь задачу которая выполнится через 3 секунды
            ball.opacity = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // ball.geometry?.materials.first?.diffuse.contents = UIColor.green
            ball.removeFromParentNode()
        }
        
        ball.physicsBody = SCNPhysicsBody(
            type: .dynamic,
            shape: SCNPhysicsShape(
                node: ball,
                options: [SCNPhysicsShape.Option.collisionMargin: 0.01]
            )
        )
        
        let transform = SCNMatrix4(frame.camera.transform)
        
        ball.transform = transform

        let power = Float(10)
        let force = SCNVector3(
            -power * transform.m31, // направленный вектор по оси
            -power * transform.m32,
            -power * transform.m33
        )
        
        ball.physicsBody?.applyForce(force, asImpulse: true)  // накладываем вектор силы на физическое тело
        
        sceneView.scene.rootNode.addChildNode(ball)
    }

    // MARK: - @IBAction Methods
    
    @IBAction func sreenTapped(_ sender: UITapGestureRecognizer) {  // get place where ur tapped
        if !hoopAdded {
            // Hoop not add yet
            let location = sender.location(in: sceneView)
            let results = sceneView.hitTest(
                location,
                types: [.existingPlaneUsingExtent])
            
            if let result = results.first {
                addHoop(result: result)
                hoopAdded = true
            }
        } else {
            createBasketball()
        }
    }
    
}

    // MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        
        let floor = createWall(planeAnchor: anchor)
        node.addChildNode(floor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let floor = node.childNodes.first,
            let geometry = floor.geometry as? SCNPlane else {
                return
        }

        geometry.width = CGFloat(planeAnchor.extent.x)
        geometry.height = CGFloat(planeAnchor.extent.z)

        floor.position = SCNVector3(
            planeAnchor.center.x,
            0,
            planeAnchor.center.z
        )
    }
    
}
