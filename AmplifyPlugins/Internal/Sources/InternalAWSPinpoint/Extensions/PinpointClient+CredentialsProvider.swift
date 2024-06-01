//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSPluginsCore
import AWSPinpoint
@_spi(PluginHTTPClientEngine) import AWSPluginsCore

extension PinpointClient {
    convenience init(region: String, awsCredentialIdentityResolver: some AWSCredentialIdentityResolver) throws {
        // TODO: FrameworkMetadata Replacement
        let configuration = try PinpointClientConfiguration(
            awsCredentialIdentityResolver: awsCredentialIdentityResolver,
            region: region
        )

        configuration.httpClientEngine = .userAgentEngine
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: configuration)
        self.init(config: configuration)
    }
}
