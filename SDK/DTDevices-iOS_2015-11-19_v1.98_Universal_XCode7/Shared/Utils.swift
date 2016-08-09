import Foundation
import UIKit

extension String {
    
    // MARK: - sub String
    func substringToIndex(index:Int) -> String {
        return self.substringToIndex(self.startIndex.advancedBy(index))
    }
    func substringFromIndex(index:Int) -> String {
        return self.substringFromIndex(self.startIndex.advancedBy(index))
    }
    func substringWithRange(range:Range<Int>) -> String {
        let start = self.startIndex.advancedBy(range.startIndex)
        let end = self.startIndex.advancedBy(range.endIndex)
        return self.substringWithRange(start..<end)
    }
    
    subscript(index:Int) -> Character{
        return self[self.startIndex.advancedBy(index)]
    }
    subscript(range:Range<Int>) -> String {
        let start = self.startIndex.advancedBy(range.startIndex)
        let end = self.startIndex.advancedBy(range.endIndex)
        return self[start..<end]
    }
    
    
    // MARK: - replace
    func replaceCharactersInRange(range:Range<Int>, withString: String!) -> String {
        let result:NSMutableString = NSMutableString(string: self)
        result.replaceCharactersInRange(NSRange(range), withString: withString)
        return result as String
    }
    
    func masked (start: Int, end: Int) -> String {
        
        let len = self.lengthOfBytesUsingEncoding(NSASCIIStringEncoding)
        var s = self.substringToIndex(start)
        for _ in 1...(len-(start+end)) {
            s += "*"
        }
        s += self.substringFromIndex(len-end)
        
        return "s"
    }
    
    /// Create NSData from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a NSData object. Note, if the string has any spaces, those are removed. Also if the string started with a '<' or ended with a '>', those are removed, too. This does no validation of the string to ensure it's a valid hexadecimal string
    ///
    /// The use of `strtoul` inspired by Martin R at http://stackoverflow.com/a/26284562/1271826
    ///
    /// :returns: NSData represented by this hexadecimal string. Returns nil if string contains characters outside the 0-9 and a-f range.
    
    func dataFromHexadecimalString() -> NSData? {
        let trimmedString = self.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<> ")).stringByReplacingOccurrencesOfString(" ", withString: "")
        
        // make sure the cleaned up string consists solely of hex digits, and that we have even number of them
        
        do {
            let regex = try NSRegularExpression(pattern: "^[0-9a-f]*$", options:NSRegularExpressionOptions.CaseInsensitive)
            let found = regex.firstMatchInString(trimmedString, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, trimmedString.characters.count))
            if found == nil || found?.range.location == NSNotFound || trimmedString.characters.count % 2 != 0 {
                return nil
            }
        }catch {
            return nil
        }
        
        // everything ok, so now let's build NSData
        
        let data = NSMutableData(capacity: trimmedString.characters.count / 2)
        
        for var index = trimmedString.startIndex; index < trimmedString.endIndex; index = index.successor().successor() {
            let byteString = trimmedString.substringWithRange(Range<String.Index>(start: index, end: index.successor().successor()))
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.appendBytes([num] as [UInt8], length: 1)
        }
        
        return data
    }
}

extension NSData {
    func toHexString() -> String {
        
        let string = NSMutableString(capacity: length * 2)
        var byte: UInt8 = 0
        
        for i in 0 ..< length {
            getBytes(&byte, range: NSMakeRange(i, 1))
            string.appendFormat("%02x", byte)
        }
        
        return string as String
    }
    
    func getBytes() -> [UInt8]! {
        // create array of appropriate length:
        var array = [UInt8](count: self.length, repeatedValue: 0)
        
        // copy bytes into array
        self.getBytes(&array, length:self.length)
        
        return array
    }
}

extension SequenceType where Generator.Element == UInt8 {
    func someMessage(){
        print("UInt8 Array")
    }
}


extension Array {
    func subArray(start: Int, end: Int) -> [Element] {
        var r = [Element]()
        for i in 0..<end {
            r.append(self[start+i])
        }
        return r
    }
    
    func toHexString() -> String {
        
        let string = NSMutableString(capacity: count * 2)
        
        if self.first is UInt8 {
            var byteArray = self.map { $0 as! UInt8 }
            for i in 0 ..< count {
                string.appendFormat("%02x", byteArray[i])
            }
        }
        return string as String
    }
    
    func getNSData() -> NSData {
        return NSData(bytes: self, length: self.count)
    }
    
}

extension Float {
    func format(f: String) -> String {
        return NSString(format: "%\(f)f", self) as String
    }
}

extension Int {
    func format(f: String) -> String {
        return NSString(format: "%\(f)d", self) as String
    }
}

class Utils: NSObject {
    
    class func showMessage(title: String, message: String)
    {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertView()
            alert.title = title
            alert.message = message
            alert.addButtonWithTitle("Ok")
            alert.show()
        }
    }
    
    class func showError(operation: String, error: NSError?)
    {
        if (error != nil)
        {
            showMessage("Error", message: "\(operation) failed with error: \(error!.localizedDescription)!")
        }else
        {
            showMessage("Error", message: "\(operation) failed!")
        }
    }
    
}