
//
//  Connection.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 11/3/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import Foundation

func connectToServer() throws -> Holder?{
    let urlString = "http://192.168.1.148:9080/MotorTherapy_war_exploded/MotorTherapy/GameData"
    let holder = Holder()
    guard let url = URL(string: urlString) else{
        print("Error: Invalid URL")
        return holder
    }
    do{
        let json = try String(contentsOf: url, encoding: .ascii)
        let data = Data(json.utf8)
        let holder = try createHolder(data)
        return holder
    } catch let error{
        print(error)
        return holder
    }
}

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
