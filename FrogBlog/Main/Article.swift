//
//  Article.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/13/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Foundation

import GRDB

class Article : Record,Codable
{
    var uuid           : UUID
    var title          : String
    var author         : String
    var bloguuid       : UUID
    var markdowntext   : String
    var publisheddate  : Date
    var published      : Bool = false
    
    var images         : [Image]!
    var filename       : String!
    var blog           : Blog!
    var userdate       : Bool = false
    var changed        : Changed = Changed()
    
    
    enum CodingKeys: String,CodingKey
    {
        case uuid
        case title
        case author
        case bloguuid
        case markdowntext
        case publisheddate
        case published
        case images
    }
    
    override class var databaseTableName: String
    {
        return SqliteDB.ARTICLE
    }
   
   

    
    init(blog:Blog,
         title:String,
         author:String,
         bloguuid:UUID,
         markdowntext:String)
    {
        self.uuid          = UUID()
        self.title         = title
        self.author        = author
        self.bloguuid      = bloguuid
        self.markdowntext  = markdowntext
        self.publisheddate = Date()
        self.published     = false
        
        self.blog = blog
        images = Array()
        
        super.init()
    }
    
    
    required init(row: Row)
    {
        uuid          = row[CodingKeys.uuid.rawValue]
        title         = row[CodingKeys.title.rawValue]
        author        = row[CodingKeys.author.rawValue]
        bloguuid      = row[CodingKeys.bloguuid.rawValue]
        markdowntext  = row[CodingKeys.markdowntext.rawValue]
        publisheddate = row[CodingKeys.publisheddate.rawValue]
        published     = row[CodingKeys.published.rawValue]
        
        changed.needsPublishing = published
        
        images = Array()
        
        super.init()
    }
    
    
    override func encode(to container: inout PersistenceContainer)
    {
        container[CodingKeys.uuid.rawValue]          = uuid
        container[CodingKeys.title.rawValue]         = title
        container[CodingKeys.author.rawValue]        = author
        container[CodingKeys.bloguuid.rawValue]      = bloguuid
        container[CodingKeys.markdowntext.rawValue]  = markdowntext
        container[CodingKeys.publisheddate.rawValue] = publisheddate
        container[CodingKeys.published.rawValue]     = published
    }
    
    
    func addImage(newimage:Image)
    {
        images.append(newimage)
        changed.changed()
    }

    
    func makeArticleNameOnServer() -> String
    {
        return String(format: "%@-%@",uuid.uuidString,formatArticleDate())
    }
    
    func makePathOnServer() -> String
    {
        return String(format: "%@/articles/%@-%@",blog.remoteroot,uuid.uuidString,formatArticleDate())
    }
    
    
    func formatArticleDate() -> String
    {
        let DateFormatter = Utils.getDateFormatter()
        return DateFormatter.string(from: publisheddate)
    }
     
    
    func formatRSSDate() -> String
    {
        let DateFormatter = Utils.getRSSDateFormatter()
        return DateFormatter.string(from: publisheddate)
    }
    
    func markAsPublished()
    {
        changed.needsPublishing = false // runtime only flag
        published = true   //stored in db
    }
}
