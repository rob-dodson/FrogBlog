//
//  SqliteDB.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/17/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Foundation

import GRDB


class SqliteDB
{
    static let FILE          : String = "file"
    static let ARTICLE       : String = "article"
    static let BLOG          : String = "blog"
    static let IMAGE         : String = "image"
    
    #if DEBUG
    static let DATABASE_NAME : String = "frogblog-v2-DEBUG.sqlite"
    #else
    static let DATABASE_NAME : String = "frogblog-v2.sqlite"
    #endif
    
    var dbqueue : DatabaseQueue!
    
    
    init()
    {
        do
        {
            let databaseURL = try FileManager.default
                .url(for: .applicationSupportDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("FrogBlog")
        
            try FileManager().createDirectory(at: databaseURL,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
            
            dbqueue = try DatabaseQueue(path:"\(databaseURL.path)/\(SqliteDB.DATABASE_NAME)")
            Utils.writeDebugMsgToFile(msg:"DB opened: \(dbqueue.path)")
            try makeTables()
            Utils.writeDebugMsgToFile(msg:"tables ok")
            
            
            //
            // upgrade?
            //
            let olddbpath = String("\(databaseURL.path)/frogblog.sqlite")
            if FileManager.default.fileExists(atPath: olddbpath)
            {
                do
                {
                    let olddbqueue = try DatabaseQueue(path:olddbpath)
                    upgradedb(olddb: olddbqueue, newdb: dbqueue)
                }
                catch
                {
                    Utils.writeDebugMsgToFile(msg:"error with db upgrade")
                }
            }
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"sqlite error: \(error)")
        }
    }
    
    
    func upgradedb(olddb:DatabaseQueue, newdb:DatabaseQueue)
    {
        Utils.writeDebugMsgToFile(msg:"upgrading db")
        
        do
        {
            try FileManager.default.copyItem(atPath: olddb.path, toPath: "\(olddb.path).backup")
            try FileManager.default.removeItem(atPath: olddb.path)
            
            Utils.writeDebugMsgToFile(msg:"deleted old db: \(olddb.path)")
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"error backing up and removing old db \(olddb.path): \(error)")
        }
    }
    
    
    func makeTables() throws
    {
        try dbqueue.write
        { db in
            
            try db.create(table: SqliteDB.IMAGE, ifNotExists: true)
            { t in
                t.column(Image.CodingKeys.uuid.rawValue,.text).primaryKey()
                t.column(Image.CodingKeys.articleuuid.rawValue,.text).notNull()
                t.column(Image.CodingKeys.name.rawValue,.text).notNull()
                t.column(Image.CodingKeys.imagedata.rawValue,.blob)
            }
            
                   
            try db.create(table: SqliteDB.FILE, ifNotExists: true)
            { t in
                t.column(File.CodingKeys.uuid.rawValue,.text).notNull()
                t.column(File.CodingKeys.bloguuid.rawValue,.text).notNull()
                t.column(File.CodingKeys.filename.rawValue,.text).notNull()
                t.column(File.CodingKeys.filetext.rawValue,.blob)
                t.primaryKey([File.CodingKeys.bloguuid.rawValue, File.CodingKeys.filename.rawValue])
            }
            
            try db.create(table: SqliteDB.ARTICLE, ifNotExists: true)
            { t in
                t.column(Article.CodingKeys.uuid.rawValue,.text).primaryKey()
                t.column(Article.CodingKeys.title.rawValue,.text).notNull()
                t.column(Article.CodingKeys.author.rawValue,.text).notNull()
                t.column(Article.CodingKeys.bloguuid.rawValue,.text).notNull()
                t.column(Article.CodingKeys.publisheddate.rawValue,.datetime)
                t.column(Article.CodingKeys.published.rawValue,.boolean)
                t.column(Article.CodingKeys.markdowntext.rawValue,.blob)
            }
            
            try db.create(table: SqliteDB.BLOG, ifNotExists: true)
            { t in
                t.column(Blog.CodingKeys.uuid.rawValue,.text).primaryKey()
                t.column(Blog.CodingKeys.nickname.rawValue,.text).notNull()
                t.column(Blog.CodingKeys.title.rawValue,.text).notNull()
                t.column(Blog.CodingKeys.subtitle.rawValue,.text).notNull()
                t.column(Blog.CodingKeys.author.rawValue,.text).notNull()
                t.column(Blog.CodingKeys.address.rawValue,.text).notNull()
                t.column(Blog.CodingKeys.hostname.rawValue,.text).notNull()
                t.column(Blog.CodingKeys.remoteroot.rawValue,.text).notNull()
                t.column(Blog.CodingKeys.loginname.rawValue,.text).notNull()
                t.column(Blog.CodingKeys.publickeypath.rawValue,.text).notNull()
                t.column(Blog.CodingKeys.privatekeypath.rawValue,.text).notNull()
            }
        }
    }
    
    
    func loadBlogs() throws -> [Blog]
    {
        try dbqueue.write
        { db in
           
            return try Blog.fetchAll(db)
        }
    }
   
    
    func loadArticles(blog:Blog) throws
    {
        try dbqueue.write
        { db in
            
            blog.articles = try Article.filter(Column("bloguuid") == blog.uuid).order(Column("publisheddate").desc).fetchAll(db)
            for article in blog.articles
            {
                article.blog = blog
            }
        }
    }
  

    func loadArticle(uuid:UUID) throws -> Article
    {
       try dbqueue.write
       { db in
           
            let articles = try Article.filter(Column("uuid") == uuid).fetchAll(db)
            return articles[0]
       }
    }

    
    func loadImages(fromArticle:Article) throws -> [Image]
    {
        try dbqueue.write
        { db in
           
            let images = try Image.filter(Column("articleuuid") == fromArticle.uuid).fetchAll(db)
            
            return images
        }
    }
    
    
    func loadFile(blog:Blog,filename:String) throws
    {
        try dbqueue.write
        { db in
           
            let files = try File.filter(Column("bloguuid") == blog.uuid).filter(Column("filename") == filename).fetchAll(db)
            
            if files.count > 0
            {
                if filename == File.INDEXHTML
                {
                    blog.html = files[0]
                }
                else if filename == File.STYLESCSS
                {
                    blog.css = files[0]
                }
            }
        }
    }
    
    func deleteFile(file:File) throws
      {
          try dbqueue.write
          { db in
              
              try file.delete(db)
              Utils.writeDebugMsgToFile(msg:"file deleted: \(file.filename)")
          }
      }
      
    
    func deleteImage(image:Image) throws
    {
        try dbqueue.write
        { db in
            
            try image.delete(db)
            Utils.writeDebugMsgToFile(msg:"image deleted: \(image.name)")
        }
    }
    
    
    func deleteArticle(article:Article) throws
    {
        try dbqueue.write
        { db in
            
            try article.delete(db)
            Utils.writeDebugMsgToFile(msg:"article deleted: \(article.title)")
        }
    }
    
    func deleteArticleByUUID(uuid:UUID) throws
    {
        try dbqueue.write
        { db in
            try Article.filter(Column("uuid") == uuid).deleteAll(db)
            Utils.writeDebugMsgToFile(msg:"article deleted by uuid: \(uuid)")
        }
    }
    
    
    func deleteBlog(blog:Blog) throws
    {
        try dbqueue.write
        { db in
            
            try Article
                .filter(Column("bloguuid") == blog.nickname)
                .deleteAll(db)
            
            try blog.delete(db)
            Utils.writeDebugMsgToFile(msg:"blog deleted: \(blog.nickname)")
        }
    }
    
    
    func updateImage(image:Image) throws
    {
        try dbqueue.write
        { db in

            try image.save(db)
            Utils.writeDebugMsgToFile(msg:"image saved: \(image.name)")
        }
    }
      
    
    func updateFile(file:File) throws
    {
       try dbqueue.write
       { db in
           
           try file.save(db)
           Utils.writeDebugMsgToFile(msg:"file saved: \(file.filename)")
       }
    }
    
    
    func updateArticle(article:Article) throws
    {
        try dbqueue.write
        { db in
            
            try article.save(db)
            Utils.writeDebugMsgToFile(msg:"article saved: \(article.title)")
        }
    }
    
    
    func updateBlog(blog:Blog) throws
	{
	   try dbqueue.write
	   { db in
		
			try blog.save(db)
			Utils.writeDebugMsgToFile(msg:"blog saved: \(blog.nickname)")
	   }
	}

}
