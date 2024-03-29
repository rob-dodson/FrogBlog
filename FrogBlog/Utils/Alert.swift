//
//  Alert.swift
//
//
//  Created by Robert Dodson on 1/13/20.
//

import Foundation
import Cocoa


class Alert
{
    static func showAlertInWindow(window:NSWindow,
                           message:String,
                           info:String,
                           ok: @escaping () -> Void,
                           cancel: @escaping () -> Void)
    {
        let okcancelalert = NSAlert.init()
        
        okcancelalert.addButton(withTitle: "Ok")
        okcancelalert.addButton(withTitle: "Cancel")
        okcancelalert.messageText = message
        okcancelalert.informativeText = info
        okcancelalert.alertStyle = .critical
        
        let retval = okcancelalert.runModal()
        if retval == NSApplication.ModalResponse.alertFirstButtonReturn
                  {
                      ok()
                  }
                  else
                  {
                      cancel()
                  }
    }
    
}
