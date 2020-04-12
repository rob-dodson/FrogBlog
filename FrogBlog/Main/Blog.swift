//
//  Blog.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/9/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Foundation
import KeychainSwift

import GRDB


class Blog : Record,Codable
{
    var uuid           : UUID
    var nickname       : String
    var title          : String
    var subtitle       : String
    var author         : String
    var address        : String
    var hostname       : String
    var remoteroot     : String
    var loginname      : String
    var publickeypath  : String
    var privatekeypath : String
  
    var articles       : [Article]!
    var html           : File!
    var css            : File!
    var engine         : File!
    
    enum CodingKeys: String,CodingKey
    {
        case uuid
        case nickname
        case title
        case subtitle
        case author
        case address
        case hostname
        case remoteroot
        case loginname
        case publickeypath
        case privatekeypath
        case articles
        case html
        case css
        case engine
    }
    
    
    override class var databaseTableName: String
    {
        return SqliteDB.BLOG
    }
     
    
    override init()
    {
        uuid           = UUID()
        nickname       = ""
        title          = ""
        subtitle       = ""
        author         = ""
        address        = ""
        hostname       = ""
        remoteroot     = ""
        loginname      = ""
        publickeypath  = ""
        privatekeypath = ""
        
        articles = Array()
        
        super.init()
    }
    
    
    //
    // We changed the key name to use the UUID instead of the nickname.
    // This func will update any keychains still using the old name.
    //
    func updatekey()
    {
        if let oldkey = Keys.getFromKeychain(name: makeOLDkey())
        {
            Keys.storeInKeychain(name: makekey(), value: oldkey)
            Keys.deleteKey(name: makeOLDkey())
        }
    }
    
    
    required init(row: Row)
    {
        uuid           = row[CodingKeys.uuid.rawValue]
        nickname       = row[CodingKeys.nickname.rawValue]
        title          = row[CodingKeys.title.rawValue]
        subtitle       = row[CodingKeys.subtitle.rawValue]
        author         = row[CodingKeys.author.rawValue]
        address        = row[CodingKeys.address.rawValue]
        hostname       = row[CodingKeys.hostname.rawValue]
        remoteroot     = row[CodingKeys.remoteroot.rawValue]
        loginname      = row[CodingKeys.loginname.rawValue]
        publickeypath  = row[CodingKeys.publickeypath.rawValue]
        privatekeypath = row[CodingKeys.privatekeypath.rawValue]

        articles = Array()
        
        super.init()
        
        updatekey();
    }
      
    
    override func encode(to container: inout PersistenceContainer)
    {
        container[CodingKeys.uuid.rawValue]           = uuid
        container[CodingKeys.nickname.rawValue]       = nickname
        container[CodingKeys.title.rawValue]          = title
        container[CodingKeys.subtitle.rawValue]       = subtitle
        container[CodingKeys.author.rawValue]         = author
        container[CodingKeys.address.rawValue]        = address
        container[CodingKeys.hostname.rawValue]       = hostname
        container[CodingKeys.remoteroot.rawValue]     = remoteroot
        container[CodingKeys.loginname.rawValue]      = loginname
        container[CodingKeys.publickeypath.rawValue]  = publickeypath
        container[CodingKeys.privatekeypath.rawValue] = privatekeypath
    }

        
    func addArticle(newarticle:Article)
    {
        articles.insert(newarticle, at: 0) // Keep articles most recent at the top of the list
    }


    func makeOLDkey() -> String
    {
        return String.init(format: "%@-%@-%@","net.FrogBlog",nickname,"keypassword")
    }
    
    func makekey() -> String
    {
        return String.init(format: "%@-%@-%@","net.FrogBlog",uuid.uuidString,"keypassword")
    }
      
    
    //
    // If replace == false we will make new UUIDs so the blog from which this imported blog was
    // exported will not be overwritten. If replace == true this imported blog will
    // replace the previous version. deleteBlog() should be called first if replace == true.
    //
    static func importFromFile(importfile:String, replace:Bool = false) throws -> Blog?
    {
        do
        {
            let filemanager = FileManager()
            if (filemanager.fileExists(atPath: importfile))
            {
                let jsonString = try String.init(contentsOfFile: importfile)
                let jsonData = jsonString.data(using: .utf8)!
                let blog = try! JSONDecoder().decode(Blog.self, from: jsonData)
                
                if replace == false
                {
                    blog.uuid = UUID() // we make a new uuid here to avoid overwriting the blog from which this was exported
                    blog.nickname = "\(blog.nickname) - NEW"
                }
                    
                
                if blog.css != nil && replace == false
                {
                    blog.css.uuid = UUID()
                    blog.css.bloguuid = blog.uuid
                }
                
                if blog.html != nil && replace == false
                {
                    blog.html.uuid = UUID()
                    blog.html.bloguuid = blog.uuid
                }
                
                if blog.engine != nil && replace == false
                {
                    blog.engine.uuid = UUID()
                    blog.engine.bloguuid = blog.uuid
                }
                
                
                if blog.articles != nil
                {
                    for article in blog.articles
                    {
                        if replace == false
                        {
                            article.uuid = UUID()  // new uuid for article and then hook up articles to blog
                            article.bloguuid = blog.uuid
                        }
                        
                        article.blog = blog
                        
                        for image in article.images
                        {
                            if replace == false
                            {
                                image.uuid = UUID()
                                image.articleuuid = article.uuid
                            }
                        }
                    }
                }
                else
                {
                    blog.articles = Array()
                }
                
                return blog
            }
            else
            {
                return nil
            }
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"Blog: import blog from file error: \(error)")
            throw error
        }
    }

    
    func exportToFile(saveArticles:Bool,exportfilename:String)
    {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try! encoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        do
        {
            try jsonString.write(toFile: exportfilename, atomically: true, encoding: .utf8)
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"Blog: write to file error")
        }
    }
}


