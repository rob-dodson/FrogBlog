//
//  Doc.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/24/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Foundation

class Doc
{
    var name     : String
    var filename : String

    init(name:String,filename:String)
    {
        self.name = name
        self.filename = filename
    }
    
    
    func getDoc() -> String?
    {
        guard let path = Bundle.main.path(forResource:filename, ofType:nil) else { return nil }

        var filetext : String

        do
        {
            filetext = try String(contentsOfFile: path)
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"Error getting file \(filename): \(error)")
            return nil
        }

        return filetext
    }

}
    
