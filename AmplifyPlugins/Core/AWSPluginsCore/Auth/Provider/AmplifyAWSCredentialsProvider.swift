//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AwsCommonRuntimeKit
import ClientRuntime
import Foundation

public class AmplifyAWSCredentialsProvider: AWSCredentialIdentityResolver {
    public func getIdentity(identityProperties: Attributes?) async throws -> AWSCredentialIdentity {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        if let awsCredentialsProvider = authSession as? AuthAWSCredentialsProvider {
            let credentials = try awsCredentialsProvider.getAWSCredentials().get()
            return credentials.toAWSCredentialIdentity()
        } else {
            let error = AuthError.unknown("Auth session does not include AWS credentials information")
            throw error
        }
    }
}

extension AWSCredentials {
    func toAWSCredentialIdentity() -> AWSCredentialIdentity {
        if let tempCredentials = self as? AWSTemporaryCredentials {
            return AWSCredentialIdentity(
                accessKey: tempCredentials.accessKeyId,
                secret: tempCredentials.secretAccessKey,
                expiration: tempCredentials.expiration,
                sessionToken: tempCredentials.sessionToken
            )
        } else {
            return AWSCredentialIdentity(
                accessKey: accessKeyId,
                secret: secretAccessKey,
                expiration: Date()
            )
        }
    }
}
