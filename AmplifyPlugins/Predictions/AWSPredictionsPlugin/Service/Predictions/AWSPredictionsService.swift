//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
import AWSTranslate
import AWSTextract
import AWSComprehend
import AWSPolly
import AWSPluginsCore
@_spi(PluginHTTPClientEngine) import AWSPluginsCore
import Foundation
import ClientRuntime
import AWSClientRuntime
import AWSTranscribeStreaming

class AWSPredictionsService {
    var identifier: String!
    var awsTranslate: TranslateClientProtocol!
    var awsRekognition: RekognitionClientProtocol!
    var awsPolly: PollyClientProtocol!
    var awsComprehend: ComprehendClientProtocol!
    var awsTextract: TextractClientProtocol!
    var awsTranscribeStreaming: AWSTranscribeStreamingBehavior!
    var predictionsConfig: PredictionsPluginConfiguration!
    let rekognitionWordLimit = 50

    convenience init(
        configuration: PredictionsPluginConfiguration,
        awsCredentialIdentityResolver: some AWSCredentialIdentityResolver,
        identifier: String
    ) throws {
        let translateClientConfiguration = try TranslateClient.TranslateClientConfiguration(
            awsCredentialIdentityResolver: awsCredentialIdentityResolver,
            region: configuration.convert.region
        )
        translateClientConfiguration.httpClientEngine = .userAgentEngine

        let awsTranslateClient = TranslateClient(config: translateClientConfiguration)

        let pollyClientConfiguration = try PollyClient.PollyClientConfiguration(
            awsCredentialIdentityResolver: awsCredentialIdentityResolver,
            region: configuration.convert.region
        )
        pollyClientConfiguration.httpClientEngine = .userAgentEngine
        let awsPollyClient = PollyClient(config: pollyClientConfiguration)

        let comprehendClientConfiguration = try ComprehendClient.ComprehendClientConfiguration(
            awsCredentialIdentityResolver: awsCredentialIdentityResolver,
            region: configuration.convert.region
        )
        comprehendClientConfiguration.httpClientEngine = .userAgentEngine

        let awsComprehendClient = ComprehendClient(config: comprehendClientConfiguration)

        let rekognitionClientConfiguration = try RekognitionClient.RekognitionClientConfiguration(
            awsCredentialIdentityResolver: awsCredentialIdentityResolver,
            region: configuration.identify.region
        )
        rekognitionClientConfiguration.httpClientEngine = .userAgentEngine
        let awsRekognitionClient = RekognitionClient(config: rekognitionClientConfiguration)

        let textractClientConfiguration = try TextractClient.TextractClientConfiguration(
            awsCredentialIdentityResolver: awsCredentialIdentityResolver,
            region: configuration.identify.region
        )
        textractClientConfiguration.httpClientEngine = .userAgentEngine
        let awsTextractClient = TextractClient(config: textractClientConfiguration)

        let awsTranscribeStreamingAdapter = AWSTranscribeStreamingAdapter(
            awsCredentialIdentityResolver: awsCredentialIdentityResolver,
            region: configuration.convert.region
        )

        self.init(
            identifier: identifier,
            awsTranslate: awsTranslateClient,
            awsRekognition: awsRekognitionClient,
            awsTextract: awsTextractClient,
            awsComprehend: awsComprehendClient,
            awsPolly: awsPollyClient,
            awsTranscribeStreaming: awsTranscribeStreamingAdapter,
            configuration: configuration
        )
    }

    init(
        identifier: String,
        awsTranslate: TranslateClientProtocol,
        awsRekognition: RekognitionClientProtocol,
        awsTextract: TextractClientProtocol,
        awsComprehend: ComprehendClientProtocol,
        awsPolly: PollyClientProtocol,
        awsTranscribeStreaming: AWSTranscribeStreamingBehavior,
        configuration: PredictionsPluginConfiguration
    ) {

        self.identifier = identifier
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsTextract = awsTextract
        self.awsComprehend = awsComprehend
        self.awsPolly = awsPolly
        self.awsTranscribeStreaming = awsTranscribeStreaming
        self.predictionsConfig = configuration
    }

    func getEscapeHatch<T>(client: PredictionsAWSService<T>) -> T {
        client.fetch(self)
    }
}

extension AWSPredictionsService: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.predictions.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
