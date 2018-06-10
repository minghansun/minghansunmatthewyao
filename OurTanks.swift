import Foundation
//import Glibc


class superTank : Tank {
    override init(row: Int, col: Int, energy: Int, id: String, instructions: String) {
        super.init(row: row, col: col, energy: energy, id: id, instructions: instructions)
    }

    /*func getRandomInt (range: Int) -> Int {
        return Int(rand()) % range
    }*/
    
    func getRandomInt (range: Int) -> Int {
        return Int(arc4random_uniform(UInt32(range)))
    }

    func randomizeDirection () -> Direction {
        var directions = [Direction]()
        directions.append(.north)
        directions.append(.south)
        directions.append(.east)
        directions.append(.west)
        directions.append(.northwest)
        directions.append(.northeast)
        directions.append(.southeast)
        directions.append(.southeast)
        return directions[getRandomInt(range: 7)]
    }

    func chanceOf (percent: Int) -> Bool {
        let ran = getRandomInt(range: 100)
        return percent <= ran
    }

    override func computePreActions() {
        //addPreAction(preAction: RadarAction(range: 4))
        //addPreAction(preAction: ShieldAction(power: 400))
        addPreAction(preAction: SendMessageAction(key: "2001", message: "prepare to attack"))
        super.computePreActions()
    }

    override func computePostActions() {
        //addPostAction(postAction: MissileAction(power: 200, destination: Position(3,3)))
        addPostAction(postAction: DropMineAction(power: 500, isRover: true, dropDirection: .east, moveDirection: .north, id: "R\(Turn)"))
        addPostAction(postAction: MoveAction(distance: 1, direction: .northwest))
        newTurn()
        super.computePostActions()
    }
}

class receive : Tank {
    override func computePreActions() {
        addPreAction(preAction: ReceiveMessageAction(key: "2001"))
        super.computePreActions()
    }
}

class MrStulin : Tank {
    override init(row: Int, col: Int, energy: Int, id: String, instructions: String) {
        super.init(row: row, col: col, energy: energy, id: id, instructions: instructions)
    }
    
    func getRandomInt (range: Int) -> Int {
        return Int(arc4random_uniform(UInt32(range)))
    }
    
    func randomizeDirection () -> Direction {
        var directions = [Direction]()
        directions.append(.north)
        directions.append(.south)
        directions.append(.east)
        directions.append(.west)
        directions.append(.northwest)
        directions.append(.northeast)
        directions.append(.southeast)
        directions.append(.southeast)
        return directions[getRandomInt(range: 7)]
    }
    
    func chanceOf (percent: Int) -> Bool {
        let ran = getRandomInt(range: 100)
        return percent <= ran
    }
    
    
}
