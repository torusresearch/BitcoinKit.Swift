//
//  MPCSigner.swift
//  iOS Example
//
//  Created by CW Lee on 18/01/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import BitcoinCore
import mpc_kit_swift

public class MPCSigner : ISigner {
    
    public var publicKey: Data
    
    
    init(publicKey: Data) {
        self.publicKey = publicKey
    }
    
    public func sign(message: Data) -> Data {
        return message
    }
    
    public func schnorrSign(message: Data, publicKey: Data) -> Data {
        print (message)
        print (publicKey)
        return message
    }
    
}
