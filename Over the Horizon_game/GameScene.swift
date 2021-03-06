//
//  GameScene.swift
//  Over the Horizon_game
//
//  Created by DDDD on 12/10/2020.
//

import SpriteKit

enum GameState { //the states of the game
    case showingLogo
    case playing
    case dead
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    
    var backgroundMusic: SKAudioNode!
    
    //configuring the showLogo
    var logoOne: SKSpriteNode!
    var logoTwo: SKSpriteNode!
    
    var gameOver: SKSpriteNode!
    
    var gameState = GameState.showingLogo //initial gameState
    
    //  configuring the pixel-perfect collision for rocks
    let rockTexture = SKTexture(imageNamed: "rock") //store rock texture
    var rockPhysics: SKPhysicsBody! //store rock physics body
    
    let explosion = SKEmitterNode(fileNamed: "PlayerExplosion") //solving the delay when the player crashes by forcing SpriteKit to preload the texture at initialization and keep it in memory
    
    
    override func didMove(to view: SKView) {
        
        createPlayer()
        createSky()
        createBackground()
        createGround()
        //        startRocks()  //commenting out so it wont start creating rocks before starting the game, also configuring player.physicsBody.isDynamic = false so player is suspended until start
        createScore()
        createLogos()
        
        //static physics gravity for player
//        setPhysicsGravity()

        //configuring music
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "m4a") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        //creating an SKPhysicsBody from the rock texture, so it can be preloaded later
        rockPhysics = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
    }
    
    func setPhysicsGravity() {

        physicsWorld.gravity = CGVector(dx: 0.0, dy: (-5.0 - Double(score))) //making the gravity harder as the player advances by each point
        physicsWorld.contactDelegate = self
    }
    
    //configuring the score
    var scoreLabel: SKLabelNode!

    var score = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
            print(score)
        }
    }
    
    func createScore() {
        scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        scoreLabel.fontSize = 25
        
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 80)
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontColor = UIColor.black
        
        addChild(scoreLabel)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //configuring the game for when the player presses "New Game"
        switch gameState {
        case .showingLogo:
            gameState = .playing
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let wait = SKAction.wait(forDuration: 0.5)
            let activatePlayer = SKAction.run {
                [unowned self] in
                self.player.physicsBody?.isDynamic = true
                self.startRocks()
            }
            
            let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
           
            logoOne.run(sequence)
            logoTwo.run(sequence)
            
        case .playing:
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0) // neutralize any existing upward velocity before applying the push
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20)) //apply a push every time the screen is tapped
        
        case .dead:
            // break //resetting the game once the player has crashed and tapped the screen
            if let scene = GameScene(fileNamed: "GameScene") { //creating a fresh GameScene scene
                scene.scaleMode = .aspectFill
                let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
                view?.presentScene(scene, transition: transition)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        guard player != nil else { return } //ensure that the player is not nil, otherwise exit the method, needed when restarting the game
        let value = player.physicsBody!.velocity.dy * 0.001 //tilting the player when moving up or down a little bit
        let rotate = SKAction.rotate(toAngle: value, duration: 0.1)
        
        player.run(rotate)
        
        setPhysicsGravity() //updating the gravity based on score
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        //checking whhich of them collided with whom
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect" {
            if contact.bodyA.node == player {
                contact.bodyB.node?.removeFromParent()
            } else {
                contact.bodyA.node?.removeFromParent()
            }
            
            let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            run(sound)
            
            //triggering the didSet property
            score += 1
            
            //if the player hits something else - do not continue this method
            return
        }
        
        //skipping any collision if either of the nodes become nil
        guard contact.bodyA.node != nil && contact.bodyB.node != nil else {
            return
        }
        
        //configuring the ending
        if contact.bodyA.node == player || contact.bodyB.node == player {
            if let explosion = SKEmitterNode(fileNamed: "PlayerExplosion") {
                explosion.position = player.position
                addChild(explosion)
            }
            
            let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
            run(sound)
            
            //configuring the ending of the game when the player crashes
            gameOver.alpha = 1
            gameState = .dead
            backgroundMusic.run(SKAction.stop())
            player.removeFromParent()
            speed = 0 //1.0 real time, 2.0 doubling the action speed
        }
    }
    
    
    func createPlayer() {
        let playerTexture = SKTexture(imageNamed: "player1-1")
        player = SKSpriteNode(texture: playerTexture)
        player.zPosition = 10
        player.position = CGPoint(x: frame.width / 6, y: frame.height * 0.75)
        
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: playerTexture, size: playerTexture.size()) //setting the exact pixel physics
        player.physicsBody!.contactTestBitMask = player.physicsBody!.collisionBitMask //tell when player collides with anything, since the player dies when touching anything, but doesn't bounce
        //        player.physicsBody?.isDynamic = true //commented for starting game in another mode
        player.physicsBody?.isDynamic = false
        
        player.physicsBody?.collisionBitMask = 0 //player bounces off in air
        
        let frame2 = SKTexture(imageNamed: "player1-2")
        let frame3 = SKTexture(imageNamed: "player1-3")
        
        let animation = SKAction.animate(with: [playerTexture, frame2, frame3, frame2], timePerFrame: 0.01)
        let runForever = SKAction.repeatForever(animation)
        
        player.run(runForever)
    }
    
    func createSky() {
        
        let topSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.14, brightness: 0.97, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.67))
        topSky.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        let bottomSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.16, brightness: 0.96, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.33))
        bottomSky.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        topSky.position = CGPoint(x: frame.midX, y: frame.height)
        bottomSky.position = CGPoint(x: frame.midX, y: bottomSky.frame.height)
        
        addChild(topSky)
        addChild(bottomSky)
        
        bottomSky.zPosition = -40
        topSky.zPosition = -40
        
    }
    
    func createBackground() {
        let backgroundTexture = SKTexture(imageNamed: "background")
        
        for i in 0...1 {
            let background = SKSpriteNode(texture: backgroundTexture)
            background.zPosition = -30 //placing it in front of the Sky
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: (backgroundTexture.size().width * CGFloat(i)) - CGFloat(1 * i), y: 100) // calculating the X position of each mountain (inside loop from 0 to  1. First loop => x = 0, second loop => x = texture - 1, and this helps avoiding tiny little gaps in the mountains)
            addChild(background)
            
            //making the background run indefinetely
            let moveLeft = SKAction.moveBy(x: -backgroundTexture.size().width, y: 0, duration: 5)
            let moveReset = SKAction.moveBy(x: backgroundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            background.run(moveForever)
        }
    }
    
    
    func createGround() {
        let groundTexture = SKTexture(imageNamed: "ground")
        
        for i in 0 ... 1 {
            let ground = SKSpriteNode(texture: groundTexture)
            
            ground.zPosition = -10
            
            ground.anchorPoint = CGPoint(x: 0.5, y: 0.05) //0.1
            //pozitionarea la ground
            ground.position = CGPoint(x: (groundTexture.size().width / 2 + (groundTexture.size().width * CGFloat(i))), y: groundTexture.size().height / 1)
            
            ground.physicsBody = SKPhysicsBody(texture: ground.texture!, size: ground.texture!.size())
            ground.physicsBody?.isDynamic = false //player htis the ground
            
            addChild(ground)
            
            let moveLeft = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
            let moveReset = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            ground.run(moveForever)
        }
    }
    
    
    func createRocks() {
        //creating top and bottom impact objects sprites
        
        let rockTexture = SKTexture(imageNamed: "rock")
        
        let topRock = SKSpriteNode(texture: rockTexture)
        
        //        topRock.physicsBody = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
        topRock.physicsBody = rockPhysics.copy() as? SKPhysicsBody
        topRock.physicsBody?.isDynamic = false //ensuring the rocks wont fall off screen
        
        topRock.zRotation = .pi
        topRock.xScale = -1.0 //inverting the sprite
        
        let bottomRock = SKSpriteNode(texture: rockTexture)
        
        //        bottomRock.physicsBody = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
        bottomRock.physicsBody = rockPhysics.copy() as? SKPhysicsBody
        bottomRock.physicsBody?.isDynamic = false //ensuring it wont fall off
        topRock.zPosition = -20
        bottomRock.zPosition = -20
        
        //creating 3rd sprite positioned after the impact object, which will record points once passed`
        let rockCollision = SKSpriteNode(color: UIColor.clear, size: CGSize(width: 32, height: frame.height)) //changing from .red to .clear color
        rockCollision.name = "scoreDetect"
        
        rockCollision.physicsBody = SKPhysicsBody(rectangleOf: rockCollision.size)
        rockCollision.physicsBody?.isDynamic = false
        
        
        addChild(topRock)
        addChild(bottomRock)
        addChild(rockCollision)
        
        //generating number to determine where the safe gap in the rocks should be
        let xPosition = frame.width + topRock.frame.width
        
        let max = CGFloat(frame.height / 3)
        let yPosition = CGFloat.random(in: -50...max)
        
        let rockDistance: CGFloat = 70 //the small number the small the space and harder the game
        
        //positioning the rocks on right edge of screen, and animate through left
        topRock.position = CGPoint(x: xPosition, y: yPosition + topRock.size.height + rockDistance)
        bottomRock.position = CGPoint(x: xPosition, y: yPosition - rockDistance)
        rockCollision.position = CGPoint(x: xPosition + (rockCollision.size.width * 2), y: frame.midY)
        
        let endPosition = frame.width + (topRock.frame.width * 2)
        
        let moveAction = SKAction.moveBy(x: -endPosition, y: 0, duration: 6.2)
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        topRock.run(moveSequence)
        bottomRock.run(moveSequence)
        rockCollision.run(moveSequence)
        
    }
    
    
    func startRocks() {
        let create = SKAction.run {
            [unowned self] in
            self.createRocks()
        }
        
        let wait = SKAction.wait(forDuration: 3)
        let sequence = SKAction.sequence([create, wait])
        let repeatForever = SKAction.repeatForever(sequence)
        
        run(repeatForever)
    }
    
    //creating the logos
    func createLogos() {
//        logo = SKSpriteNode(imageNamed: "logo")
//        logo.position = CGPoint(x: frame.midX, y: frame.midY)
//        addChild(logo)
        
        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOver.alpha = 0
        addChild(gameOver)
        
        //player 1
        let player1Texture = SKTexture(imageNamed: "player1-1")
        logoOne = SKSpriteNode(texture: player1Texture)
//        logoOne.zPosition = 10
        logoOne.position = CGPoint(x: frame.midX - 100, y: frame.midY)
        
        logoOne.physicsBody = SKPhysicsBody(texture: player1Texture, size: player1Texture.size()) //setting the exact pixel physics
       
        logoOne.physicsBody?.isDynamic = false
        
//        player.physicsBody?.collisionBitMask = 0 //player bounces off in air
//
        let frame2 = SKTexture(imageNamed: "player1-2")
        let frame3 = SKTexture(imageNamed: "player1-3")
        
        let animation = SKAction.animate(with: [player1Texture, frame2, frame3, frame2], timePerFrame: 0.01)
        let runForever = SKAction.repeatForever(animation)
        
        logoOne.run(runForever)
        addChild(logoOne)
    
        //player 2
        let player2Texture = SKTexture(imageNamed: "player2-1")
        logoTwo = SKSpriteNode(texture: player2Texture)
//        logoTwo.zPosition = 10
        logoTwo.position = CGPoint(x: frame.midX, y: frame.midY)
        
        logoTwo.physicsBody = SKPhysicsBody(texture: player2Texture, size: player2Texture.size()) //setting the exact pixel physics
       
        logoTwo.physicsBody?.isDynamic = false
        
//        player.physicsBody?.collisionBitMask = 0 //player bounces off in air
//
        let frame4 = SKTexture(imageNamed: "player2-2")
        let frame5 = SKTexture(imageNamed: "player2-3")
        
        let animation2 = SKAction.animate(with: [player2Texture, frame4, frame5, frame4], timePerFrame: 0.01)
        let runForever2 = SKAction.repeatForever(animation2)
        
        logoTwo.run(runForever2)
        addChild(logoTwo)
    }
}
