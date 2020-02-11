public class PwGen{
    private struct RuntimeError: Error {
        let message: String
        
        init(_ message: String) {
            self.message = message
        }
    }
    
    private let defaultUppercase: Bool = true
    private var useUppercase: Bool
    
    private let defaultSize: UInt8 = 12
    private var size: UInt8
    
    private let symbols: Array<String> = ["@","#","$","%", " ", ".", "!", "\"", "&", "\'", "(", ")", "*", "+", ",", "-", "/", ":", ";", "<", "=", ">", "?", "[", "\\", "]", "^", "_", "`", "{", "|", "}", "~"]
    private let letters: Array<String> = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
    private let numbers: Array<String> = ["0","1","2","3","4","5","6","7","8","9"]
    
    private var characters: Array<String>
    
    public init(){
        self.useUppercase = self.defaultUppercase
        self.size = self.defaultSize
        self.characters = self.symbols + self.letters + self.numbers
    }
    
    private func random(_ n:Int) -> Int
    {
        return Int(arc4random_uniform(UInt32(n)))
    }
    
    public func generate() throws -> String{
        var password: String = ""
        
        if self.characters.count == 0{
            throw RuntimeError("Cannot generate a password with all characters filtered out")
        }
        
        if self.size == 0{
            throw RuntimeError("Cannot generate a password of size 0")
        }
        
        if(self.useUppercase){
            for _ in 0..<self.size {
                if(random(2) == 1){
                    password += self.characters[random(self.characters.count)].uppercased()
                }
                else{
                    password += self.characters[random(self.characters.count)]
                }
            }
        }
        else{
            for _ in 0..<self.size {
                password += self.characters[random(self.characters.count)]
            }
        }
        
        return password
    }
    
    public func ofSize(_ size : UInt8) -> PwGen{
        self.size = size
        return self
    }
    
    public func withoutNumbers() -> PwGen{
        for number in self.numbers{
            self.characters = self.characters.filter{$0 != number}
        }
        return self
    }
    
    public func withoutLetters() -> PwGen{
        for letter in self.letters{
            self.characters = self.characters.filter{$0 != letter}
        }
        return self
    }
    
    public func withoutSymbols() -> PwGen{
        for symbol in self.symbols{
            self.characters = self.characters.filter{$0 != symbol}
        }
        return self
    }
    
    public func withoutUppercase() -> PwGen{
        self.useUppercase = false
        return self
    }
    
    public func withoutCharacter(_ character : String) -> PwGen{
        self.characters = self.characters.filter{$0 != character.lowercased()}
        return self
    }
    
    public func withoutCharacters(_ characters : Array<String>) -> PwGen{
        for character in characters{
            self.characters = self.characters.filter{$0 != character.lowercased()}
        }
        return self
    }
    
    public func addCharacter(_ character : String) -> PwGen{
        if character.count == 1{
            if !self.characters.contains(character.lowercased()){
                self.characters.append(character.lowercased())
            }
        }
        return self
    }
    
    public func addCharacters(_ characters : Array<String>) -> PwGen{
        for character in characters{
            if character.count == 1{
                if !self.characters.contains(character.lowercased()){
                    self.characters.append(character.lowercased())
                }
            }
        }
        return self
    }
    
    public func getCharacters() -> Array<String>{
        return self.characters
    }
    
    public func getDefaultSymbols() -> Array<String>{
        return self.symbols
    }
    
    public func getDefaultLetters() -> Array<String>{
        return self.letters
    }
    
    public func getDefaultNumbers() -> Array<String>{
        return self.numbers
    }
    
    public func reset() -> PwGen{
        self.useUppercase = self.defaultUppercase
        self.size = self.defaultSize
        self.characters = self.symbols + self.letters + self.numbers
        return self
    }
}
