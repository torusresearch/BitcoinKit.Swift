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
    
    @IBOutlet weak var factorView: UIView!
    @IBOutlet weak var factorlabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "MPC Demo"
        
        factorView.isHidden = true
        
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
        factorView.isHidden = true
        
        let factorPubs = try await mpcCoreKitInstance.getAllFactorPubs()
        print(factorPubs)
        var childs : [UIAction] = []
        factorPubs.forEach({
            factorPub in
            childs.append(UIAction(title: factorPub, handler: handleDeleteFactor))
            print(factorPub)
        })
        deleteFactorButton.menu = UIMenu(children: childs )
    }
    
    func handleCreateFactor (action: UIAction) {
        Task { @MainActor in
            showLoader()
            let factorKey = try await mpcCoreKitInstance.createFactor(tssShareIndex: .DEVICE,factorKey: nil, factorDescription: .DeviceShare, additionalMetadata: [:])
            
            try await refreshFactorPubs()
            
            let factorPub = try curveSecp256k1.SecretKey(hex: factorKey).toPublic().serialize(compressed: true)
            cleanupFactor.updateValue(factorKey, forKey: factorPub)
            
            factorlabel.text = factorKey
            factorView.isHidden = false
            
            print(factorKey)
            // popup factorkey
            dismissLoader()
        }
    }
    
    func handleDeleteFactor (action: UIAction) {
        Task { @MainActor in
            showLoader()
            let factorkey = cleanupFactor[action.title]
            try await mpcCoreKitInstance.deleteFactor(deleteFactorPub: action.title, deleteFactorKey: factorkey)
            try await refreshFactorPubs()
            dismissLoader()
        }
        
//        var currentChildren = deleteFactorButton.menu!.children
//        currentChildren.removeAll(where: { element in
//            return element.title == action.title
//        })
//        deleteFactorButton.menu = UIMenu( children: currentChildren )
    }
    
    @IBAction func handleEnableMFA(_ sender: Any) {
        Task {
            do {
                // loading ui
                showLoader()
                try await mpcCoreKitInstance.enableMFA()
                // stop loading ui
                dismissLoader()
            } catch let error {
                dismissLoader()
                let alert = UIAlertController(
                    title: "Error", message: error.localizedDescription, preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                present(alert, animated: true)
                
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }
    
    private func dismissLoader() {
        if let loadingViewController = self.presentedViewController, loadingViewController is UIAlertController {
            dismiss(animated: false, completion: nil)
        }
    }
    
    private func showLoader() {
        let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(style: .large)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.isUserInteractionEnabled = false
        loadingIndicator.startAnimating();

        alert.view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            alert.view.heightAnchor.constraint(equalToConstant: 95),
            alert.view.widthAnchor.constraint(equalToConstant: 95),
            loadingIndicator.centerXAnchor.constraint(
                equalTo: alert.view.centerXAnchor
            ),
            loadingIndicator.centerYAnchor.constraint(equalTo: alert.view.centerYAnchor)
        ])
        
        present(alert, animated: true, completion: nil)
    }

    @IBAction func handleCopy(_ sender: Any) {
        if let factor = factorlabel?.text?.trimmingCharacters(in: .whitespaces) {
            UIPasteboard.general.setValue(factor, forPasteboardType: "public.plain-text")

            let alert = UIAlertController(title: "Success", message: "Factor copied", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
    }
}
