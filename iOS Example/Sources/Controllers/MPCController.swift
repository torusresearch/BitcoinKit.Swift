//
//  MPCController.swift
//  iOS Example
//
//  Created by CW Lee on 20/02/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import HdWalletKit
import UIKit
import CryptoSwift
import mpc_core_kit_swift
import curveSecp256k1

class MemoryStorage : ILocalStorage {
    var memory : [String: Data] = [:]
    
    func get(key: String) async throws -> Data {
        guard let data = memory[key] else  {
            return Data()
        }
        return data
    }
    
    func set(key: String, payload: Data) async throws {
        memory[key] = payload
    }
}

var cleanupFactor : [String: String] = [:]

class MPCController: UIViewController {
    @IBOutlet weak var textView: UILabel!
    @IBOutlet weak var createFactorButton: UIButton!
    @IBOutlet weak var deleteFactorButton: UIButton!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "MPC Demo"
        
        textView?.layer.cornerRadius = 8
        Task {
            try await refreshFactorPubs()
        }
        
        createFactorButton.menu = UIMenu(children: [
            UIAction(title: "Device Type", handler: handleCreateFactor),
            UIAction(title: "Recovery Type", handler: handleCreateFactor)
        ])
    }
    
    func refreshFactorPubs() async throws {
        loadingIndicator.startAnimating()
        let factorPubs = try await mpcCoreKitInstance.getAllFactorPubs()
        print(factorPubs)
        var childs : [UIAction] = []
        factorPubs.forEach({
            factorPub in
            childs.append(UIAction(title: factorPub, handler: handleDeleteFactor))
            print(factorPub)
        })
        deleteFactorButton.menu = UIMenu(children: childs )
        loadingIndicator.stopAnimating()
    }
    
    func handleCreateFactor (action: UIAction) {

        loadingIndicator.startAnimating()
        Task {
            let factorKey = try await mpcCoreKitInstance.createFactor(tssShareIndex: .DEVICE,factorKey: nil, factorDescription: .DeviceShare, additionalMetadata: [:])
            
            try await refreshFactorPubs()
            
            let factorPub = try curveSecp256k1.SecretKey(hex: factorKey).toPublic().serialize(compressed: true)
            cleanupFactor.updateValue(factorKey, forKey: factorPub)
            // popup factorkey
        }
    }
    
    func handleDeleteFactor (action: UIAction) {
        Task {
            let factorkey = cleanupFactor[action.title]
            try await mpcCoreKitInstance.deleteFactor(deleteFactorPub: action.title, deleteFactorKey: factorkey)
            
            try await refreshFactorPubs()
        }
        
//        var currentChildren = deleteFactorButton.menu!.children
//        currentChildren.removeAll(where: { element in
//            return element.title == action.title
//        })
//        deleteFactorButton.menu = UIMenu( children: currentChildren )
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

}
