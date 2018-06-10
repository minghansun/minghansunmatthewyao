//
//  File.swift
//  TankLand
//
//  Created by Minghan's on 5/2/18.
//  Copyright © 2018 Minghan's. All rights reserved.
//

import Foundation

extension TankWorld {
    func actionSendMessage(tank: Tank, sendMessageAction: SendMessageAction){
        if isDead(tank){return}
        logger.addLog(tank, "\(sendMessageAction)")

        if !isEnergyAvailable(tank, amount: Constants.costOfSendingMessage){
            logger.addLog(tank, "insufficient energy to send message")
            return
        }

        applyCost(tank, amount: Constants.costOfSendingMessage)
        MessageCenter.sendMessage(id: sendMessageAction.key, message: sendMessageAction.message)
    }

    func actionReceiveMessage(tank: Tank, receiveMessageAction: ReceiveMessageAction){
        if isDead(tank){return}
        logger.addLog(tank, "\(receiveMessageAction)")

        if !isEnergyAvailable(tank, amount: Constants.costOfReceivingMessage){
            logger.addLog(tank, "insufficient energy to receive message")
            return
        }

        applyCost(tank, amount: Constants.costOfReceivingMessage)
        let message = MessageCenter.receiveMessage(id: receiveMessageAction.key)
        tank.setReceivedMessage(message: message)
        logger.addLog(tank, "message has been received")
    }

    func actionRunRadar (tank: Tank, runRadarAction: RadarAction) {
        let r = runRadarAction.range
        if isDead(tank){return}

        logger.addLog(tank, "\(runRadarAction)")
        if !isEnergyAvailable(tank, amount: Constants.costOfRadarByUnitDistance[r]) {
            logger.addLog(tank, "insufficient energy to run radar")
            return
        }

        applyCost(tank, amount: Constants.costOfRadarByUnitDistance[r])

        var result = RadarResult()
        for e in findObjectsWithinRange(tank.position, range: r)  {
            result.information.append((e,grid[e.row][e.col]!.id,grid[e.row][e.col]!.energy))
        }
        logger.addLog(tank, "the results of the radar are: \(result)")

        tank.newRadarResult(result: result)
    }

    func actionSetShield (tank: Tank, setShieldsAction: ShieldAction) {
        if isDead(tank) {return}

        logger.addLog(tank, "\(setShieldsAction)")
        if !isEnergyAvailable(tank, amount: setShieldsAction.power) {
            logger.addLog(tank, "insufficient energy to set shield")
            return
        }

        tank.addEnergyToShield(amount: setShieldsAction.power * Constants.shieldPowerMultiple)
        logger.addLog(tank, "a shield with strength \(setShieldsAction.power) has been set")
    }

    func actionMove (tank: Tank, moveAction: MoveAction) {
        if isDead(tank) {return}

        logger.addLog(tank, "\(moveAction)")
        
        if !isEnergyAvailable(tank, amount: Constants.costOfFMovingTanksPerUnitDistance[moveAction.distance]) {
            logger.addLog(tank, "insufficient energy to move")
            return
        }

        let newPlace = newPosition(position: tank.position, direction: moveAction.direction, magnitude: moveAction.distance)

        switch newPlace {
        case let a where !isValidPosition(a) : logger.addLog(tank, "the move fails as \(newPlace) is not a valid position")
            return

        case let c where isPositionEmpty(c) : doTheMoving(object: tank, destination: newPlace)
        logger.addLog(tank, "the move has succeeded as \(newPlace) is empty")

        case let b where grid[b.row][b.col]!.objectType == .Tank : logger.addLog(tank, "the move fails as there is a tank in the destination which is \(newPlace)")
            return
        default :
        tank.useEnergy(amount: grid[newPlace.row][newPlace.col]!.energy * Constants.mineStrikeMultiple)
        logger.addLog(tank, "the move has succeeded, but due to the presence of \(grid[newPlace.row][newPlace.col]!.id), it loses \(grid[newPlace.row][newPlace.col]!.energy * Constants.mineStrikeMultiple) energy")
        if isDead(tank) {
            logger.addLog(tank, "the tank is dead in the process of moving")
            remove(tank)
            if isGameOver() {
                setWinner(winner: findWinner()!)
            }
            return
        }
        else {
            doTheMoving(object: tank, destination: newPlace)}
        }
    }


    func actionFireMissle (tank: Tank, fireMissleAction: MissileAction) {
        let destination = fireMissleAction.absoluteDestination
        if isDead(tank) {return}
        applyCost(tank, amount: fireMissleAction.power)

        logger.addLog(tank, "\(fireMissleAction)")
        
        if !isEnergyAvailable(tank, amount: Constants.costOfLaunchingMissle * distance(tank.position, destination)) {
            logger.addLog(tank, "insufficient energy to fire missile")
            return
        }

        if !isValidPosition(destination) {
            logger.addLog(tank, "firing missile failed because \(destination) is not a valid location")
            return
        }

        if !isPositionEmpty(destination) {
            let objective = grid[destination.row][destination.col]!
            var power = fireMissleAction.power * Constants.missileStrikeMultiple
            let energyToBeCollected = objective.energy / 4
            if objective.objectType == .Tank{
                let tankObj = objective as! Tank
                let preShield = tankObj.shield
                if preShield >= power{
                    tankObj.depleteEnergyFromShield(amount: power)
                    logger.addLog(tank, "hit \(objective.id), but all the damage was absorbed by shields")
                    logger.addLog(tankObj, "shields strength reduced from \(preShield) to \(tankObj.shield)")
                } else {
                    power -= preShield
                    objective.useEnergy(amount: power)
                    logger.addLog(tank, "hit \(tankObj.id) at \(tankObj.position) causing \(power) damage; the shields of \(tankObj.id) is breached")
                }

            }
            if isDead(objective) {
                remove(objective)
                if isGameOver() {
                    setWinner(winner: findWinner()!)
                }
                tank.addEnergy(amount: energyToBeCollected)
                logger.addLog(tank, "killed and took \(energyToBeCollected) energy from \(objective.id)")
            }
        }  
        // collateral
        for e in getSurroundingPositions(destination) where !isPositionEmpty(e) && distance(e, tank.position) != 0 {
            let objective = grid[e.row][e.col]!
            var power = fireMissleAction.power * Constants.missileStrikeMultipleCollateral / 4
            let energyToBeCollected = objective.energy / 4
            if objective.objectType == .Tank{
                let tankObj = objective as! Tank
                let preShield = tankObj.shield
                if preShield >= power {
                    tankObj.depleteEnergyFromShield(amount: power)
                    logger.addLog(tank, "splash hit \(objective.id), but all the damage was absorbed by shields")
                    logger.addLog(tankObj, "shields strength reduced from \(preShield) to \(tankObj.shield)")
                } else {
                    power -= preShield
                    objective.useEnergy(amount: power)
                    logger.addLog(tank, "splash hit \(objective.id) at \(objective.position) causing \(power) collateral damage; the shields of \(tankObj.id) is breached")
                }
                if isDead(objective) {
                    remove(objective)
                    if isGameOver() {
                        setWinner(winner: findWinner()!)
                    }
                    tank.addEnergy(amount: energyToBeCollected)
                    logger.addLog(tank, "killed and took \(energyToBeCollected) energy from \(objective.id)")
                    
                }
            }
            else {
                remove(objective)
                logger.addLog(tank, "splash hit \(objective.objectType) \(objective.id), which is destroyed")
            }

        }
    }

    func actionDropMine (tank: Tank, dropMineAction: DropMineAction) {
        if isDead(tank) {return}
        let type = (dropMineAction.isRover) ? GameObjectType.Rover : GameObjectType.Mine
        
        if let direction = dropMineAction.dropDirection {
            logger.addLog(tank, "about to drop \(type) to the \(direction)")
        } else {logger.addLog(tank, "about to drop \(type) randomly")}
        
        if findFreeAdjacent(tank.position) == nil {
            logger.addLog(tank, "the drop fails as there are no free spaces")
            return
        }
        
        if (type == .Rover && !isEnergyAvailable(tank, amount: Constants.costOfReleasingRover + dropMineAction.power)) || (type == .Mine && !isEnergyAvailable(tank, amount: Constants.costOfReleasingMine + dropMineAction.power)) {
            logger.addLog(tank, "insufficient energy to drop \(type)")
            return
        }
        
            if dropMineAction.dropDirection == nil {
                let dropPosition = findFreeAdjacent(tank.position)!
                addGameObject(adding: Mine(mineorRover: type, row: dropPosition.row, col: dropPosition.col, energy: dropMineAction.power, id: dropMineAction.id, moveDirection: dropMineAction.moveDirection))
                logger.addLog(tank, "\(dropMineAction.id) has been dropped at \(dropPosition)")
            }
            //fixed directoion dropping is below
            else {
                let dropPosition = newPosition(position: tank.position, direction: dropMineAction.dropDirection!, magnitude: 1)
                if !isValidPosition(dropPosition) {
                    logger.addLog(tank, "the drop fails as the drop position \(dropPosition) in not valid")
                    return
                }
                if !isPositionEmpty(dropPosition) {
                    logger.addLog(tank, "the drop fails as the drop position \(dropPosition) is not empty")
                    return
                }
                addGameObject(adding: Mine(mineorRover: type, row: dropPosition.row, col: dropPosition.col, energy: dropMineAction.power, id: dropMineAction.id, moveDirection: dropMineAction.moveDirection))
                logger.addLog(tank, "\(dropMineAction.id) has been dropped at \(dropPosition)")
            }
    }
    
    
    func movingIndividualRover (e: Mine) {
        
        if isDead(e) {return}
        
        if !isEnergyAvailable(e, amount: Constants.costOfMovingRover) {
            logger.addLog(e, "insufficient energy to move rover")
            return 
        }
        
        applyCost(e, amount: Constants.costOfMovingRover)
        
        if e.moveDirection != nil {
            logger.addLog(e, "about to move \(e.id) to the \(e.moveDirection!)")
            let newPlace = newPosition(position: e.position, direction: e.moveDirection!, magnitude: 1)
            if !isValidPosition(newPlace) {
                logger.addLog(e, "the move fails as the new position \(newPlace) is not valid")
                return
            }
            if isPositionEmpty(newPlace) {
                doTheMoving(object: e, destination: newPlace)
                logger.addLog(e, "the move succeeds as \(newPlace) is empty")
            } else {
                let obstacle = grid[newPlace.row][newPlace.col]!
                if obstacle.objectType == .Tank {
                    obstacle.useEnergy(amount: e.energy * Constants.mineStrikeMultiple)
                    logger.addLog(e, "the move fails; however \(e.id) struck \(obstacle.id) at \(newPlace), causing \(e.energy * Constants.mineStrikeMultiple) damage")
                    killTheObject(e)
                    if isDead(obstacle) {
                        remove(obstacle)
                        if isGameOver() {
                            setWinner(winner: findWinner()!)
                        }
                    }
                }
                else {
                    killTheObject(e)
                    killTheObject(obstacle as! Mine)
                    logger.addLog(e, "the move fails; however \(e.id) struck another \(obstacle.objectType) \(obstacle.id) at \(newPlace); both objects died")
                }
            }
        }
            
        else {
            logger.addLog(e, "about to move randomly")
            let possibles = getSurroundingPositions(e.position)
            let destination = possibles[getRandomInt(range: possibles.count)]
            if isPositionEmpty(destination) {
                doTheMoving(object: e, destination: destination)
                logger.addLog(e, "the move succeeds as \(destination) is empty")
            } else {
                let obstacle = grid[destination.row][destination.col]!
                if obstacle.objectType == .Tank {
                    obstacle.useEnergy(amount: e.energy * Constants.mineStrikeMultiple)
                    logger.addLog(e, "the move fails; however \(e.id) struck \(obstacle.id) at \(destination), causing \(e.energy * Constants.mineStrikeMultiple) damage")
                    killTheObject(e)
                    if isDead(obstacle) {
                        remove(obstacle)
                        if isGameOver() {
                            setWinner(winner: findWinner()!)
                        }
                    }
                }
                else {
                    logger.addLog(e, "the move fails; however \(e.id) struck another \(obstacle.objectType) \(obstacle.id) at \(destination); both objects died")
                    
                    killTheObject(obstacle as! Mine)
                    killTheObject(e)
                }
            }
        }
    }
    
    func movingRovers () {
        let allRovers = randomizeGameObjects(gameObjects: findAllRovers())
        for e in allRovers { movingIndividualRover(e: e) }
    }
}
