//
//  Model.swift
//  FrogBlog
//
//  Created by Robert Dodson on 2/7/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//
//  Hold all the Blog and Article data. Maintains
//  handles to the current blog and current article.
//  Also is the interace to the database layer.
//

import Foundation


class Model: NSCopying
{
    var db                : SqliteDB!
    var blogs             : [Blog]?
    var docs              : [Doc]?
    var currentBlog       : Blog!
    var currentArticle    : Article!
    
    
    struct ModelError: Error
    {
        let msg  : String
    }
    
    
    init(db: SqliteDB!, blogs: [Blog]? = nil, docs: [Doc]? = nil, currentBlog: Blog!, currentArticle: Article!)
    {
        self.db = db
        self.blogs = blogs
        self.docs = docs
        self.currentBlog = currentBlog
        self.currentArticle = currentArticle
    }
    
    
    func copy(with zone: NSZone? = nil) -> Any
    {
        let copy = Model(db: db, blogs: blogs, docs: docs, currentBlog: currentBlog, currentArticle: currentArticle)
        return copy
    }
    
    
    func loadBlogsAndDocs() throws
    {
        //
        // Load blogs
        //
        do
        {
            db = SqliteDB()

            blogs = try db.loadBlogs()
            for blog in blogs!
            {
                try db.loadArticles(blog:blog)

                try db.loadFile(blog: blog, filename: File.INDEXHTML)
                try db.loadFile(blog: blog, filename: File.STYLESCSS)
                try db.loadFile(blog: blog, filename: File.BLOGENGINE)

                try getSupportFilesFromBundle(blog:blog)
            }
        }
        catch
        {
            throw ModelError(msg:"Load blogs error: \(error)")
        }
        
        

        //
        // Load doc files
        //
        docs = [Doc]()
        docs!.append(Doc(name: "Markdown Help", filename: "MarkdownHelp.txt"))
        docs!.append(Doc(name: "CSS Colors", filename: "https://www.w3schools.com/cssref/css_colors.asp"))
        docs!.append(Doc(name: "FrogBlog Help", filename: "FrogBlogHelp.txt"))
        docs!.append(Doc(name: "Sample HTML File", filename: "index.html"))
        docs!.append(Doc(name: "Sample CSS File", filename: "styles.css"))
    }
    
    
    //
    // Delete an article.
    // Delete the images that it uses and delete it from its blog's list of articles.
    //
    func deleteArticle(article:Article) throws
    {
        do
        {
            for image in article.images
            {
                try deleteImage(image: image)
            }
            
            let blog = article.blog!
            
            try db.deleteArticle(article: article)
            blog.articles.removeAll(where: { $0.uuid == article.uuid } )
        }
        catch
        {
            throw ModelError(msg:"Error deleting article from database \(article.title): \(error)")
        }
    }
    
    
    //
    // Delete the article and it's images from the server.
    //
    func deleteArticleFromServer(article:Article) throws
    {
        if article.published == true
        {
            do
            {
                let blog = article.blog!
                
                let pub = Publish()
                try pub.deleteArticleFromServer(blog: blog, article: article)
                try pub.deleteImagesFromServer(blog: blog, images: article.images)
            }
            catch let err as Publish.PublishError
            {
                throw ModelError(msg: "Error deleting article from server: \(err.msg) - \(err.info) - \(err.blog)")
            }
        }
    }
    
    
    func deleteAllArticlesFromServer(blog:Blog) throws
    {
        do
        {
            let pub = Publish()
            try pub.deleteAllArticlesFromServer(blog: blog)
            try pub.deleteAllImagesFromServer(blog: blog)
        }
        catch let err as Publish.PublishError
        {
            throw ModelError(msg: "Error deleting all articles from server: \(err.msg) - \(err.info) - \(err.blog)")
        }
    }
    
    func addABlog(blog:Blog)
    {
       blogs!.append(blog)
    }
    
    
    func saveArticle(article:Article) throws
    {
        try db.updateArticle(article: article)
    }
    
    
    func saveBlog(blog:Blog) throws
    {
        try db.updateBlog(blog: blog)
    }
    
    
    func saveFile(file:File) throws
    {
        try db.updateFile(file:file)
        file.changed.needsSaving = false
    }
    
    
    func deleteArticleByUUID(uuid:UUID) throws
    {
        try db.deleteArticleByUUID(uuid:uuid)
    }
    
    
    func deleteImage(image:Image) throws
    {
       try db.deleteImage(image:image)
    }
    
    
    func saveImage(image:Image) throws
    {
        try self.db.updateImage(image: image)
    }
    
    
    
    func deleteBlog(blog:Blog) throws
    {
        do
        {
            for article in blog.articles
            {
                do
                {
                    try deleteArticleFromServer(article: article)
                }
                catch
                {
                    NSLog("Error deleting article from server: \(error)")
                }
            }
            
            for article in blog.articles
            {
                try deleteArticle(article: article)
            }
            
            try db.deleteFile(file:blog.html)
            try db.deleteFile(file:blog.css)
            try db.deleteFile(file:blog.engine)
            
            try db.deleteBlog(blog:blog)
            blogs!.removeAll(where: {$0.nickname == blog.nickname})
        }
        catch
        {
            throw ModelError(msg:"Error deleting blog \(blog.nickname): \(error)")
        }
            
        do
        {
            try Publish().deleteBlogFolderFromServer(blog:blog)
        }
        catch let err as Publish.PublishError
        {
            throw ModelError(msg:"Error deleting blog on server \(blog.nickname): \(err.localizedDescription)")
        }
        
    }
    
    
    
    func filterBlogSupportFiles(blog:Blog) throws
    {
        blog.html.filteredtext = Utils.filterHtmlText(blog: blog, text:  blog.html.filetext)           
        blog.css.filteredtext = blog.css.filetext // nothing to fiter in css file
        
        //
        // for now we always send the sample file for blogengine.php
        //
        let enginefilteredtext = try self.getSampleFile(blog: blog, filename: File.BLOGENGINE)
        { (filetext) -> String in
            return Utils.filterHtmlText(blog: blog, text: filetext)
        }
        blog.engine.filteredtext = enginefilteredtext
    }
    
    
    func getSupportFilesFromBundle(blog:Blog) throws
    {
        if blog.html == nil
        {
            let indexhtmltext = try self.getSampleFile(blog: blog, filename: File.INDEXHTML)
            { (filetext) -> String in
                return filetext
            } ?? "html file error"
            
            blog.html = File(bloguuid: blog.uuid, filename: File.INDEXHTML, filetext: indexhtmltext)
            
            try self.db.updateFile(file:blog.html)
            blog.html.changed.needsSaving = false
            blog.html.changed.needsPublishing = true
        }
        
        if blog.css == nil
        {
            let csstext = try self.getSampleFile(blog: blog, filename: File.STYLESCSS)
            { (filetext) -> String in
               return filetext
            } ?? "css error"

            blog.css = File(bloguuid: blog.uuid, filename: File.STYLESCSS, filetext: csstext)
            
            try self.db.updateFile(file:blog.css)
            blog.css.changed.needsSaving = false
            blog.css.changed.needsPublishing = true
        }
        
        
        if blog.engine == nil
        {
            let enginetext = try self.getSampleFile(blog: blog, filename: File.BLOGENGINE)
            { (filetext) -> String in
              return filetext
            } ?? "blogengine error"

            blog.engine = File(bloguuid: blog.uuid, filename: File.BLOGENGINE, filetext: enginetext)
            
            blog.engine.changed.needsPublishing = true
        }
    }
    
 
    func saveSupportFiles(blog:Blog) throws
    {
        do
        {
            if blog.css.changed.needsSaving { try saveFile(file:blog.css)       }
            if blog.html.changed.needsSaving { try saveFile(file:blog.html)     }
            if blog.engine.changed.needsSaving { try saveFile(file:blog.engine) }
            
            blog.css.changed.needsSaving = false
            blog.html.changed.needsSaving = false
            blog.engine.changed.needsSaving = false
        }
        catch
        {
            throw ModelError(msg:"Error saving support files to database: \(error)")
        }
    }
    
    
    func getSampleFile(blog:Blog,filename:String,processBlock: @escaping (String) -> String) throws -> String?
    {
       guard let path = Bundle.main.path(forResource:filename, ofType:nil) else { return nil }

       var filetext : String

       do
       {
           filetext = try String(contentsOfFile: path)
       }
       catch
       {
           throw ModelError(msg:"Error getting sampelefile \(filename): \(error)")
       }

       filetext = processBlock(filetext)

       return filetext
    }
    
}
