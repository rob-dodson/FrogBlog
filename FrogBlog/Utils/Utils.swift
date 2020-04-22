//
//  Utils.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/21/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Foundation

//
//  Utils.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/21/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//
import Cocoa
import Foundation

class Utils
{
    static func savefile(title:String, folders:Bool, startfolder:String, filepicked: @escaping (String) -> Void)
    {
        let filepanel = NSSavePanel()

        filepanel.title = title
        filepanel.message = "\(title) to text file"
        filepanel.nameFieldLabel = "Export file name:"
        filepanel.prompt = "Export"
        filepanel.showsHiddenFiles = false
        filepanel.directoryURL = URL.init(string:startfolder)
        filepanel.canCreateDirectories = true;

        filepanel.begin
        { (retval) in
            if (retval == NSApplication.ModalResponse.OK)
            {
                filepicked(filepanel.url!.path)
            }
        }
    }
    
    
    static func pickfile(title:String, folders:Bool, startfolder:String, filepicked: @escaping (String) -> Void)
    {
        let filepanel = NSOpenPanel()

        filepanel.canChooseDirectories = folders
        filepanel.allowsMultipleSelection = false
        filepanel.message = title
        filepanel.prompt = "Use"
        filepanel.showsHiddenFiles = false
        filepanel.directoryURL = URL.init(string:startfolder)
        filepanel.canCreateDirectories = true;

        filepanel.begin
        { (retval) in
            if (retval == NSApplication.ModalResponse.OK)
            {
                filepicked(filepanel.url!.path)
            }
        }
    }
    
    
    static func filterHtmlText(blog:Blog,text:String) -> String
    {
        var newfiletext = text.replacingOccurrences(of: "BLOG_TITLE_HERE", with: blog.title)
        newfiletext = newfiletext.replacingOccurrences(of: "SUBTITLE_HERE", with: blog.subtitle)
        newfiletext = newfiletext.replacingOccurrences(of: "AUTHOR_HERE", with: blog.author)
        newfiletext = newfiletext.replacingOccurrences(of: "BLOGPATH_HERE", with: blog.address)

        return newfiletext
    }
    
    
    static func resizeImage(image: NSImage, minimumSize:CGFloat) -> NSImage
    {
        let ratio = image.size.height / image.size.width

        let width: CGFloat
        let height: CGFloat

        if ratio > 1 // Portrait orientation, let's make it smaller
        {
            width = (minimumSize * 0.5)
            height = (minimumSize * 0.5) * ratio
        }
        else
        {
            width = minimumSize
            height = minimumSize * ratio
        }
        
        let destSize = NSSize(width: width, height: height)

        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: destSize.width, height: destSize.height),
                   from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
                   operation: .sourceOver, fraction: 1.0)
        newImage.unlockFocus()
        newImage.size = destSize
        
        return NSImage(data: newImage.tiffRepresentation!)!
    }

    
    static func getImageData(imagename:String,nsimage:NSImage) -> Data?
    {
        if let imgRep = nsimage.representations[0] as? NSBitmapImageRep
        {
            var filetype : NSBitmapImageRep.FileType!
            
            if imagename.lowercased().hasSuffix(".png")
            {
                filetype = NSBitmapImageRep.FileType.png
            }
            else if imagename.lowercased().hasSuffix(".jpg") || imagename.lowercased().hasSuffix(".jpeg")
            {
                filetype = NSBitmapImageRep.FileType.jpeg
            }
            else if imagename.lowercased().hasSuffix(".gif")
            {
                filetype = NSBitmapImageRep.FileType.gif
            }
            
            if let data = imgRep.representation(using: filetype, properties: [:])
            {
                return data
            }
        }
        
        return nil
    }
    
    static func getRSSDateFormatter() -> DateFormatter
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
        dateFormatter.timeZone = TimeZone.current
           
        return dateFormatter
    }
    
    static func getDateFormatter() -> ISO8601DateFormatter
    {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate,.withFullTime,.withSpaceBetweenDateAndTime]
        dateFormatter.timeZone = TimeZone.current
        
        return dateFormatter
    }

    static func writeDebugMsgToFile(msg:String)
    {
        Utils.writeDebugMsgToFile(msg: msg, rewindfile: false)
    }
    
    
    static func writeDebugMsgToFile(msg:String, rewindfile:Bool)
    {
       NSLog("debug: \(msg)")
        
        do
        {
           //let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            
            let fileName = "/tmp/FrogBlogDebug.txt"
            let logmsg = "\(Date().description): \(msg)"
            
            if rewindfile == true
            {
                try FileManager.default.removeItem(atPath: fileName)
            }

            if FileManager.default.fileExists(atPath: fileName) == false
            {
                FileManager.default.createFile(atPath: fileName, contents: nil, attributes: nil)
            }

            guard let file = FileHandle.init(forWritingAtPath: fileName) else { return }
            file.seekToEndOfFile()
            file.write(logmsg.data(using: .utf8)!)
            file.write("\n".data(using: .utf8)!)
            file.closeFile()
        }
        catch
        {
            NSLog("write to debug file failed. error: \(error) - msg: \(msg)")
        }
    }

}
