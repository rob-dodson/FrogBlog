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
import Shout  // SSH & SFTP code


class Publish
{
    struct PublishError: Error
    {
        let msg  : String
        let info : String
        let blog : String
    }

    
    func sendFile(blog:Blog, ftp:SFTP, path:String, data:Data) throws
    {
        try ftp.upload(data: data, remotePath: path)
        
        Utils.writeDebugMsgToFile(msg:"sendFile done: \(path)")
    }
    

    func sendArticleImages(blog:Blog, article:Article, images:[Image], ftp:SFTP) throws
    {
        for image in images
        {
            let path = image.makePathOnServer(blog: blog)
            
            Utils.writeDebugMsgToFile(msg:"Sending image \(image.name)")
            
            try ftp.upload(data: image.imagedata, remotePath: path)
        }
        
        Utils.writeDebugMsgToFile(msg:"sendArticleImages done")
    }
    
    
    func sendArticle(blog:Blog, article:Article, ftp:SFTP) throws
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
       
        try ftp.upload(data: htmldata, remotePath: path)
        
        article.markAsPublished()
        
        Utils.writeDebugMsgToFile(msg:"sendCurrentArticle done: \(article.title)")
    }
    
    
    func deleteBlogFolderFromServer(blog:Blog) throws
    {
       try publishTask(blog: blog)
        { (blog, sftp) in
             
            try sftp.removeFile("\(blog.remoteroot)/\(File.BLOGENGINE)")
            try sftp.removeFile("\(blog.remoteroot)/\(File.INDEXHTML)")
            try sftp.removeFile("\(blog.remoteroot)/\(File.STYLESCSS)")
            
            try sftp.removeDirectory("\(blog.remoteroot)/articles")
            try sftp.removeDirectory("\(blog.remoteroot)/images")
        
            Utils.writeDebugMsgToFile(msg:"deleteBlogFolderFromServer done: \(blog.remoteroot)")
        }
    }
    
    
    func deleteArticleFromServerByPath(blog:Blog,path:String) throws
    {
        try publishTask(blog: blog)
        { (blog, sftp) in
              
            try sftp.removeFile(path)
            
            Utils.writeDebugMsgToFile(msg:"deleteArticleFromServerByPath done: \(path)")
        }
    }
    
    
    func deleteArticleFromServer(blog:Blog, article:Article) throws
    {
        try publishTask(blog: blog)
        { (blog, sftp) in
                    
            let path = article.makePathOnServer()
            try sftp.removeFile(path)
            
            Utils.writeDebugMsgToFile(msg:"deleteArticleFromServer done: \(article.title)")
        }
    }
    
    
    func deleteAllArticlesFromServer(blog:Blog) throws
    {
        try publishTask(blog: blog)
        { (blog, sftp) in
                    
            let filesonserver = try sftp.listFiles(in: "\(blog.remoteroot)/articles")
            for file in filesonserver.keys
            {
                if file == "." { continue }
                if file == ".." { continue }
                
                try sftp.removeFile("\(blog.remoteroot)/articles/\(file)")
                Utils.writeDebugMsgToFile(msg:"deleteArticleFromServer done: \(file)")
            }
            
            Utils.writeDebugMsgToFile(msg:"deleteAllArticlesFromServer done")
        }
    }
    
    
    func deleteAllImagesFromServer(blog:Blog) throws
    {
        try publishTask(blog: blog)
        { (blog, sftp) in
                   
            for article in blog.articles
            {
                for image in article.images
                {
                    let path = image.makePathOnServer(blog:blog)
                    try sftp.removeFile(path)
                    
                    Utils.writeDebugMsgToFile(msg:"deleteImageFromServer done: \(image.name)")
                }
            }
            
            Utils.writeDebugMsgToFile(msg:"deleteAllImagesFromServer done")
        }
    }
    
    
    func deleteImagesFromServer(blog:Blog,images:[Image]) throws
    {
        try publishTask(blog: blog)
        { (blog, sftp) in
                   
            for image in images
            {
                let path = image.makePathOnServer(blog:blog)
                try sftp.removeFile(path)
                
                Utils.writeDebugMsgToFile(msg:"deleteImagesFromServer done: \(image.name)")
            }
        }
    }
    

    func createBlogFoldersOnSever(blog:Blog,ftp:SFTP)
    {
        do
        {
            try ftp.createDirectory("\(blog.remoteroot)")
            try ftp.createDirectory("\(blog.remoteroot)/articles")
            try ftp.createDirectory("\(blog.remoteroot)/images")
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"Error : createBlogFoldersOnSever [Folders already exist?]: \(error.localizedDescription)")
        }
    }
    
    func uploadAllSupportFiles(blog: Blog) throws
    {
        try publishTask(blog: blog)
        { (blog:Blog, sftp:SFTP) in
            
            try self.uploadallsupportfiles(blog: blog, ftp: sftp)
        }
    }
    
    func uploadallsupportfiles(blog:Blog,ftp:SFTP) throws
    {
        try self.sendFile(blog: blog, ftp: ftp, path: "\(blog.remoteroot)/\(File.STYLESCSS)", data: Data(blog.css.filteredtext.utf8))
        try self.sendFile(blog: blog, ftp: ftp, path: "\(blog.remoteroot)/\(File.INDEXHTML)", data: Data(blog.html.filteredtext.utf8))
        try self.sendFile(blog: blog, ftp: ftp, path: "\(blog.remoteroot)/\(File.BLOGENGINE)", data: Data(blog.engine.filteredtext.utf8))
    }
    
    func sendSupportFiles(blog:Blog,ftp:SFTP) throws
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
        { (blog:Blog, sftp:SFTP) in
            
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
        { (blog:Blog, sftp:SFTP) in // you can put types in here!
        
            try self.sendSupportFiles(blog: blog, ftp: sftp)
            
            if article.changed.needsPublishing
            {
                try self.sendArticle(blog: blog, article:article, ftp: sftp)
                try self.sendArticleImages(blog: blog, article:article, images:article.images, ftp: sftp)
                
                article.changed.needsPublishing = false
            }
        }
    }
    
    
    func publishTask(blog:Blog, task: @escaping (Blog,SFTP) throws -> Void) throws
    {
        let ssh : SSH!
        
        do
        {
            ssh = try SSH(host: blog.hostname)
            
            var keypassword = Keys.getFromKeychain(name: blog.makekey())
            
            try ssh.authenticate(username: blog.loginname, privateKey: blog.privatekeypath, publicKey: blog.publickeypath, passphrase: keypassword)
            
            keypassword = String("") // erase the password from memory
            
            let sftp = try ssh.openSftp()
            
            try task(blog,sftp)

			Utils.writeDebugMsgToFile(msg:"publishTask: done")
        }
        catch
        {
            throw PublishError(msg: "Failed to connect!", info: "\(error)", blog: "\(blog.nickname) at \(blog.hostname)")
        }
    }
}

