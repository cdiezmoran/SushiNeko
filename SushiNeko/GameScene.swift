//
//  GameScene.swift
//  SushiNeko
//
//  Created by Carlos Diez on 6/27/16.
//  Copyright (c) 2016 Carlos Diez. All rights reserved.
//

import SpriteKit

enum Side {
    case Left, Right, None
}

enum GameState {
    case Title, Ready, Playing, GameOver
}

class GameScene: SKScene {
    var sushiBasePiece: SushiPiece!
    var character: Character!
    var playButton: MSButtonNode!
    var healthBar: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var lastScoreLabel: SKLabelNode!
    var highScoreLabel: SKLabelNode!
    var mat: SKSpriteNode!
    
    var state: GameState = .Title
    
    var lastScore: Int!
    var highscore: Int!
    var userDefaults: NSUserDefaults!
    
    var sushiTower: [SushiPiece] = []
    
    var health: CGFloat = 1.0 {
        didSet {
            /* Scale health bar between 0.0 -> 1.0 e.g 0 -> 100% */
            if health > 1.0 { health = 1.0 }
            healthBar.xScale = health
        }
    }
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = String(score)
        }
    }
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        /* Connect game objects */
        sushiBasePiece = self.childNodeWithName("sushiBasePiece") as! SushiPiece
        character = self.childNodeWithName("character") as! Character
        playButton = self.childNodeWithName("playButton") as! MSButtonNode
        healthBar = self.childNodeWithName("healthBar") as! SKSpriteNode
        scoreLabel = self.childNodeWithName("scoreLabel") as! SKLabelNode
        lastScoreLabel = self.childNodeWithName("//lastScoreLabel") as! SKLabelNode
        highScoreLabel = self.childNodeWithName("//highScoreLabel") as! SKLabelNode
        mat = self.childNodeWithName("mat") as! SKSpriteNode
        
        /* Setup chopstick connections */
        sushiBasePiece.connectChopsticks()
        
        /* Manually added pieces */
        addTowerPiece(.None)
        addTowerPiece(.Right)
        
        addRandomPieces(10)
        
        playButton.selectedHandler = {
            self.state = .Ready
            self.hideMat()
        }
        
        userDefaults = NSUserDefaults.standardUserDefaults()
        highscore = userDefaults.integerForKey("highscore")
        lastScore = userDefaults.integerForKey("lastScore")
        
        highScoreLabel.text = "High Score: \(highscore)"
        lastScoreLabel.text = "Last Score: \(lastScore)"
        
        displayMat()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        
        /* Game not ready to play */
        if state == .GameOver || state == .Title { return }
        
        /* Game begins on first touch */
        if state == .Ready {
            state = .Playing
        }
        
        for touch in touches {
            /* Get touch position in scene */
            let location = touch.locationInNode(self)
            
            /* Was touch on left/right hand side of screen? */
            if location.x > size.width / 2 {
                character.side = .Right
            } else {
                character.side = .Left
            }
            
            /* Grab sushi piece on top of the base sushi piece, it will always be 'first' */
            let firstPiece = sushiTower.first as SushiPiece!
            
            /* Check character side against sushi piece side (this is the death collision check)*/
            if character.side == firstPiece.side {
                
                dropSushiTower()
                
                gameOver()
                
                /* No need to continue as player dead */
                return
            }
            
            /* Increment Health */
            health += 0.1
            
            /* Increment Score */
            score += 1
            
            /* Remove from sushi tower array */
            sushiTower.removeFirst()

            /* Animate the punched sushi piece */
            firstPiece.flip(character.side)
            
            /* Add a new sushi piece to the top of the sushi tower */
            addRandomPieces(1)
            
            dropSushiTower()
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        /* Called before each frame is rendered */
        if state != .Playing { return }
        
        /* Decrease Health */
        health -= 0.01
        
        /* Has the player run out of health? */
        if health < 0 { gameOver() }
    }
    
    func addTowerPiece(side: Side) {
        /* Add a new sushi piece to the sushi tower */
        
        /* Copy original sushi piece */
        let newPiece = sushiBasePiece.copy() as! SushiPiece
        newPiece.connectChopsticks()
        
        /* Access last piece properties */
        let lastPiece = sushiTower.last
        
        /* Add on top of last piece, default on first piece */
        let lastPosition = lastPiece?.position ?? sushiBasePiece.position
        newPiece.position = lastPosition + CGPoint(x: 0, y: 55)
        
        /* Increment Z to ensure it's on top of the last piece, default on first piece*/
        let lastZPosition = lastPiece?.zPosition ?? sushiBasePiece.zPosition
        newPiece.zPosition = lastZPosition + 1
        
        /* Set side */
        newPiece.side = side
        
        /* Add sushi to scene */
        addChild(newPiece)
        
        /* Add sushi piece to the sushi tower */
        sushiTower.append(newPiece)
    }
    
    func addRandomPieces(total: Int) {
        /* Add random sushi pieces to the sushi tower */
        
        for _ in 1...total {
            
            /* Need to access last piece properties */
            let lastPiece = sushiTower.last as SushiPiece!
            
            /* Need to ensure we don't create impossible sushi structures */
            if lastPiece.side != .None {
                addTowerPiece(.None)
            } else {
                
                /* Random Number Generator */
                let rand = CGFloat.random(min: 0, max: 1.0)
                
                if rand < 0.45 {
                    /* 45% Chance of a left piece */
                    addTowerPiece(.Left)
                } else if rand < 0.9 {
                    /* 45% Chance of a right piece */
                    addTowerPiece(.Right)
                } else {
                    /* 10% Chance of an empty piece */
                    addTowerPiece(.None)
                }
            }
        }
    }
    
    func dropSushiTower() {
        /* Drop all the sushi pieces down one place */
        for node:SushiPiece in sushiTower {
            node.runAction(SKAction.moveBy(CGVector(dx: 0, dy: -55), duration: 0.10))
            
            /* Reduce zPosition to stop zPosition climbing over UI */
            node.zPosition -= 1
        }
    }
    
    func gameOver() {
        /* Game over! */
        
        state = .GameOver
        
        /* Turn all the sushi pieces red*/
        for node:SushiPiece in sushiTower {
            node.runAction(SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 1.0, duration: 0.50))
        }
        
        /* Make the player turn red */
        character.runAction(SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 1.0, duration: 0.50))
        
        if score > highscore {
            userDefaults.setValue(score, forKey: "highscore")
        }
        
        userDefaults.setValue(score, forKey: "lastScore")
        userDefaults.synchronize()
        
        /* Change play button selection handler */
        playButton.selectedHandler = {
            
            /* Grab reference to the SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFill
            
            /* Restart GameScene */
            skView.presentScene(scene)
        }
    }
    
    func displayMat() {
        let dropMat = SKAction(named: "DropMat")!
        mat.runAction(dropMat)
    }
    
    func hideMat() {
        mat.removeAllActions()
        let pullMat = SKAction(named: "PullMat")!
        mat.runAction(pullMat)
    }
}
