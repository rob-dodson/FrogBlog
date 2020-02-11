# PwGen

[![Version](https://img.shields.io/cocoapods/v/PwGen.svg?style=flat)](http://cocoapods.org/pods/PwGen)
[![License](https://img.shields.io/cocoapods/l/PwGen.svg?style=flat)](http://cocoapods.org/pods/PwGen)
[![Platform](https://img.shields.io/cocoapods/p/PwGen.svg?style=flat)](http://cocoapods.org/pods/PwGen)

Simple yet cryptographically secure password generator library in Swift.

## Usage

### Import library

```swift
import PwGen
```

### Generate password

Default password (12 characters) made of symbols, letters and/or numbers:

```swift
let password: String = try! PwGen().generate()
```
Password of size 20 that will use only letters and/or numbers:

```swift
let password: String = try! PwGen().ofSize(20).withoutSymbols().generate()
```

Symbols, letters, numbers with added characters:

```swift
let password = try! PwGen().addCharacters(["€","£"]).generate()
```
Lowercase letters, numbers + symbols without some characters:

```swift
let password = try! PwGen().withoutCharacters(["!","L"," "]).withoutUppercase().generate()
```

10 random passwords using the same pattern:

```swift
let generator = PwGen().withoutCharacter("a").withoutSymbols()
for _ in 0..<10 {
	let password = try! generator.generate()
	print(password)
}
```

### Check characters that will be used

```swift
let generator = PwGen().withoutSymbols()
print(generator.getCharacters())
```

## Installation

PwGen is available through [CocoaPods](http://cocoapods.org). 

To install it, simply add the following line to your Podfile:

```ruby
pod 'PwGen'
```

Then run:

```shell
pod install
```

## License

PwGen is available under the MIT license. See the LICENSE file for more info.
