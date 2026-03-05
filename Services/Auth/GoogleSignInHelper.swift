import Foundation
import SwiftUI
import GoogleSignIn
import FirebaseCore

@MainActor
class GoogleSignInHelper: ObservableObject {
    var onLoginSuccess: ((String, String) -> Void)?
    var onError: ((Error) -> Void)?
    
    func signIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let error = NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ClientID found in Firebase configuration"])
            onError?(error)
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Find topmost ViewController to present Google Sign In
        guard let rootViewController = getRootViewController() else {
            let error = NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No RootViewController found"])
            onError?(error)
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
            if let error = error {
                self?.onError?(error)
                return
            }
            
            guard let signInResult = signInResult,
                  let idToken = signInResult.user.idToken?.tokenString else {
                let error = NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing ID Token from Google"])
                self?.onError?(error)
                return
            }
            
            let accessToken = signInResult.user.accessToken.tokenString
            self?.onLoginSuccess?(idToken, accessToken)
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return nil
        }
        
        guard let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}
