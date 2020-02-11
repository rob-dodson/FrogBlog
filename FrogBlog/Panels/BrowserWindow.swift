//
//  BrowserWindow.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/24/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Cocoa
import WebKit


class BrowserWindow: NSWindowController
{
    @IBOutlet var docLabel: NSTextField!
    @IBOutlet var webView: WKWebView!
    
    
    var doc : Doc!
    
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
    }
      
    
    convenience init(doc: Doc)
    {
        self.init(windowNibName: "BrowserWindow")
        self.doc = doc
    }
    
    
    func show()
    {
        self.showWindow(self)
        
        docLabel.stringValue = doc.name
        webView.load(URLRequest(url: URL(string: doc.filename)!))
    }

}
