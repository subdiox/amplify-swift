//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSClientRuntime

public protocol IAMCredentialsProvider {
    func getAWSCredentialIdentityResolver() -> any AWSCredentialIdentityResolver
}

public struct BasicIAMCredentialsProvider: IAMCredentialsProvider {
    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    public func getAWSCredentialIdentityResolver() -> any AWSCredentialIdentityResolver {
        return authService.getAWSCredentialIdentityResolver()
    }
}
