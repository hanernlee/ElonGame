//
//  GameScene.swift
//  ElonGame
//
//  Created by Christopher Lee on 14/4/18.
//  Copyright © 2018 Christopher Lee. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // Nodes
    var player : SKNode?
    var joystick : SKNode?
    var joystickKnob : SKNode?
    var cameraNode : SKCameraNode?
    var mountains1 : SKNode?
    var mountains2 : SKNode?
    var mountains3 : SKNode?
    var moon : SKNode?
    var stars : SKNode?
    
    // Boolean
    var joystickAction = false
    
    // Measure
    var knobRadius : CGFloat = 50.0
    
    // Sprite Engine
    var previousTimeInterval : TimeInterval = 0
    var playerIsFacingRight = true
    let playerSpeed = 4.0
    
    // Player state
    var playerStateMachine : GKStateMachine!
    
    // didmove
    override func didMove(to view: SKView) {
        
        player = childNode(withName: "player")
        joystick = childNode(withName: "joystick")
        joystickKnob = joystick?.childNode(withName: "knob")
        cameraNode = childNode(withName: "cameraNode") as? SKCameraNode
        mountains1 = childNode(withName: "mountains1")
        mountains2 = childNode(withName: "mountains2")
        mountains3 = childNode(withName: "mountains3")
        moon = childNode(withName: "moon")
        stars = childNode(withName: "stars")
        
        playerStateMachine = GKStateMachine(states: [
            JumpingState(playerNode: player!),
            WalkingState(playerNode: player!),
            IdleState(playerNode: player!),
            LandingState(playerNode: player!),
            StunnedState(playerNode: player!),
            ])
        
        playerStateMachine.enter(IdleState.self)
    }
}

// MARK: Touches
extension GameScene {
    // Touch Began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let joystickKnob = joystickKnob {
                let location = touch.location(in: joystick!)
                joystickAction = joystickKnob.frame.contains(location)
            }
            
            let location = touch.location(in: self)
            if !(joystick?.contains(location))! {
                playerStateMachine.enter(JumpingState.self)
            }
        }
    }
    
    // Touch Moved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let joystick = joystick else { return }
        guard let joystickKnob = joystickKnob else { return }
        
        if !joystickAction { return }
        
        // Distance
        for touch in touches {
            let position = touch.location(in: joystick)
            
            let length = sqrt(pow(position.y, 2) + pow(position.x, 2))
            let angle = atan2(position.y, position.x)
            
            if knobRadius > length {
                joystickKnob.position = position
            } else {
                joystickKnob.position = CGPoint(x: cos(angle) * knobRadius, y: sin(angle) * knobRadius)
            }
        }
    }
    
    // Touch End
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let xJoystickCoordinate = touch.location(in: joystick!).x
            let xLimit: CGFloat = 200.0
            if xJoystickCoordinate > -xLimit && xJoystickCoordinate < xLimit {
                resetKnobPosition()
            }
        }
    }
}

// MARK: Action
extension GameScene {
    func resetKnobPosition() {
        let initialPoint = CGPoint(x: 0, y: 0)
        let moveBack = SKAction.move(to: initialPoint, duration: 0.1)
        moveBack.timingMode = .linear
        joystickKnob?.run(moveBack)
        joystickAction = false
    }
}

// MARK: Game Loop
extension GameScene {
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - previousTimeInterval
        previousTimeInterval = currentTime
        
        // Camera
        cameraNode?.position.x = player!.position.x
        joystick?.position.y = (cameraNode?.position.y)! - 100
        joystick?.position.x = (cameraNode?.position.x)! - 300
        
        // Player movement
        guard let joystickKnob = joystickKnob else { return }
        let xPosition = Double(joystickKnob.position.x)
        let positivePosition = xPosition < 0 ? -xPosition : xPosition
        
        if floor(positivePosition) != 0 {
            playerStateMachine.enter(WalkingState.self)
        } else {
            playerStateMachine.enter(IdleState.self)
        }
        let displacement = CGVector(dx: deltaTime * xPosition * playerSpeed, dy: 0)
        let move = SKAction.move(by: displacement, duration: 0)
        let faceAction : SKAction!
        let movingRight = xPosition > 0
        let movingLeft = xPosition < 0
        if movingLeft && playerIsFacingRight {
            playerIsFacingRight = false
            let faceMovement = SKAction.scaleX(to: -1, duration: 0.0)
            faceAction = SKAction.sequence([move, faceMovement])
        }
        else if movingRight && !playerIsFacingRight {
            playerIsFacingRight = true
            let faceMovement = SKAction.scaleX(to: 1, duration: 0.0)
            faceAction = SKAction.sequence([move, faceMovement])
        } else {
            faceAction = move
        }
        player?.run(faceAction)
        
        // Background Parallax
        let parallax1 = SKAction.moveTo(x: (player?.position.x)!/(10), duration: 0.0)
        mountains1?.run(parallax1)
        
        let parallax2 = SKAction.moveTo(x: (player?.position.x)!/(30), duration: 0.0)
        mountains2?.run(parallax2)
        
        let parallax3 = SKAction.moveTo(x: (player?.position.x)!/(60), duration: 0.0)
        mountains3?.run(parallax3)
        
        let parallax4 = SKAction.moveTo(x: (cameraNode?.position.x)!, duration: 0.0)
        moon?.run(parallax4)
        
        let parallax5 = SKAction.moveTo(x: (cameraNode?.position.x)!, duration: 0.0)
        stars?.run(parallax5)
    }
}
