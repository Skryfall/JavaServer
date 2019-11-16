//
//  Connection.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 11/3/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import Foundation

/// Connects to set server to fetch data
func connectToServer() -> Holder {
    // Default server URL
    let urlString = "http://192.168.100.11:9080/MotorTherapy_war_exploded/MotorTherapy/GameData"
    
    // Holder contains all updated data from server
    let holder = Holder()
    guard let url = URL(string: urlString) else{
        print("Error: Invalid URL")
        return holder
    }
    
    // Decode JSON message
    do{
        let json = try String(contentsOf: url, encoding: .ascii)
        let data = Data(json.utf8)
        let holder = try createHolder(data)
        holder?.connectionSuccess = true
        return holder!
    } catch let error{
        // Error connecting
        print(error)
        holder.connectionSuccess = false
        return holder
    }
}


/// Initializes holder from JSON message
func createHolder(_ json: Data) throws -> Holder?{
    do {
        let decoder = JSONDecoder()
        let holder = try decoder.decode(Holder.self, from: json)
        return holder
    } catch let error {
        print(error)
        return nil
    }
}
