//
//  Changed.swift
//  FrogBlog
//
//  Created by Robert Dodson on 4/16/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Foundation

struct Changed
{
    var needsSaving : Bool
    var needsPublishing : Bool
    
    init()
    {
        needsSaving = false
        needsPublishing = false
    }
    
    mutating func changed()
    {
        needsSaving = true
        needsPublishing = true
    }
}
