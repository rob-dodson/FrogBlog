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

import NMSSH  // sftp code
import Ink    // markdown support


class Publish
{
    struct PublishError: Error
    {
        let msg  : String
        let info : String
        let blog : String
    }

    
    func sendFile(blog:Blog, ftp:NMSFTP, path:String, data:Data) throws
    {
        let result = ftp.writeContents(data, toFileAtPath: path)
        if result == false
        {
           throw PublishError(msg: "sendFile failed to write file", info: path, blog: blog.nickname)
        }
        
        Utils.writeDebugMsgToFile(msg:"sendFile done: \(path)")
    }
   

    func sendArticleImages(blog:Blog, article:Article, images:[Image], ftp:NMSFTP) throws
    {
        for image in images
        {
            let path = image.makePathOnServer(blog: blog)
            
            Utils.writeDebugMsgToFile(msg:"Sending image \(image.name)")
            
            let result = ftp.writeContents(image.imagedata,toFileAtPath:path)
            if result == false
            {
                throw PublishError(msg: "send image failed", info: path, blog: blog.nickname)
            }
        }
        
        Utils.writeDebugMsgToFile(msg:"sendArticleImages done")
    }
    
    
    func sendArticle(blog:Blog, article:Article, ftp:NMSFTP) throws
    {
        let parser = MarkdownParser()

        var articletext = parser.html(from: article.markdowntext)
        articletext = articletext.replacingOccurrences(of:"IMAGEDIR",  with:"\(blog.address)/images")

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
       
        let result = ftp.writeContents(htmldata,toFileAtPath:path)
        if result == false
        {
            throw PublishError(msg: "sendCurrentArticle failed to write file", info: path, blog: blog.nickname)
        }
        
        article.markAsPublished()
        
        Utils.writeDebugMsgToFile(msg:"sendCurrentArticle done: \(article.title)")
    }
    
    
    func deleteBlogFolderFromServer(blog:Blog) throws
    {
       try publishTask(blog: blog)
        { (blog, sftp, session) in
             
            sftp.removeFile(atPath: "\(blog.remoteroot)/\(File.BLOGENGINE)")
            sftp.removeFile(atPath: "\(blog.remoteroot)/\(File.INDEXHTML)")
            sftp.removeFile(atPath: "\(blog.remoteroot)/\(File.STYLESCSS)")
            
            sftp.removeDirectory(atPath: "\(blog.remoteroot)/articles")
            sftp.removeDirectory(atPath: "\(blog.remoteroot)/images")
            let result = sftp.removeDirectory(atPath: blog.remoteroot)
            if result == false
            {
               throw PublishError(msg: "deleteBlogFolderFromServer failed", info: blog.remoteroot, blog: blog.nickname)
            }
            else
            {
                Utils.writeDebugMsgToFile(msg:"deleteBlogFolderFromServer done: \(blog.remoteroot)")
            }
        }
    }
    
    func deleteArticleFromServerByPath(blog:Blog,path:String) throws
    {
        try publishTask(blog: blog)
        { (blog, sftp, session) in
              
            let result = sftp.removeFile(atPath: path)
            if result == false
            {
               throw PublishError(msg: "deleteArticleFromServerByPath failed", info: path, blog: blog.nickname)
            }
            else
            {
              Utils.writeDebugMsgToFile(msg:"deleteArticleFromServerByPath done: \(path)")
            }
        }
    }
          
    
    func deleteArticleFromServer(blog:Blog, article:Article) throws
    {
        try publishTask(blog: blog)
        { (blog, sftp, session) in
                    
            let path = article.makePathOnServer()
            let result = sftp.removeFile(atPath: path)
            if result == false
            {
                 throw PublishError(msg: "deleteArticleFromServer failed", info: path, blog: blog.nickname)
            }
            else
            {
                Utils.writeDebugMsgToFile(msg:"deleteArticleFromServer done: \(article.title)")
            }
        }
    }
    
    
    func deleteImagesFromServer(blog:Blog,images:[Image]) throws
    {
        try publishTask(blog: blog)
        { (blog, sftp, session) in
                   
            for image in images
            {
                let path = image.makePathOnServer(blog:blog)
                let result = sftp.removeFile(atPath: path)
                
                if result == false
                {
                    Utils.writeDebugMsgToFile(msg:"Error in deleteImagesFromServer: \(image.name)")
                    throw PublishError.init(msg: "Error in deleteImagesFromServer:", info: "\(image.name)", blog: blog.nickname)
                }
                else
                {
                    Utils.writeDebugMsgToFile(msg:"deleteImagesFromServer done: \(image.name)")
                }
            }
        }
    }
    

    func createBlogFoldersOnSever(blog:Blog,ftp:NMSFTP)
    {
        ftp.createDirectory(atPath:"\(blog.remoteroot)")
        ftp.createDirectory(atPath:"\(blog.remoteroot)/articles")
        ftp.createDirectory(atPath:"\(blog.remoteroot)/images")
    }
 
    
    func sendSupportFiles(blog:Blog,ftp:NMSFTP) throws
    {
        self.createBlogFoldersOnSever(blog: blog, ftp: ftp)
        
        if blog.css.changed.needsPublishing
        {
            try self.sendFile(blog: blog, ftp: ftp, path: "\(blog.remoteroot)/\(File.STYLESCSS)", data: Data(blog.css.filteredtext.utf8))
            blog.css.changed.needsPublishing = false
        }
        
        if blog.html.changed.needsPublishing
        {
            try self.sendFile(blog: blog, ftp: ftp, path: "\(blog.remoteroot)/\(File.INDEXHTML)", data: Data(blog.html.filteredtext.utf8))
            blog.html.changed.needsPublishing = false
        }
        
        if blog.engine.changed.needsPublishing
        {
            try self.sendFile(blog: blog, ftp: ftp, path: "\(blog.remoteroot)/\(File.BLOGENGINE)", data: Data(blog.engine.filteredtext.utf8))
            blog.engine.changed.needsPublishing = false
        }
        
        try self.sendFile(blog: blog, ftp: ftp, path: "\(blog.remoteroot)/rss.xml", data: Data(blog.exportRSS().utf8))
    }
    

    func sendAllArticles(blog:Blog) throws
    {
        try publishTask(blog: blog)
        { (blog:Blog, sftp:NMSFTP, session:NMSSHSession) in
            
            for article in blog.articles
            {
                let path = article.makePathOnServer()
                let result = sftp.removeFile(atPath: path)
                if result == false
                {
                    Utils.writeDebugMsgToFile(msg: "sendAllArticles: Error deleting article from server: \(article.title)")
                }
                else
                {
                    Utils.writeDebugMsgToFile(msg:"sendAllArticles: deleted article \(article.title) from sever")
                }
            }
            
            try self.sendSupportFiles(blog: blog, ftp: sftp)
            
            for article in blog.articles
            {
                try self.sendArticle(blog: blog, article:article, ftp: sftp)
            }
        }
    }
    
    
    func sendArticleAndSupportFiles(blog:Blog, article:Article) throws
    {
        try publishTask(blog: blog)
        { (blog:Blog, sftp:NMSFTP, session:NMSSHSession) in // you can put types in here!
        
            try self.sendSupportFiles(blog: blog, ftp: sftp)
            
            if article.changed.needsPublishing
            {
                try self.sendArticle(blog: blog, article:article, ftp: sftp)
                try self.sendArticleImages(blog: blog, article:article, images:article.images, ftp: sftp)
                
                article.changed.needsPublishing = false
            }
        }
    }
    
    
    func publishTask(blog:Blog, task: @escaping (Blog,NMSFTP,NMSSHSession) throws -> Void) throws
    {
        let session = NMSSHSession(host: blog.hostname,
                                   andUsername: blog.loginname)
        session.connect()
        if (session.isConnected == true)
        {
            Utils.writeDebugMsgToFile(msg:"publishTask: connected")
            
            var keypassword = Keys.getFromKeychain(name: blog.makekey())
            
            session.authenticate(byPublicKey: blog.publickeypath,
                                 privateKey: blog.privatekeypath,
                                 andPassword: keypassword)
            keypassword = String("") // erase the password from memory
            
            if (session.isAuthorized == true)
            {
                Utils.writeDebugMsgToFile(msg:"publishTask: We're AUTHed");
                
                let sftp = NMSFTP(session: session)
                sftp.connect() // took a while to notice I needed to do this call.
                
                try task(blog,sftp,session)
                
                sftp.disconnect()
            }
            else
            {
                throw PublishError(msg: "Failed to authorise", info:session.lastError.debugDescription, blog: blog.hostname)
            }
        }
        else
        {
            throw PublishError(msg: "Failed to connect", info:session.lastError.debugDescription, blog: blog.hostname)
        }
        
        session.disconnect();
        
        Utils.writeDebugMsgToFile(msg:"publishTask: done")
    }
    
}

