//
//  Image.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/26/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//
//  An image object. An article has an array of these.
//

import Foundation
import Cocoa

import GRDB

class Image : Record,Codable
{
    var uuid        : UUID
    var articleuuid : UUID
    var name        : String
    var imagedata   : Data
    
    
    enum CodingKeys: String,CodingKey
    {
        case uuid
        case articleuuid
        case name
        case imagedata
    }
    
    
    override class var databaseTableName: String
    {
        return SqliteDB.IMAGE
    }
       
    
    init(articleuuid:UUID, name:String, imagedata:Data)
    {
        self.uuid        = UUID()
        self.articleuuid = articleuuid
        self.name        = name.replacingOccurrences(of: " ", with: "_")
        self.imagedata   = imagedata

        super.init()
    }
    

    required init(row: Row)
    {
        uuid        = row[CodingKeys.uuid.rawValue]
        articleuuid = row[CodingKeys.articleuuid.rawValue]
        name        = row[CodingKeys.name.rawValue]
        imagedata   = row[CodingKeys.imagedata.rawValue]
       
        super.init()
    }
      
    
    override func encode(to container: inout PersistenceContainer)
    {
        container[CodingKeys.uuid.rawValue]        = uuid
        container[CodingKeys.articleuuid.rawValue] = articleuuid
        container[CodingKeys.name.rawValue]        = name
        container[CodingKeys.imagedata.rawValue]   = imagedata
    }
    
    
    func makePathOnServer(blog:Blog) -> String
    {
        return String(format: "%@/images/%@",blog.remoteroot,name)
    }
    
}
