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
import tss_client_swift
import tkey_mpc_swift

extension MpcSigningKit : ISigner {
//public class MPCSigner : ISigner {
    
    public var publicKey : Data {
        let semaphore = DispatchSemaphore(value: 0)
        var result : Data?
        performAsyncOperation(completion: { myresult  in
            result = myresult
        })
        semaphore.wait()

        return result ?? Data([])
    }
    
    public func sign(message: Data) -> Data {
        return message
    }
    
    public func schnorrSign(message: Data, publicKey: Data) -> Data {
        print (message)
        print (publicKey)
        return message
    }
    
    func performAsyncOperation(completion: @escaping (Data) -> Void) {
        Task {
            // Simulate an asynchronous operation
            let tss_tag = try! TssModule.get_tss_tag(threshold_key: self.tkey! )
            
            let result = try! await Data(hex: TssModule.get_tss_pub_key(threshold_key: self.tkey!, tss_tag: tss_tag ) )
            completion(result)
        }
    }

}
