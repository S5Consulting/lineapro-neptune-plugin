//
//  BerTlv.swift
//  BoricaSDKDemo
//
//  Created by Flex on 10/12/15.
//  Copyright © 2015 Datecs. All rights reserved.
//

import Foundation

class BerTlv : NSObject {
    
    var tag: UInt64 = 0
    var data = [UInt8]()
    
    override init() {
        super.init()
    }
    
    func intValue() -> UInt64 {
        var r: UInt64 = 0
        for b in data {
            r <<= 8
            r |= UInt64(b)
        }
        
        return r
    }
    
    func stringValue() -> String {
        return String(bytes: data, encoding: NSASCIIStringEncoding)!
    }
    
    class func encodeToBCD(var value: UInt64, nBytes: Int) -> NSData {
        var r = [UInt8]()
        for _ in 0..<nBytes {
            var b = UInt8(value % 10)
            value /= 10
            b |= UInt8((value % 10) << 4)
            value /= 10
            r.append(b)
        }
        return NSData(bytes: r, length: r.count)
    }
    
    class func tlvWithBytes(data: [UInt8], tag: UInt64) -> BerTlv {
        let tlv = BerTlv()
        tlv.tag = tag
        tlv.data = data;
        return tlv;
    }
    
    class func tlvWithInt(var data: UInt64, nBytes:Int, tag: UInt64) -> BerTlv {
        var r = [UInt8]()
        for _ in 0..<nBytes {
            r.append(UInt8(data))
            data >>= 8
        }
        return .tlvWithBytes(r, tag:tag)
    }
    
    class func tlvWithBCD(data: UInt64, nBytes:Int, tag: UInt64) -> BerTlv {
        let b = self.encodeToBCD(data, nBytes:nBytes)
        return self.tlvWithBytes(b.getBytes(), tag:tag)
    }
    
    class func tlvWithString(data: String, tag: UInt64) -> BerTlv {
        return self.tlvWithBytes(data.dataUsingEncoding(NSASCIIStringEncoding)!.getBytes(), tag:tag)
    }
    
    class func tlvWithHexString(data:String, tag:UInt64) -> BerTlv {
        return self.tlvWithBytes(data.dataFromHexadecimalString()!.getBytes(), tag:tag)
    }
    
    class func findTag(tag:UInt64, tags:[BerTlv]) -> [BerTlv] {
        var r = [BerTlv]()
        
        for t in tags {
            if (t.tag == tag) {
                r.append(t)
            }
        }
        return r
    }
    
    class func findLastTag(tag:UInt64, tags:[BerTlv]) -> BerTlv? {
        var r = self.findTag(tag, tags: tags)
        if r.count > 0 {
            return r[0]
        }
        return nil
    }
    
    class func decodeTags(data: [UInt8]) -> [BerTlv]? {
        
        if data.count == 0 {
            return nil
        }
        var r = [BerTlv]()
        
        var i = 0
        while i < data.count {
            let t = UInt64(data[i++])
            
            let tlv = BerTlv()
            
            tlv.tag = t
            
            while (tlv.tag & 0x1F) == 0x1F {
                tlv.tag <<= 8
                tlv.tag |= UInt64(data[i++])
            }
            
            var tagLen = 0
            
            if (data[i] & 0x80) != 0 {
                //long form
                let nBytes = data[i++] & 0x7f
                for _ in 0..<nBytes {
                    tagLen <<= 8
                    tagLen |= Int(data[i++])
                }
            }else {
                //short form
                tagLen = Int(data[i++]&0x7f)
            }
            if tagLen > 4096 {
                return nil
            }
            tlv.data=data.subArray(i, end: tagLen)
            
            r.append(tlv)
            
            i+=tagLen;
        }
        return r;
    }
    
    class func encodeTags(tags: [BerTlv]) -> [UInt8]? {
        
        var r = [UInt8]()
        for tag in tags {
            var tagLen = 0
            var t = tag.tag
            while (t & 0xff) != 0 {
                tagLen++
                t >>= 8
            }
            for i in 0..<tagLen {
                r.append(UInt8((tag.tag >> UInt64((tagLen-i-1) * 8)) & 0xff))
            }
            if tag.data.count > 127 {
                //long form
                r.append(UInt8(0x80 | (tag.data.count >> 8)))
            }
            r.append(UInt8(tag.data.count))
            r.appendContentsOf(tag.data)
        }
        
        return r;
    }
    
    override  var description: String {
        let str = self.data.toHexString()
        return "Tag: \(self.tag) (\(str))"
    }
    
}