//
//  ProgressPanel.swift
//  FrogBlog
//
//  Created by Robert Dodson on 7/25/22.
//  Copyright © 2022 Robert Dodson. All rights reserved.
//

import Cocoa

class ProgressPanel: NSWindowController {

    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var text: NSTextField!
    
    var max : Double = 10.0
    var msg : String = "Progess"
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        let frame = NSApplication.shared.mainWindow?.frame
        let point = NSPoint(x: frame?.midX ?? 100.0, y: frame?.midY ?? 100.0)
        self.window?.setFrameOrigin(point)
        
        progress.minValue = 0
        progress.maxValue = max
        progress.doubleValue = 0
        
        text.stringValue = msg
    }
    
    convenience init(message:String,maxcount:Int)
    {
        self.init(windowNibName: "ProgressPanel")
       
        
        msg = message
        max = Double(maxcount)
    }
    
    func increment(amount:Int)
    {
        DispatchQueue.main.sync
        {
            self.progress.increment(by: Double(amount))
        }
    }
    
    func show()
    {
        self.showWindow(self)
    }
    
    override func close()
    {
        sleep(1) // let progress bar show the last increment before closing
        self.window?.close()
    }
    
   
}
