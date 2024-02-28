import HdWalletKit
import UIKit
import CryptoSwift
import mpc_core_kit_swift

let memory = UserStorage()
//let memory = MemoryStorage()

var web3AuthClientId = "519228911939-cri01h55lsjbsia1k7ll6qpalrus75ps.apps.googleusercontent.com"
var globalVerifier = "w3a-google-demo"
//var web3AuthClientId = "221898609709-obfn3p63741l5333093430j3qeiinaa8.apps.googleusercontent.com"
//var globalVerifier = "google-lrc"

var mpcCoreKitInstance = MpcCoreKit(web3AuthClientId: web3AuthClientId, web3AuthNetwork: .sapphire(.SAPPHIRE_DEVNET) , localStorage: memory )

class MPCLoginController: UIViewController {

    @IBOutlet weak var RecoveryView: UIView!
    @IBOutlet weak var RecoveryText: UITextField!
    
    @IBOutlet weak var LoginOauthButton: UIButton!
    @IBOutlet weak var textConsole: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        RecoveryView.isHidden = true

        title = "BitcoinKit Demo"
        textConsole.text = ""
    }
    
    @IBAction func recovery(_ sender: Any) {
        guard let text = RecoveryText.text else {
            return
        }
        print(text)
        Task {
            // loading
            do {
                try await mpcCoreKitInstance.inputFactor(factorKey: text)
            } catch {
                let errorBlock: (Error) -> Void = { [weak self] error in
                    let alert = UIAlertController(title: "Validation Error", message: "\(error)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self?.present(alert, animated: true)
                }
                errorBlock(error)
            }
//             done loading
        }
    }
    
    @IBAction func loginOauth(_ sender: Any) {

        Task { @MainActor in
            let errorBlock: (Error) -> Void = { [weak self] error in
                let alert = UIAlertController(title: "Validation Error", message: "\(error)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self?.present(alert, animated: true)
            }
            
            let successBlock = { [weak self] in

                Manager.shared.login(apiSigner: mpcCoreKitInstance , syncModeIndex: 1 )
                if let window = UIApplication.shared.windows.filter(\.isKeyWindow).first {
                    let mainController = MainController()
                    UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                        window.rootViewController = mainController
                    })
                }
            }
            
            let result = try? await mpcCoreKitInstance.login(loginProvider: .google, clientId: "519228911939-cri01h55lsjbsia1k7ll6qpalrus75ps.apps.googleusercontent.com", verifier: globalVerifier)
            
            
            guard let result = result else {
                errorBlock("login failed")
                return
            }
            
            if result.requiredFactors > 0 {
                // request recover factor key
                RecoveryView.isHidden = false
                textConsole.text = try String(data : JSONSerialization.data(withJSONObject: result), encoding: .utf8 )
                
            } else {
                successBlock()
            }
            
            LoginOauthButton.isOpaque = true
        }
    }
}
