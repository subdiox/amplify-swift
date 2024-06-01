//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import AWSClientRuntime
import Amplify
import AWSPluginsCore

public class MockAWSAuthService: AWSAuthServiceBehavior {

    var interactions: [String] = []
    var getIdentityIdError: AuthError?
    var getTokenError: AuthError?
    var getTokenClaimsError: AuthError?
    var identityId: String?
    var token: String?
    var tokenClaims: [String: AnyObject]?

    public func configure() {
        interactions.append(#function)
    }

    public func reset() {
        interactions.append(#function)
    }

    public func getAWSCredentialIdentityResolver() -> any AWSCredentialIdentityResolver {
        interactions.append(#function)
        return MyCustomCredentialIdentityResolver()
    }

    public func getIdentityID() async throws -> String {
        interactions.append(#function)
        if let error = getIdentityIdError {
            throw error
        }

        return identityId ?? "IdentityId"
    }

    public func getUserPoolAccessToken() async throws -> String {
        interactions.append(#function)
        if let error = getTokenError {
            throw error
        } else {
            return token ?? "token"
        }
    }

    public func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError> {
        interactions.append(#function)
        if let error = getTokenClaimsError {
            return .failure(error)
        }
        return .success(tokenClaims ?? ["": "" as AnyObject])
    }
}

struct MyCustomCredentialIdentityResolver: AWSCredentialIdentityResolver {
    func getIdentity(identityProperties: Attributes? = nil) async throws -> AWSCredentialIdentity {
        AWSCredentialIdentity(
            accessKey: "AKIDEXAMPLE",
            secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
            expiration: Date().addingTimeInterval(30))
    }
}
