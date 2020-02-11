//
//  DocWindow.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/24/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Cocoa

class DocWindow: NSWindowController
{
    @IBOutlet var docLabel: NSTextField!
    @IBOutlet var docTextView: NSTextView!
    
    var doc : Doc!
    
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        docTextView.font = NSFont.systemFont(ofSize: 17)
        docTextView.textColor = NSColor.black
        docTextView.backgroundColor = NSColor.lightGray
    }
    
    
    convenience init(doc: Doc)
    {
        self.init(windowNibName: "DocWindow")
        self.doc = doc
    }
    
    
    func show()
    {
        self.showWindow(self)
        
        docLabel.stringValue = doc.name
        docTextView.string = doc.getDoc() ?? "Not text found"
    }

}
