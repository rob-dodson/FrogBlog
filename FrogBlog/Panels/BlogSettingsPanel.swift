//
//  ServerSettings.swift
//  FrogBlog
//
//  Created by Robert Dodson on 1/10/20.
//  Copyright © 2020 Robert Dodson. All rights reserved.
//

import Cocoa
import PwGen


class ServerSettingsPanel: NSWindowController
{
    @IBOutlet var nicknameTextfield: NSTextField!
    @IBOutlet var titleTextField: NSTextField!
    @IBOutlet var subTitleTextField: NSTextField!
    @IBOutlet var addressTextField: NSTextField!
    @IBOutlet var authorTextField: NSTextField!
    @IBOutlet var remotePathTextfield: NSTextField!
    @IBOutlet var serverLoginNameTextField: NSTextField!
    @IBOutlet var publicKeyPathTextfield: NSTextField!
    @IBOutlet var privateKeyPathTextField: NSTextField!
    @IBOutlet var keyPasswordTextfield: NSSecureTextField!
    @IBOutlet var serverTextField: NSTextField!
    @IBOutlet var showKeyButton: NSButton!
    @IBOutlet var unsecureKeyPasswordField: NSTextField!
    
    var theblog:Blog!
    var theappwindow:NSWindow!
    var overridepublickeypassword:String?
    
    convenience init(blog: Blog,window:NSWindow)
    {
        self.init(windowNibName: "BlogSettingsPanel")
        
        theblog = blog
        theappwindow = window
    }


    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        UIFromBlog(blog: theblog)
    }
    
    
    func setPublicKeyPassword(key:String)
    {
        overridepublickeypassword = key
    }
    
    
    func UIFromBlog(blog:Blog)
    {
        nicknameTextfield.stringValue        = blog.nickname
        titleTextField.stringValue           = blog.title
        subTitleTextField.stringValue        = blog.subtitle
        addressTextField.stringValue         = blog.address
        authorTextField.stringValue          = blog.author
        serverTextField.stringValue          = blog.hostname
        remotePathTextfield.stringValue      = blog.remoteroot
        serverLoginNameTextField.stringValue = blog.loginname
        publicKeyPathTextfield.stringValue   = blog.publickeypath
        privateKeyPathTextField.stringValue  = blog.privatekeypath
        
        if overridepublickeypassword != nil
        {
            keyPasswordTextfield.stringValue = overridepublickeypassword ?? "XXX"
        }
        else
        {
            keyPasswordTextfield.stringValue = Keys.getFromKeychain(name:blog.makekey()) ?? ""
        }
    }
    
    
    func show(doneBlock: @escaping (Blog) -> Void)
    {
        theappwindow.beginSheet(self.window!)
        { (returncode) in
            if returncode == NSApplication.ModalResponse.OK
            {
                doneBlock(self.theblog);
            }
        }
    }
    
    
    @IBAction func showKeyAction(_ sender: Any)
    {
        let state = showKeyButton.state
        if state == .on
        {
            showKeyButton.title = "Hide Key"
            keyPasswordTextfield.isHidden = true
            unsecureKeyPasswordField.isHidden = false
            unsecureKeyPasswordField.stringValue = keyPasswordTextfield.stringValue
        }
        else
        {
            showKeyButton.title = "Show Key"
            showKeyButton.state = .off
            keyPasswordTextfield.isHidden = false
            unsecureKeyPasswordField.isHidden = true
            unsecureKeyPasswordField.stringValue = ""
        }
    }
    
    
    @IBAction func saveButtonAction(_ sender: Any)
    {
        theblog.nickname       = nicknameTextfield.stringValue
        theblog.title          = titleTextField.stringValue
        theblog.subtitle       = subTitleTextField.stringValue
        theblog.address        = addressTextField.stringValue
        theblog.author         = authorTextField.stringValue
        theblog.hostname       = serverTextField.stringValue
        theblog.remoteroot     = remotePathTextfield.stringValue
        theblog.loginname      = serverLoginNameTextField.stringValue
        theblog.publickeypath  = publicKeyPathTextfield.stringValue
        theblog.privatekeypath = privateKeyPathTextField.stringValue
        
        //
        // validate --------------
        //
        theblog.nickname = theblog.nickname.replacingOccurrences(of: " ", with: "")
        theblog.publickeypath = NSString(string:theblog.publickeypath).expandingTildeInPath
        theblog.privatekeypath = NSString(string:theblog.privatekeypath).expandingTildeInPath
      
        let straddress : NSString = theblog.address as NSString
        let strremote  : NSString = theblog.remoteroot as NSString
        if (straddress.lastPathComponent != strremote.lastPathComponent)
        {
            Alert.showAlertInWindow(window: self.window!, message: "Blog Address and Remote Folder must end in the same name:",
                                    info: "\"\(straddress.lastPathComponent)\" is not equal to \"\(strremote.lastPathComponent)\"", ok: {}, cancel: {})
            return;
        }
        //
        // validate --------------
        //
        
        
        //
        // Store key password in Keychain
        //
        Keys.storeInKeychain(name: theblog.makekey(), value: keyPasswordTextfield.stringValue)

        self.window?.sheetParent!.endSheet(self.window!, returnCode: .OK)
    }
    
    
    @IBAction func cancelButtonAction(_ sender: Any)
    {
        self.window?.sheetParent!.endSheet(self.window!, returnCode: .cancel)
    }
    
   
    @IBAction func copyPublicKeyAction(_ sender: Any)
    {
        do
        {
            NSPasteboard.general.clearContents()
            let publickey = try String.init(contentsOfFile: publicKeyPathTextfield.stringValue)
            NSPasteboard.general.setString(publickey, forType: NSPasteboard.PasteboardType.string)
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"copy pub key error \(error)")
        }
    }
    
    
    @IBAction func createKeyButtonAction(_ sender: Any)
    {
        do
        {
            let info = ProcessInfo.processInfo
            let comment = String.init(format: "%@-%@", theblog.nickname,info.hostName)
            let keypassword = try PwGen().ofSize(20).withoutCharacter(" ").generate()
            
            let keyfilename = nicknameTextfield.stringValue.trimmingCharacters(in: .whitespaces)
            var keyfile = String("~/.ssh/\(keyfilename)")
            keyfile = NSString(string:keyfile).expandingTildeInPath
            
            var cancel : Bool = false
            let filemanager = FileManager()
            if (filemanager.fileExists(atPath: keyfile))
            {
                Alert.showAlertInWindow(window: theappwindow,
                                        message: "These keys already exist: \(keyfile).",
                                        info: "Do you want to overwrite them?",
                                        ok:
                                        {
                                            do
                                            {
                                                try filemanager.removeItem(atPath: keyfile)
                                            }
                                            catch
                                            {
                                                Utils.writeDebugMsgToFile(msg:"Error deleting keys")
                                            }
                                        },
                                        cancel:
                                        {
                                            cancel = true
                                        })
            }
            
            if cancel == true
            {
                return
            }
            
            
            let subprocess = Process.init()
            let args: [String] = ["-t", "rsa", "-f", keyfile,"-N", keypassword,"-C",comment,"-m","PEM"]
            subprocess.launchPath = "/usr/bin/ssh-keygen"
            subprocess.arguments = args
            try subprocess.run()
            
            keyPasswordTextfield.stringValue = keypassword
            publicKeyPathTextfield.stringValue = String.init(format: "%@.pub", keyfile)
            privateKeyPathTextField.stringValue = keyfile
            Utils.writeDebugMsgToFile(msg:"ssh-keygen done")
        }
        catch
        {
            Utils.writeDebugMsgToFile(msg:"process error: \(error)")
        }
    }
    
    
    
    @IBAction func publicKeyFileOpenAction(_ sender: Any)
    {
        Utils.pickfile(title:"Select a Public Key",folders:false,startfolder:"~/.ssh")
        { (keyfile) in
            self.publicKeyPathTextfield.stringValue = keyfile
        }
    }
    
    
    @IBAction func privateKeyFileOpen(_ sender: Any)
    {
        Utils.pickfile(title: "Select a Private Key",folders:false,startfolder:"~/.ssh")
        { (keyfile) in
            self.privateKeyPathTextField.stringValue = keyfile
        }
    }
    
}
