//
//  SSH.swift
//  FrogBlog
//
//  Created by Robert Dodson on 4/19/22.
//  Copyright © 2022 Robert Dodson. All rights reserved.
//

import Foundation


class SSH
{
    var indentityfile : String
    var keypassword   : String
    var destusername  : String
    var destmachine   : String
    
    
    init(indentityfile:String,keypassword:String,destusername:String,destmachine:String)
    {
        self.indentityfile = indentityfile
        self.keypassword = keypassword
        self.destusername = destusername
        self.destmachine = destmachine
        
        //
                   // add our ssh key to the ssh agent
                   //
                   let processaddkey = Process()
                   processaddkey.launchPath = "/usr/bin/ssh-add"
                   processaddkey.arguments = ["\(indentityfile)"]
                   var env = ProcessInfo.processInfo.environment
                   env.removeValue(forKey: "DISPLAY") // if DISPLAY not set, ssh-add will ask for a password on stdin, and we will write it to there.
                   processaddkey.environment = env
                   do
                   {
                        runprocessPassword(process:processaddkey, password:keypassword)
                   }
                   catch
                   {
                       Utils.writeDebugMsgToFile(msg:"Error getting password from keychain: \(error.localizedDescription)")
                       return
                   }
    }
    
    func writeFile(data:Data,destfile:String) throws
    {
        let desktop = URL(fileURLWithPath: "/tmp/FrogBlog")

        do {
            let temporaryDirectory = try FileManager.default.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: desktop,
                create: true
            )
            
            print(temporaryDirectory)
            let tempurl = URL(fileURLWithPath: "\(temporaryDirectory)/temp")
            try data.write(to: tempurl, options: [])
            
            let args: [String] = ["-i",indentityfile,tempurl.absoluteString, "\(destusername)@\(destmachine):\(destfile)"]
            
            try runSCP(args:args)
            
            try FileManager.default.removeItem(atPath: tempurl.absoluteString)
        }
        catch
        {
            
            // Handle the error.
        }
       
    }
    
    func writeFile(sourcefile:String,destfile:String) throws
    {
        let args: [String] = ["-i",indentityfile,sourcefile, "\(destusername)@\(destmachine):\(destfile)"]
        
        try runSCP(args:args)
    }
    
    func createDirectory(atPath:String) throws
    {
        let args: [String] = ["-i",indentityfile,"\(destusername)@\(destmachine)","mkdir -r \(atPath)"]
        
        try runSSH(args:args)
    }
    
    func removeFile(atPath:String) throws
    {
        let args: [String] = ["-i",indentityfile,"\(destusername)@\(destmachine)","rm \(atPath)"]
        
        try runSSH(args:args)
    }
    
    func removeDirectory(atPath:String) throws
    {
        let args: [String] = ["-i",indentityfile,"\(destusername)@\(destmachine)","rm -r \(atPath)"]
        
       try runSSH(args:args)
    }
    
    func runSCP(args:[String]) throws
    {
        let subprocess = Process.init()
        subprocess.launchPath = "/usr/bin/scp"
        subprocess.arguments = args
        try subprocess.run()
    }
    
    func runSSH(args:[String]) throws
    {
        let subprocess = Process.init()
        subprocess.launchPath = "/usr/bin/ssh"
        subprocess.arguments = args
        try subprocess.run()
    }
    
    
    func runprocessPassword(process:Process, password:String)
       {
           do
           {
               let writepipe = Pipe()
               process.standardInput = writepipe

               let readpipe = Pipe()
               let readerrpipe = Pipe()
               process.standardOutput = readpipe
               process.standardError = readerrpipe

               try process.run()


               DispatchQueue.global().async
               {
                   var morestderrddata = true
                   var morestdoutdata = true

                   repeat
                   {
                       let stderr_data : Data = readerrpipe.fileHandleForReading.availableData
                       if stderr_data.count > 0
                       {
                           if let stderr = String(data: stderr_data, encoding:.utf8)
                           {
                               self.logit(msg: stderr)
                           }
                       }
                       else
                       {
                           morestderrddata = false
                       }

                       let stdout_data : Data = readpipe.fileHandleForReading.availableData
                      if stdout_data.count > 0
                      {
                           if let stdout = String(data: stdout_data, encoding:.utf8)
                           {
                               self.logit(msg: stdout)
                           }
                      }
                      else
                      {
                          morestdoutdata = false
                      }


                   } while (morestdoutdata || morestderrddata)
               }

               writepipe.fileHandleForWriting.write(password.data(using:.utf8)!)
               writepipe.fileHandleForWriting.write("\n".data(using:.utf8)!)
           }
           catch
           {
               alert(msg: "password process error", info: error.localizedDescription)
           }
       }
    
}
