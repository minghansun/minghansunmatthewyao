import Foundation
//import Glibc

struct MessageCenter{
    static var messages = [String : String]()
    
    static func sendMessage(id: String, message: String){
        messages[id] = message
    }
    static func receiveMessage(id: String) -> String! {
        if let message = messages[id] {
            return message
        }
        else {return nil}
    }
}
