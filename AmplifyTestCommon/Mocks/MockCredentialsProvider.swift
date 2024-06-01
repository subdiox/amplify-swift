//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import ClientRuntime
import Foundation

class MockCredentialIdentityResolver: AWSCredentialIdentityResolver {
    func getIdentity(identityProperties: Attributes? = nil) async throws -> AWSCredentialIdentity {
        return AWSCredentialIdentity(
            accessKey: "accessKey",
            secret: "secret",
            expiration: Date().addingTimeInterval(1000)
        )
    }
}
