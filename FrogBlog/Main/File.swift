//
//  File.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/19/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//
//  Represents a File, used for the sample html and css files.
//

import Foundation

import GRDB

class File : Record,Codable
{
    static let INDEXHTML  : String = "index.html"
    static let STYLESCSS  : String = "styles.css"
    static let BLOGENGINE : String = "blogengine.php"
    
    var uuid     : UUID
    var bloguuid : UUID
    var filename : String
    var filetext : String
    
    var filteredtext : String!
    var changed : Changed = Changed()
    
    
    enum CodingKeys: String,CodingKey
    {
        case uuid
        case bloguuid
        case filename
        case filetext
        case filteredtext
    }
    
    override class var databaseTableName: String
    {
        return SqliteDB.FILE
    }
       
    
    init(bloguuid:UUID,filename:String, filetext:String)
    {
        self.uuid     = UUID()
        self.bloguuid = bloguuid
        self.filename = filename
        self.filetext = filetext

        super.init()
    }
    
    
    required init(row: Row)
    {
        uuid     = row[CodingKeys.uuid.rawValue]
        bloguuid = row[CodingKeys.bloguuid.rawValue]
        filename = row[CodingKeys.filename.rawValue]
        filetext = row[CodingKeys.filetext.rawValue]
       
        super.init()
    }
    
    
    override func encode(to container: inout PersistenceContainer)
    {
        container[CodingKeys.uuid.rawValue]     = uuid
        container[CodingKeys.bloguuid.rawValue] = bloguuid
        container[CodingKeys.filename.rawValue] = filename
        container[CodingKeys.filetext.rawValue] = filetext
    }
       
}
