//
//  TankWorld.swift
//  TankLand
//
//  Created by Minghan's on 5/2/18.
//  Copyright © 2018 Minghan's. All rights reserved.
//

import Foundation
//import Glibc


class TankWorld {
    var grid : [[GameObject?]]
    var turn = 1
    var numberLivingTanks = 0
    var logger = Logger()
    private (set) var winnner : Tank?

    init () {
        grid = Array(repeating: Array(repeating: nil, count: 15), count: 15)
        winnner = nil
    }
    
    func setWinner (winner: Tank) {
        logger.addLog(winner, "we have a winner!!!! \(winner.id) \(winner.position)")
        self.winnner = winner
    }
    
    func addGameObject (adding gameObject: GameObject) {
        grid[gameObject.position.row][gameObject.position.col] = gameObject
        if gameObject.objectType == .Tank {numberLivingTanks += 1}
    }
    
    func remove (_ obj: GameObject) {
        grid[obj.position.row][obj.position.col] = nil
        if obj.objectType == .Tank {numberLivingTanks -= 1}
    }

    func populateTheTankWorld () {
        addGameObject(adding: superTank(row: 4, col: 4, energy: 100000, id: "T1", instructions: "none"))
        addGameObject(adding: Mine(mineorRover: .Mine, row: 3, col: 3, energy: 2000000, id: "R1", moveDirection: .north))
        addGameObject(adding: receive(row: 10, col: 10, energy: 50000, id: "T2", instructions: "none"))
    }

    //handling helpers
    func handleRadar (tank: Tank) {
        guard let radarAction = tank.preActions[.Radar] else {return}
        actionRunRadar(tank: tank, runRadarAction: radarAction as! RadarAction)
    }

    func handleMove (tank: Tank) {
        guard let moveAction = tank.postActions[.Move] else {return}
        actionMove(tank: tank, moveAction: moveAction as! MoveAction)
    }

    func handleShields(tank: Tank) {
        guard let shieldAction = tank.preActions[.Shields] else {return }
        actionSetShield(tank: tank, setShieldsAction: shieldAction as! ShieldAction)
    }

    func handleMissle (tank: Tank) {
        guard let missleAction = tank.postActions[.Missle] else {return}
        actionFireMissle(tank: tank, fireMissleAction: missleAction as! MissileAction)
    }

    func handleSendMessage (tank: Tank) {
        guard let sendMessageAction = tank.preActions[.SendMessage] else {return}
        actionSendMessage(tank: tank, sendMessageAction: sendMessageAction as! SendMessageAction)
    }

    func handleReceiveMessage (tank: Tank) {
        guard let receieveMessageAction = tank.preActions[.ReceiveMessage] else {return}
        actionReceiveMessage(tank: tank, receiveMessageAction: receieveMessageAction as! ReceiveMessageAction)
    }

    func handleDropMine (tank: Tank) {
        guard let dropMineAction = tank.postActions[.DropMine] else {return}
        actionDropMine(tank: tank, dropMineAction: dropMineAction as! DropMineAction)
    }
    
    func doTurn () {
        
        logger.newRound()

        var allObjects = findAllGameObjects()
        allObjects = randomizeGameObjects(gameObjects: allObjects)
        
        for e in allObjects {
            let preEnergy = e.energy
            e.liveSupport()
            logger.addLog(e, "life support")
            logger.addLog(e, "energy drops from \(preEnergy) to \(e.energy)")
        }
        
        movingRovers()

        var allTanks = findAllTanks()
        allTanks = randomizeGameObjects(gameObjects: allTanks)

        for a in allTanks {
            a.computePreActions()
            handleRadar(tank: a)
        }
        
        allTanks = randomizeGameObjects(gameObjects: allTanks)

        for a in allTanks {
            handleSendMessage(tank: a)
        }
        
        allTanks = randomizeGameObjects(gameObjects: allTanks)
        
        for a in allTanks {
            handleReceiveMessage(tank: a)
        }
        
        allTanks = randomizeGameObjects(gameObjects: allTanks)

        for a in allTanks {
            handleShields(tank: a)
        }
        
        allTanks = randomizeGameObjects(gameObjects: allTanks)
        
        for b in allTanks {
            b.computePostActions()
            handleDropMine(tank: b)
            handleMissle(tank: b)
            handleMove(tank: b)
        }
        
        for e in logger.data[turn]! {
            print (e)
        }
        
        turn += 1

        for e in allTanks {
            e.clearActions()
            e.clearShieldEnergy()
        }
    }
    
    func runOneTurn () {
        print ("")
        print ("RUNNING TURN \(turn)")
        print ("number of tanks standing \(numberLivingTanks)")
        print ("")
        doTurn()
        gridReport()
    }

    func driver () {
        //var x : String
        populateTheTankWorld()
        gridReport()
        while winnner == nil {
            /*print ("please enter a positive integer indicating how many turns you want Tankland to run")
            x = readLine()!
            if let k = Int(x), k > 0 {
                for _ in 1...k {
                    runOneTurn()
                }
            }*/
        }
        print ("game is over")
    }
}
