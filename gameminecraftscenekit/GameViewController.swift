import UIKit
import SceneKit

class GameViewController: UIViewController {
    var sceneView: SCNView!
    var groundNode: SCNNode!
    let groundSize: CGFloat = 10.0  // Kích thước mặt đất
    let boxSize: CGFloat = 0.5       // Kích thước khối lập phương

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tạo Scene
        sceneView = SCNView(frame: self.view.frame)
        let scene = SCNScene()
        sceneView.scene = scene
        self.view.addSubview(sceneView)

        // Tạo mặt trời
        addSun()

        // Tạo mặt đất với màu sắc ngẫu nhiên
        createGround()

        // Tạo đám mây
        createClouds()

        // Thiết lập camera
        setupCamera()

        // Nhận sự kiện nhấp chuột
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)

        // Nhận sự kiện kéo để di chuyển camera
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)

        // Nhận sự kiện giữ
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        sceneView.addGestureRecognizer(longPressGesture)
    }

    func addSun() {
        // Thêm ánh sáng mặt trời
        let sunNode = SCNNode()
        let light = SCNLight()
        light.type = .directional
        light.color = UIColor.white // Màu trắng cho ánh sáng mặt trời
        light.intensity = 1000 // Cường độ ánh sáng
        sunNode.light = light
        sunNode.position = SCNVector3(x: 0, y: 10, z: 10) // Đặt vị trí ánh sáng
        sunNode.look(at: SCNVector3(0, 0, 0)) // Nhìn vào mặt đất
        sceneView.scene?.rootNode.addChildNode(sunNode)
    }

    func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 15) // Đặt camera nhìn xuống mặt đất
        cameraNode.name = "camera" // Gán tên cho camera
        cameraNode.look(at: SCNVector3(0, 0, 0)) // Nhìn vào trung tâm của mặt đất
        sceneView.scene?.rootNode.addChildNode(cameraNode)
    }

    func createGround() {
        // Tạo mặt đất dưới dạng hình khối với màu sắc ngẫu nhiên
        let groundGeometry = SCNBox(width: groundSize, height: 0.1, length: groundSize, chamferRadius: 0)
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = generateRandomColor() // Màu sắc ngẫu nhiên cho mặt đất
        groundGeometry.materials = [groundMaterial]

        groundNode = SCNNode(geometry: groundGeometry)
        groundNode.position = SCNVector3(0, -0.05, 0) // Đặt mặt đất nằm ở dưới
        sceneView.scene?.rootNode.addChildNode(groundNode)
    }

    func createClouds() {
        // Tạo đám mây
        let cloudGeometry = SCNSphere(radius: 0.5)
        let cloudMaterial = SCNMaterial()
        cloudMaterial.diffuse.contents = UIColor.white // Màu trắng cho đám mây
        cloudGeometry.materials = [cloudMaterial]

        for _ in 0..<5 {
            let cloudNode = SCNNode(geometry: cloudGeometry)
            cloudNode.position = SCNVector3(
                Float.random(in: -5...5),
                Float.random(in: 5...10),
                Float.random(in: -5...5)
            )
            sceneView.scene?.rootNode.addChildNode(cloudNode)
        }
    }

    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // Nhận tọa độ nhấp chuột
        let location = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: [:])

        if let hit = hitResults.first, hit.node == groundNode {
            // Sinh ra khối lập phương màu ngẫu nhiên
            let boxGeometry = SCNBox(width: boxSize, height: boxSize, length: boxSize, chamferRadius: 0)
            let boxMaterial = SCNMaterial()
            boxMaterial.diffuse.contents = generateRandomColor() // Màu sắc ngẫu nhiên
            boxGeometry.materials = [boxMaterial]

            let boxNode = SCNNode(geometry: boxGeometry)
            boxNode.position = SCNVector3(
                hit.worldCoordinates.x,
                Float(boxSize) / 2,  // Đặt khối ở trên mặt đất
                hit.worldCoordinates.z
            )

            // Gán tag cho khối để theo dõi
            boxNode.name = "block"
            sceneView.scene?.rootNode.addChildNode(boxNode)
        }
    }

    @objc func handleLongPress(_ gestureRecognize: UILongPressGestureRecognizer) {
        let location = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: [:])

        if gestureRecognize.state == .began {
            if let hit = hitResults.first, hit.node.name == "block" {
                // Giữ khối lập phương trong hơn 2 giây
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if hit.node.name == "block" {
                        hit.node.removeFromParentNode() // Xóa khối lập phương
                    }
                }
            }
        }
    }

    @objc func handlePan(_ gestureRecognize: UIPanGestureRecognizer) {
        let translation = gestureRecognize.translation(in: sceneView)
        
        if gestureRecognize.state == .changed {
            // Xoay camera dựa trên cử chỉ kéo
            let cameraNode = sceneView.scene!.rootNode.childNode(withName: "camera", recursively: false) ?? SCNNode()
            let angleY = Float(translation.x) * (Float.pi / 180) // Chuyển đổi độ sang radian
            let angleX = Float(translation.y) * (Float.pi / 180)

            cameraNode.eulerAngles.y -= angleY
            cameraNode.eulerAngles.x -= angleX
            
            // Đảm bảo camera không quay quá 90 độ về phía trên hoặc dưới
            cameraNode.eulerAngles.x = max(min(cameraNode.eulerAngles.x, Float.pi / 2), -Float.pi / 2)
            
            // Reset lại tọa độ để điều chỉnh cho các lần kéo tiếp theo
            gestureRecognize.setTranslation(.zero, in: sceneView)
        }
    }

    func generateRandomColor() -> UIColor {
        return UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1.0)
    }
}
