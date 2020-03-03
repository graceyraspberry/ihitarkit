/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Displays coordinate axes visualizing the tracked face pose (and eyes in iOS 12).
*/

import ARKit
import SceneKit

class TransformVisualization: NSObject, VirtualContentController {
    
    var contentNode: SCNNode?
    
    // Load multiple copies of the axis origin visualization for the transforms this class visualizes.
    lazy var rightEyeNode = SCNReferenceNode(named: "coordinateOrigin")
    lazy var leftEyeNode = SCNReferenceNode(named: "coordinateOrigin")
    
    var leftEyeArray: Array<Float> = Array()
    var rightEyeArray: Array<Float> = Array()
    var lookAtArray: Array<Float> = Array()
    var timeArray: Array<Int> = Array()
    var faceArray: Array<Float> = Array()
    var count = 0
    
    /// - Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // This class adds AR content only for face anchors.
        guard anchor is ARFaceAnchor else { return nil }
        
        // Load an asset from the app bundle to provide visual content for the anchor.
        contentNode = SCNReferenceNode(named: "coordinateOrigin")
        
        // Add content for eye tracking in iOS 12.
        self.addEyeTransformNodes()
        
        // Provide the node to ARKit for keeping in sync with the face anchor.
        return contentNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard #available(iOS 12.0, *), let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        rightEyeNode.simdTransform = faceAnchor.rightEyeTransform
        leftEyeNode.simdTransform = faceAnchor.leftEyeTransform

        var leftEyePosition = SCNVector3(leftEyeNode.simdTransform.columns.3.x, leftEyeNode.simdTransform.columns.3.y, leftEyeNode.simdTransform.columns.3.z)
        var rightEyePosition = SCNVector3(rightEyeNode.simdTransform.columns.3.x, rightEyeNode.simdTransform.columns.3.y, rightEyeNode.simdTransform.columns.3.z)
        var leftEyeX = leftEyeNode.simdTransform.columns.3.x
        var rightEyeX = rightEyeNode.simdTransform.columns.3.x
        let d = distance(float3(leftEyePosition), float3(rightEyePosition))
//        print("\nInter-eye distance in centimeters: ", d * 100)
//        print("\nLeft eye x: ", leftEyeX * 100)
//        print("\nRight eye x: ", rightEyeX * 100)
//        print(faceAnchor.lookAtPoint.x)
        let x = faceAnchor.lookAtPoint.x
        let timestamp = count
        let facecoordinate = faceAnchor.transform.columns.2.x
        leftEyeArray.append(leftEyeX)
        rightEyeArray.append(rightEyeX)
        lookAtArray.append(x)
        timeArray.append(timestamp)
        faceArray.append(facecoordinate)
        
//        print("x: " + String(faceAnchor.transform.columns.1.x))
//        print("y: " + String(faceAnchor.transform.columns.1.y))
//        print("z: " + String(faceAnchor.transform.columns.2.x))
        
        count = count + 1
        if (count == -1) {
            //write to csv file
            print("\nLeft eye array")
            print(leftEyeArray)
            print("\nRight eye array")
            print(rightEyeArray)
            print("\nLook at point array")
            print(lookAtArray)
            print("\nTime array")
            print(timeArray)
            print("\nFace array")
            print(faceArray)
        }
//        NSMutableData * data = [NSMutableData dataWithCapacity:0];
//
//        [data appendBytes:&leftEyeX length:sizeof(float)];
//        data.write("/Users/cchen/Desktop/lefteye.csv", leftEyeX)
//        NSData.write("/Users/cchen/Desktop/righteye.csv", rightEyeX)
    }
    
    func addEyeTransformNodes() {
        guard #available(iOS 12.0, *), let anchorNode = contentNode else { return }
        
        // Scale down the coordinate axis visualizations for eyes.
        rightEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
        leftEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
        
        anchorNode.addChildNode(rightEyeNode)
        anchorNode.addChildNode(leftEyeNode)
    }

}
