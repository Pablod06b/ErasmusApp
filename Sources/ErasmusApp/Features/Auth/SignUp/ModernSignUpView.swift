import SwiftUI

struct ModernSignUpView: View {
    let onFinish: () -> Void
    
    var body: some View {
        ModernOnboardingFlow(onFinish: onFinish)
    }
}

struct ModernSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        ModernSignUpView(onFinish: {})
            .environmentObject(FirebaseAuthManager())
    }
}
