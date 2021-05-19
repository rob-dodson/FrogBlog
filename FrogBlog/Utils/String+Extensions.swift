//
//  String+Extensions.swift
//  RobToolsLibrary
//
//  Created by Robert Dodson on 5/12/20.
//  Copyright © 2020 Shy Frog Productions LLC. All rights reserved.
//

import Foundation

extension String
{
    
    public func matchRegex(regex: String) throws -> [NSTextCheckingResult]
    {
        let re = try NSRegularExpression(pattern: regex, options: [])
        return re.matches(in: self, options:[], range:NSMakeRange(0,self.count))
    }
    
    
    public func match(regex: String) -> [[String]]
    {
        let nsString = self as NSString
        
        do
        {
            let re = try NSRegularExpression(pattern: regex,options: [])
            
            let matches = re.matches(in:self, options:[], range:NSMakeRange(0, count)).map
            { match in
                (0..<match.numberOfRanges).map
                {
                    match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0))
                }
            }
            
            return matches
        }
        catch
        {
            return []
        }
    }

    
    static func random(_ n:Int) -> Int
    {
        return Int(arc4random_uniform(UInt32(n)))
    }

    
    public static func generatePassword(size:UInt8) -> String
    {
        let symbols: Array<String> = ["@","#","$","%", ".", "!", "\"", "&", "\'", "(", ")", "*", "+", ",", "-", "/", ":", ";", "<", "=", ">", "?", "[", "\\", "]", "^", "_", "`", "{", "|", "}", "~"]
        let letters: Array<String> = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
        let numbers: Array<String> = ["0","1","2","3","4","5","6","7","8","9"]
        var characters: Array<String>

        characters = symbols + letters + numbers
        var password: String = ""
        
        for _ in 0...size
        {
            if(random(2) == 1)
            {
                password += characters[random(characters.count)].uppercased()
            }
            else
            {
                password += characters[random(characters.count)]
            }
        }

        return password
    }
    

    
    public func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>?
    {
        return Range(nsRange, in: self)
    }
    
    
    //
    // do we want these?
    //
    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    public func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    public func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

