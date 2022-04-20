//
//  Publish.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/26/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//
//	This class handles sending files to the web blog server.
//	It can also delete files there.
//

import Foundation
import Cocoa

import Ink    // markdown support

class Publish
{
    struct PublishError: Error
    {
        let msg  : String
        let info : String
        let blog : String
    }
   
    
    func publishTask(blog:Blog, task: @escaping (Blog,SSH) throws -> Void) throws
    {
        guard let keypassword = Keys.getFromKeychain(name: blog.makekey())  else
        {
            throw PublishError(msg: "Failed to get key password", info:"foo", blog: blog.hostname)
        }
        let ssh = SSH(indentityfile: blog.privatekeypath, keypassword:keypassword, destusername: blog.loginname, destmachine: blog.hostname)
       
        try task(blog,ssh)
        
       
        Utils.writeDebugMsgToFile(msg:"publishTask: done")
    }
    
    
    func sendFile(blog:Blog, ssh:SSH, path:String, data:Data) throws
    {
        do
        {
            try ssh.writeFile(data:data, destfile: path)
        }
        catch
        {
           throw PublishError(msg: "sendFile failed to write file", info: path, blog: blog.nickname)
        }
        
        Utils.writeDebugMsgToFile(msg:"sendFile done: \(path)")
    }
   

    func sendArticleImages(blog:Blog, article:Article, images:[Image], ssh:SSH) throws
    {
        for image in images
        {
            let path = image.makePathOnServer(blog: blog)
            
            Utils.writeDebugMsgToFile(msg:"Sending image \(image.name)")
            
            do
            {
                try ssh.writeFile(data:image.imagedata,destfile: path)
            }
            catch
            {
                throw PublishError(msg: "send image failed", info: path, blog: blog.nickname)
            }
        }
        
        Utils.writeDebugMsgToFile(msg:"sendArticleImages done")
    }
    
    
    func sendArticle(blog:Blog, article:Article, ssh:SSH) throws
    {
        let parser = MarkdownParser()

        var articletext = parser.html(from: article.markdowntext)
        articletext = articletext.replacingOccurrences(of:AppDelegate.IMAGEDIR, with:"\(blog.address)/images")

        let articletitle = article.title
        let articleauthor = article.author

        let articledate = article.formatArticleDate()
        
        
        let articlenameonserver = article.makeArticleNameOnServer().addingPercentEncoding(withAllowedCharacters:.alphanumerics)
        
        let articlehtml = """
        <div id=\"article\">
        <span class=\"articletitle\">\(articletitle)</span><a class=\"chain\" href="\(blog.address)?article=\(articlenameonserver!)">&#9741;</a>
        <br />
        <span class=\"articleauthor\">\(articleauthor)</span> - <span  class=\"articledate\">\(articledate)</span><br />
        \(articletext )
        </div>
        """

        let path = article.makePathOnServer()
        let htmldata = Data(articlehtml.utf8)
       
        do
        {
            try ssh.writeFile(data:htmldata,destfile:path)
        }
        catch
        {
            throw PublishError(msg: "sendCurrentArticle failed to write file", info: path, blog: blog.nickname)
        }
        
        article.markAsPublished()
        
        Utils.writeDebugMsgToFile(msg:"sendCurrentArticle done: \(article.title)")
    }
    
    
    func deleteBlogFolderFromServer(blog:Blog) throws
    {
       try publishTask(blog: blog)
        { (blog, ssh:SSH) in
             
            do
            {
                try ssh.removeFile(atPath: "\(blog.remoteroot)/\(File.BLOGENGINE)")
                try ssh.removeFile(atPath: "\(blog.remoteroot)/\(File.INDEXHTML)")
                try ssh.removeFile(atPath: "\(blog.remoteroot)/\(File.STYLESCSS)")
            
                try ssh.removeDirectory(atPath: "\(blog.remoteroot)/articles")
                try ssh.removeDirectory(atPath: "\(blog.remoteroot)/images")
                try ssh.removeDirectory(atPath: blog.remoteroot)
            }
            catch
            {
                throw PublishError(msg: "deleteBlogFolderFromServer failed", info: blog.remoteroot, blog: blog.nickname)
            }
            
            Utils.writeDebugMsgToFile(msg:"deleteBlogFolderFromServer done: \(blog.remoteroot)")
        }
    }
    
    func deleteArticleFromServerByPath(blog:Blog,path:String) throws
    {
        try publishTask(blog: blog)
        { (blog, ssh:SSH) in
              
            do
            {
                try ssh.removeFile(atPath: path)
            }
            catch
            {
                throw PublishError(msg: "deleteArticleFromServerByPath failed", info: path, blog: blog.nickname)
            }
            
            Utils.writeDebugMsgToFile(msg:"deleteArticleFromServerByPath done: \(path)")
        }
    }
          
    
    func deleteArticleFromServer(blog:Blog, article:Article) throws
    {
        try publishTask(blog: blog)
        { (blog, ssh:SSH) in
               
            let path = article.makePathOnServer()
            do
            {
                
                try ssh.removeFile(atPath: path)
            }
            catch
            {
                 throw PublishError(msg: "deleteArticleFromServer failed", info: path, blog: blog.nickname)
            }
                
            Utils.writeDebugMsgToFile(msg:"deleteArticleFromServer done: \(article.title)")
        }
    }
    
    
    func deleteImagesFromServer(blog:Blog,images:[Image]) throws
    {
        try publishTask(blog: blog)
        { (blog, ssh:SSH) in
                   
            for image in images
            {
                let path = image.makePathOnServer(blog:blog)
                do
                {
                    try ssh.removeFile(atPath: path)
                }
                catch
                {
                    Utils.writeDebugMsgToFile(msg:"Error in deleteImagesFromServer: \(image.name)")
                    throw PublishError.init(msg: "Error in deleteImagesFromServer:", info: "\(image.name)", blog: blog.nickname)
                }
                
                Utils.writeDebugMsgToFile(msg:"deleteImagesFromServer done: \(image.name)")
            }
        }
    }
    

    func createBlogFoldersOnSever(blog:Blog,ssh:SSH) throws
    {
        do
        {
            try ssh.createDirectory(atPath:"\(blog.remoteroot)")
            try ssh.createDirectory(atPath:"\(blog.remoteroot)/articles")
            try ssh.createDirectory(atPath:"\(blog.remoteroot)/images")
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"Error creatinb folders on server: \(error)")
        }
    }
 
    
    func sendSupportFiles(blog:Blog,ssh:SSH) throws
    {
        try self.createBlogFoldersOnSever(blog: blog,ssh:ssh)
        
        if blog.css.changed.needsPublishing
        {
            try self.sendFile(blog: blog, ssh:ssh, path: "\(blog.remoteroot)/\(File.STYLESCSS)", data: Data(blog.css.filteredtext.utf8))
            blog.css.changed.needsPublishing = false
        }
        
        if blog.html.changed.needsPublishing
        {
            try self.sendFile(blog: blog, ssh:ssh, path: "\(blog.remoteroot)/\(File.INDEXHTML)", data: Data(blog.html.filteredtext.utf8))
            blog.html.changed.needsPublishing = false
        }
        
        if blog.engine.changed.needsPublishing
        {
            try self.sendFile(blog: blog, ssh:ssh, path: "\(blog.remoteroot)/\(File.BLOGENGINE)", data: Data(blog.engine.filteredtext.utf8))
            blog.engine.changed.needsPublishing = false
        }
        
        try self.sendFile(blog: blog, ssh:ssh, path: "\(blog.remoteroot)/rss.xml", data: Data(blog.exportRSS().utf8))
    }
    

    func sendAllArticles(blog:Blog) throws
    {
        try publishTask(blog: blog)
        { (blog:Blog,ssh:SSH) in
            
            for article in blog.articles
            {
                do
                {
                    let path = article.makePathOnServer()
                    try ssh.removeFile(atPath: path)
                }
                catch
                {
                    Utils.writeDebugMsgToFile(msg: "sendAllArticles: Error deleting article from server: \(article.title)")
                }
                    
                Utils.writeDebugMsgToFile(msg:"sendAllArticles: deleted article \(article.title) from sever")
            }
            
            try self.sendSupportFiles(blog: blog,ssh:ssh)
            
            for article in blog.articles
            {
                try self.sendArticle(blog: blog, article:article,ssh:ssh)
            }
        }
    }
    
    
    func sendArticleAndSupportFiles(blog:Blog, article:Article) throws
    {
        try publishTask(blog: blog)
        { (blog:Blog,ssh:SSH) in // you can put types in here!
        
            try self.sendSupportFiles(blog:blog,ssh:ssh)
            
            if article.changed.needsPublishing
            {
                try self.sendArticle(blog: blog, article:article,ssh:ssh)
                try self.sendArticleImages(blog: blog,article:article,images:article.images,ssh:ssh)
                
                article.changed.needsPublishing = false
            }
        }
    }
    
   
}

