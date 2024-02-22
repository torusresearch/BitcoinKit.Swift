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

class UserStorage : ILocalStorage {
    var memory : [String: Data] = [:]
    
    func get(key: String) async throws -> Data {
        
        guard let data = UserDefaults().value(forKey: key) as? Data else  {
            return Data()
        }
        return data
    }
    
    func set(key: String, payload: Data) async throws {
        UserDefaults().setValue(payload, forKey: key)
    }
}

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
    @IBOutlet weak var copyButton: UIButton?
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var recoveryFactorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "MPC Demo"
        
        recoveryFactorLabel?.layer.cornerRadius = 8
        Task {
            try await refreshFactorPubs()
        }
        recoveryFactorLabel.isHidden = true;
        loadingIndicator.isHidden = true;
        copyButton?.isHidden = true;
        createFactorButton.menu = UIMenu(children: [
            UIAction(title: "Device Type", handler: handleCreateFactor),
            UIAction(title: "Recovery Type", handler: handleCreateFactor)
        ])
        loadingIndicator.stopAnimating()
    }
    
    @IBAction func getkeydetails() {
        Task { @MainActor in
            let keyDetails = try mpcCoreKitInstance.tkey?.get_key_details();
        }
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

        let factorDescription = FactorDescriptionTypeModule.DeviceShare;
        let tssShareIndex = TssShareType.DEVICE;
        if action.title == "Recovery Type" {
            let factorDescription = FactorDescriptionTypeModule.SeedPhrase;
            let tssShareIndex = TssShareType.RECOVERY;
        }
        loadingIndicator.isHidden = false;
        loadingIndicator.startAnimating()
        Task { @MainActor in
            let factorKey = try await mpcCoreKitInstance.createFactor(tssShareIndex: tssShareIndex,factorKey: nil, factorDescription: factorDescription, additionalMetadata: [:])
            
            try await refreshFactorPubs()
            let factorPub = try curveSecp256k1.SecretKey(hex: factorKey).toPublic().serialize(compressed: true)
            if action.title == "Recovery Type" {
                let mnemonic = mpcCoreKitInstance.keyToMnemonic(factorKey: factorKey, format: "mnemonic");
                recoveryFactorLabel.text = mnemonic!;
                let factor = mpcCoreKitInstance.mnemonicToKey(shareMnemonic: mnemonic!, format: "mnemonic");
                recoveryFactorLabel.isHidden = false;
                copyButton?.isHidden = false;
                cleanupFactor.updateValue(factorKey, forKey: factorPub)
                loadingIndicator.stopAnimating();
                loadingIndicator.isHidden = true;
            }
            // popup factorkey
        }
    }
    
    func handleDeleteFactor (action: UIAction) {
        Task { @MainActor in
            loadingIndicator.isHidden = false;
            loadingIndicator.startAnimating();
            let factorkey = cleanupFactor[action.title]
            try await mpcCoreKitInstance.deleteFactor(deleteFactorPub: action.title, deleteFactorKey: factorkey)
            
            try await refreshFactorPubs()
            loadingIndicator.stopAnimating();
            loadingIndicator.isHidden = true;
        }
        
//        var currentChildren = deleteFactorButton.menu!.children
//        currentChildren.removeAll(where: { element in
//            return element.title == action.title
//        })
//        deleteFactorButton.menu = UIMenu( children: currentChildren )
    }
    
    @IBAction func handleEnableMFA(_ sender: Any) {
        Task {
            // loading ui
            try await mpcCoreKitInstance.enableMFA()
            // stop loading ui
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }
    
    @IBAction func onCopyFactor(_ sender: Any) {
    }
    

}
