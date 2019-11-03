//
//  SpiderView.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/29/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import ARKit
import AVFoundation
import Combine
import RealityKit
import UIKit

class SpiderView: UIViewController, ARSessionDelegate {
    
    // MARK: - UI Elements
    
    // Main UI views
    @IBOutlet var arView: ARView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var controlView: UIView!
    
    // Buttons and other elements
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    // Game view words
    @IBOutlet weak var avatarIcon: UIImageView!
    
    // TEMP
    @IBOutlet weak var upbutton: UIButton!
    @IBOutlet weak var downbutton: UIButton!
    @IBOutlet weak var leftbutton: UIButton!
    @IBOutlet weak var rightbutton: UIButton!
    
    @IBAction func uppress(_ sender: Any) {
        signalUp()
    }
    
    @IBAction func downpress(_ sender: Any) {
        signalDown()
    }
    
    @IBAction func leftpress(_ sender: Any) {
        signalLeft()
    }
    
    @IBAction func rightpress(_ sender: Any) {
        signalRight()
    }
    
    
    // MARK: - Attributes
    
    // Entity data
    var bodyAnchorExists = false
    var bodyPosition: simd_float3?
    var character: BodyTrackedEntity?
    let characterAnchor = AnchorEntity()
    var upBall = Entity()
    var downBall = Entity()
    var leftBall = Entity()
    var rightBall = Entity()
    var leftBox = Entity()
    var rightBox = Entity()
    
    // Additional variables for control
    var audioPlayer: AVAudioPlayer!
    var collectedWords = [String]()
    var columns: Int?
    var halfAPress = ("", 0)
    var isFirstTime = true
    var isOnline: Bool?
    var isOver = false
    var rows: Int?
    var score = 0
    var squareHeight: CGFloat?
    var squareWidth: CGFloat?
    var posList = [[graphicalSquare]]()
    var web: SpiderWeb?
    var wordLabelList = [[UILabel]]()
    
    // Reality Composer scene
    var experienceScene = Experience.Scene()
    
    // Flush Collision events list for memory management
    var collisionEventStreams = [AnyCancellable]()
    deinit {
        collisionEventStreams.removeAll()
        endGame()
    }
    
    // MARK: - Functions
    
    /// Draws player in position
    func drawPlayer(_ x: Int, _ y: Int) {
        if x > (posList.count - 1) || x < 0 || y > (posList[0].count - 1) || y < 0{
            print("Index out of range")
        } else {
            // Move avatar icon to position of graphical square
            let square = posList[x][y]
            avatarIcon.frame.origin.x = square.x + (squareWidth! / 5)
            avatarIcon.frame.origin.y = square.y + (squareHeight! / 5)
            
            // Update logical player position
            web?.playerPos[0] = x
            web?.playerPos[1] = y
            
            // If player is over a word, collect it
            let wordToCollect = web?.getWord(x, y)
            if (web?.path.contains(web!.playerPos))! && wordToCollect != ""{
                if wordToCollect == "END" {
                    if collectedWords.count == ((web?.path.count)! - 1) {
                        // Check if all words have been collected
                        // End game. No more words
                        web?.setWord(x, y, "")
                        wordLabelList[x][y].text = ""
                        endGame()
                    } else {
                        messageLabel.displayMessage("Collect all words", duration: 5, "Spider Web")
                    }
                } else {
                    // Collect word
                    collectedWords.append(wordToCollect!)
                    web?.setWord(x, y, "")
                    wordLabelList[x][y].text = ""
                    
                    // Add to score
                    score += (web?.scoreMatrix[x][y])!
                }
            }
        }
    }
    
    /// Draws web in UI
    func drawWeb() {
        // Calculate required datax
        let viewWidth = gameView.frame.width
        let viewHeight = gameView.frame.height
        squareWidth = (viewWidth - 40) / CGFloat(columns!)
        squareHeight = (viewHeight - 40) / CGFloat(rows!)
        
        // Initialize variables
        var posX = CGFloat(20)
        var posY = CGFloat(20)
        
        // Render matrix as an Image View
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: viewWidth, height: viewHeight))
        var graphicalSquareRow = [graphicalSquare]()
        
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(#colorLiteral(red: 1, green: 0.1783470213, blue: 0.1863833368, alpha: 1))
            ctx.cgContext.setStrokeColor(#colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1))
            ctx.cgContext.setLineWidth(5)
            
            // Iterate square placement
            for row in 0...(rows! - 1) {
                for column in 0...(columns! - 1) {
                    let rectangle = CGRect(x: posX, y: posY, width: squareWidth!, height: squareHeight!)
                    ctx.cgContext.addRect(rectangle)
                    ctx.cgContext.drawPath(using: .fillStroke)
        
                    // Store graphical square
                    let currentSquare = graphicalSquare(i: row, j: column, x: posX, y: posY)
                    graphicalSquareRow.append(currentSquare)
                    
                    posX += squareWidth!
                }
                posList.append(graphicalSquareRow)
                graphicalSquareRow.removeAll()
                posY += squareHeight!
                posX = CGFloat(20)
            }
        }
        let imgView = UIImageView(image: img)
        gameView.addSubview(imgView)
        drawWordMatrix()
        gameView.bringSubviewToFront(avatarIcon)
    }
    
    /// Draws word matrix in UI
    func drawWordMatrix() {
        let wordMatrix = web?.matrix
        var wordLabelListRow = [UILabel]()
        for i in 0...(wordMatrix!.count - 1) {
            for j in 0...(wordMatrix![0].count - 1) {
                let wordLabel = UILabel(frame: CGRect(x: posList[i][j].x + (squareWidth! / 4),
                                                      y: posList[i][j].y + (squareHeight! / 4),
                                                      width: 200, height: 30))
                let word = web!.getWord(i, j)
                
                // Add label to UI
                wordLabel.text = word
                gameView.addSubview(wordLabel)
                wordLabelListRow.append(wordLabel)
            }
            wordLabelList.append(wordLabelListRow)
            wordLabelListRow.removeAll()
        }
    }
    
    /// Ends game
    func endGame() {
        showWinScreen()
        playSound("yay")
        startButton.isEnabled = true
    }
    
    /// Loads objects in scene
    func loadObjects() {
        loadReality()
        loadRobot()
    }
    
    /// Initializes attributes locally
    func initializeOfflineAttributes() {
        // Generate random spider web
        let dimensionList = [5, 6]
        let dimensions = dimensionList.randomElement()
        columns = dimensions!
        rows = dimensions!
        web = SpiderWeb(dimensions!, dimensions!, isOnline: false)
    }
    
    /// Initializes attributes from server
    func initializeOnlineAttributes() {
        
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities and model entities
        upBall = experienceScene.upBall!
        downBall = experienceScene.downBall!
        leftBall = experienceScene.leftBall!
        rightBall = experienceScene.rightBall!
        leftBox = experienceScene.leftBox!
        rightBox = experienceScene.rightBox!
        
        // Anchor entities
        characterAnchor.addChild(upBall)
        characterAnchor.addChild(downBall)
        characterAnchor.addChild(leftBall)
        characterAnchor.addChild(rightBall)
        characterAnchor.addChild(leftBox)
        characterAnchor.addChild(rightBox)
        
        // Add body tracked character and objects
        arView.scene.addAnchor(characterAnchor)
    }
    
    /// Loads body tracked robot character
    func loadRobot() {
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "models/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    // Model couldn't be lodad
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                
                self.character = character
                cancellable?.cancel()
            } else {
                // Couldn't load model as a body
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    @IBAction func onStartButtonTap(_ sender: Any) {
        startGame()
    }
    
    /// Plays sounds
    func playSound(_ sound: String) {
        switch sound {
        case "hit":
            if let soundURL = Bundle.main.url(forResource: "hit", withExtension: "mp3") {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                }
                catch {
                    print(error)
                }
                audioPlayer.play()
            } else {
                print("Unable to locate audio file")
            }
        case "yay":
            if let soundURL = Bundle.main.url(forResource: "yay", withExtension: "mp3") {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                }
                catch {
                    print(error)
                }
                audioPlayer.play()
            } else {
                print("Unable to locate audio file")
            }
        default:
            print("No sound found")
        }
    }
    
    /// Shows animated view screen
    func showWinScreen() {
        blurView.alpha = 0
        blurView.isHidden = false
        blurView.fadeIn()
        isOver = true
        scoreLabel.text = "Score - " + String(score)
        messageLabel.text = "Congratulations!"
    }
    
    /// Signal down movement in UI
    func signalDown() {
        halfAPress.1 += 1
        if halfAPress.1 == 1 {
            halfAPress.0 = "down"
        } else if halfAPress.1 > 1 && halfAPress.0 == "down" {
            drawPlayer((web?.playerPos[0])! + 1, (web?.playerPos[1])!)
            halfAPress.0 = ""
            halfAPress.1 = 0
        } else {
            messageLabel.displayMessage("Out of bounds. Try again", duration: 3, "Spider Web")
        }
        print("DOWN HAS BEEN TOUCHED")
    }
    
    /// Signal left movement in UI
    func signalLeft() {
        halfAPress.1 += 1
        if halfAPress.1 == 1 {
            halfAPress.0 = "left"
        } else if halfAPress.1 > 1 && halfAPress.0 == "left" {
            drawPlayer((web?.playerPos[0])!, (web?.playerPos[1])! - 1)
            halfAPress.0 = ""
            halfAPress.1 = 0
        } else {
            messageLabel.displayMessage("Out of bounds. Try again", duration: 3, "Spider Web")
        }
        print("LEFT HAS BEEN TOUCHED")
    }
    
    /// Signal right movement in UI
    func signalRight() {
        halfAPress.1 += 1
        if halfAPress.1 == 1 {
            halfAPress.0 = "right"
        } else if halfAPress.1 > 1 && halfAPress.0 == "right" {
            drawPlayer((web?.playerPos[0])!, (web?.playerPos[1])! + 1)
            halfAPress.0 = ""
            halfAPress.1 = 0
        } else {
            messageLabel.displayMessage("Out of bounds. Try again", duration: 3, "Spider Web")
        }
        print("RIGHT HAS BEEN TOUCHED")
    }
    
    /// Signal up movement in UI
    func signalUp() {
        halfAPress.1 += 1
        if halfAPress.1 == 1 {
            halfAPress.0 = "up"
        } else if halfAPress.1 > 1 && halfAPress.0 == "up" {
            drawPlayer((web?.playerPos[0])! - 1, (web?.playerPos[1])!)
            halfAPress.0 = ""
            halfAPress.1 = 0
        } else {
            messageLabel.displayMessage("Out of bounds. Try again", duration: 3, "Spider Web")
        }
        print("UP HAS BEEN TOUCHED")
    }
    
    /// Start collision detection system for current floating object
    func startCollisions() {
        // Subscribe scene to collision events
        // Signal up
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: upBall
        ) { event in
            self.signalUp()
        }.store(in: &collisionEventStreams)
        
        // Signal down
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: downBall
        ) { event in
            self.signalDown()
        }.store(in: &collisionEventStreams)
        
        // Signal left
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: leftBall
        ) { event in
            self.signalLeft()
        }.store(in: &collisionEventStreams)
        
        // Signal right
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: rightBall
        ) { event in
            self.signalRight()
        }.store(in: &collisionEventStreams)
    }
    
    /// Starts game
    func startGame() {
        if !isOver {
            if !bodyAnchorExists {
                // Body doesn't yet exist
                messageLabel.displayMessage("No person detected", duration: 5, "Spider Web")
            } else {
                // Draw web in UI
                drawWeb()
                
                // Start collision detection
                if isFirstTime {
                    startCollisions()
                    isFirstTime = false
                    drawPlayer((web?.midPos[0])!, (web?.midPos[1])!)
                }
                
                startButton.isEnabled = false
            }
        } else {
            // Restart game
            blurView.fadeOut()
            isOver = false
            web?.restartWeb(isOnline: self.isOnline!)
            score = 0
            
            // Clear lists
            collectedWords.removeAll()
            posList.removeAll()
            wordLabelList.removeAll()
            
            if isOnline! {
                initializeOnlineAttributes()
            } else {
                initializeOfflineAttributes()
            }
            
            startGame()
            drawPlayer((web?.midPos[0])!, (web?.midPos[1])!)
        }
    }
    
    // MARK: - View Control
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent screen lock
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Name anchors
        character?.name = "Jackie"
        characterAnchor.name = "Character Anchor"
        
        // Load Reality Composer scene and objects
        experienceScene = try! Experience.loadScene()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configuration for session
        let configuration = ARBodyTrackingConfiguration()
        configuration.automaticSkeletonScaleEstimationEnabled = true
        
        arView.session.run(configuration)
        
        // Load objects in scene
        loadObjects()
        
        // Initialize Attributes
        if isOnline! {
            initializeOnlineAttributes()
        } else {
            initializeOfflineAttributes()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    // MARK: - Session Control
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Print when new anchor is added
        if !anchors.isEmpty {
            anchors.forEach { (anchor) in
                print("""
                      The Type Of Anchor = \(anchor.classForCoder)
                      The Anchor Identifier = \(anchor.identifier)
                      The Anchor Translation = X: \(anchor.transform.columns.3.x), Y: \(anchor.transform.columns.3.y), Z: \(anchor.transform.columns.3.z)
                      """)
                if anchor is ARBodyAnchor {
                    // ARBodyAnchor is detected. Notify class
                    bodyAnchorExists = true
                }
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Iterate over all detected anchors
        for anchor in anchors {
            if anchor is ARBodyAnchor {
                let bodyAnchor = anchor as! ARBodyAnchor
                
                // Tracked body data in skeleton
                let skeleton = bodyAnchor.skeleton
                
                // Obtain position and orientation with anchor data
                let bodyOrientation = Transform(matrix: bodyAnchor.transform).rotation
                let leftHandMidStartPos = simd_make_float3(skeleton.jointModelTransforms[29].columns.3)
                let rightHandMidStartPos = simd_make_float3(skeleton.jointModelTransforms[73].columns.3)
                let rootPos = simd_make_float3(skeleton.jointModelTransforms[0].columns.3)
                bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                
                // Update position and orientation of elements
                characterAnchor.position = bodyPosition!
                characterAnchor.orientation = bodyOrientation
                
                // Place balls control panel in the air
                upBall.position = rootPos + [0, 0, 0.3]
                leftBall.position = rootPos + [0.7, 0, 0]
                rightBall.position = rootPos + [-0.7, 0, 0]
                downBall.position = rootPos + [0, 0, -0.3]
                leftBox.position = leftHandMidStartPos
                rightBox.position = rightHandMidStartPos
                
                // Attach character to anchor
                if let character = character, character.parent == nil {
                    characterAnchor.addChild(character)
                }
            }
        }
    }
    
}
