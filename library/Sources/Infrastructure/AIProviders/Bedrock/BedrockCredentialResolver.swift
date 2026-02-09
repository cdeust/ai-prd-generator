import Foundation
import AIPRDSharedUtilities
@preconcurrency import AWSBedrockRuntime
import AWSClientRuntime

/// AWS Credential Resolver adapter
/// Uses BedrockStaticCredential from SharedUtilities
@available(iOS 15.0, macOS 12.0, *)
struct BedrockCredentialResolver: AWSCredentialIdentityResolver {
    private let credential: BedrockStaticCredential

    init(credential: BedrockStaticCredential) {
        self.credential = credential
    }

    func getIdentity(identityProperties: Any?) async throws -> AWSCredentialIdentity {
        return AWSCredentialIdentity(
            accessKey: credential.accessKey,
            secret: credential.secret
        )
    }
}
