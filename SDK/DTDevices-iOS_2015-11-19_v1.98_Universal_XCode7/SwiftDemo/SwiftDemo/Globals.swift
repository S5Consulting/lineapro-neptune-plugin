import Foundation

struct Constants {
    static let keyAES256KEK: [UInt8] = [0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30]
    static let keyAES256Data: [UInt8] = [0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31]
    static let keyAES128Data1: [UInt8] = [0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
    static let keyAES128Data2: [UInt8] = [0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x32,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
    static let keyAES128Data3: [UInt8] = [0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x33,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
    static let keyDUKPTANSI: [UInt8] = [0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10]
    static let keyDUKPTKSN: [UInt8] = [0xFF,0xFF,0x98,0x76,0x54,0x32,0x10,0x00,0x00,0x00]
}
