//
//  Keys.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/15/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Foundation

import KeychainSwift

class Keys
{
    
    static func getFromKeychain(name:String) -> String?
    {
        return KeychainSwift().get(name)
    }
    
    static func storeInKeychain(name:String,value:String)
    {
        KeychainSwift().set(value, forKey: name)
    }

}
