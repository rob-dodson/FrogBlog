//
//  Preview.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/28/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Foundation

class Preview
{
    var appsupportdir : URL!
    var previewdir    : URL!
    var imagedir      : URL!
    
    
    init()
    {
        do
        {
            appsupportdir = try FileManager.default.url(for: .applicationSupportDirectory,
                                                          in: .userDomainMask,
                                                          appropriateFor: nil,
                                                          create: true).appendingPathComponent("FrogBlog")
            
            previewdir = appsupportdir.appendingPathComponent("webpreview")
            imagedir = previewdir.appendingPathComponent("images")
            
			// this is the deepest directory so creating it will create all those above it
            try FileManager().createDirectory(at: imagedir,withIntermediateDirectories: true,attributes: nil)
            
            Utils.writeDebugMsgToFile(msg:"preview dir: \(previewdir.path)")
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"Preview init error: \(error)")
        }
    }
    
    
    func cleanPreviewDir()
    {
        do
        {
			// delete then recreate the preview directory
            try FileManager.default.removeItem(at: previewdir)
            try FileManager().createDirectory(at: imagedir,withIntermediateDirectories: true,attributes: nil)
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"Preview clean dir error: \(error)")
        }
    }
    
    
    func createPreviewHTMLFile(filename:String,htmltext:String)
    {
        FileManager.default.createFile(atPath: "\(previewdir.path)/\(filename).html",
            contents: htmltext.data(using: .utf8),
            attributes: nil)
    }
    
}

