//
//  HdApiSigner.swift
//  iOS Example
//
//  Created by CW Lee on 19/01/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import BitcoinCore
import curvelib_swift
import HdWalletKit

public class HDApiSigner : ISigner {
    
    public var publicKey: Data
    
    var sckey: curvelib_swift.SecretKey
    init(privateKey: Data) throws {
        self.sckey = try SecretKey(hex: privateKey.hexString)
        self.publicKey = Data(hex: try self.sckey.to_public().serialize(compressed: false))
    }
    
    init() throws {
        self.sckey = SecretKey()
        self.publicKey = Data(hex: try self.sckey.to_public().serialize(compressed: false))
    }
    
    convenience init (text: String ) throws {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let extendedKey = try! HDExtendedKey(extendedKey: text )
        let key = extendedKey.serialized
        try self.init(privateKey: key)
    }
    
    public func sign(message: Data) -> Data {
        return try! Data(hex: curvelib_swift.ECDSA.sign_recoverable(key: self.sckey, hash: message.hexString).serialize())
    }
    
    public func schnorrSign(message: Data, publicKey: Data) -> Data {
        print (message)
        print (publicKey)
        return message
    }
    
}
