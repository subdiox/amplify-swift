//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSTranscribeStreaming
import AWSClientRuntime

class AWSTranscribeStreamingAdapter: AWSTranscribeStreamingBehavior {

    /// Placeholder input that mirrors a subset of the `StartStreamTranscriptionInput` properties.
    /// This should make it easier to pivot to the AWS SDK for Swift implementation once streaming is supported.
    struct StartStreamInput {
        let audioStream: Data
        let languageCode: TranscribeStreamingClientTypes.LanguageCode
        let mediaEncoding: TranscribeStreamingClientTypes.MediaEncoding
        let mediaSampleRateHertz: Int
    }

    let awsCredentialIdentityResolver: any AWSCredentialIdentityResolver
    let region: String

    init(awsCredentialIdentityResolver: some AWSCredentialIdentityResolver, region: String) {
        self.awsCredentialIdentityResolver = awsCredentialIdentityResolver
        self.region = region
    }

    func startStreamTranscription(
        input: StartStreamInput
    ) async throws -> AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error> {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        guard let awsCredentialsProvider = authSession as? AuthAWSCredentialsProvider
        else {
            throw PredictionsError.client(
                .init(
                    description: "Error retrieving credentials",
                    recoverySuggestion: "Ensure that the Auth plugin is properly configured",
                    underlyingError: nil
                )
            )
        }

        let awsCredentials = try awsCredentialsProvider.getAWSCredentials().get()
        let sessionToken = (awsCredentials as? AWSTemporaryCredentials)?.sessionToken
        let signerCredentials = SigV4Signer.Credential(
            accessKey: awsCredentials.accessKeyId,
            secretKey: awsCredentials.secretAccessKey,
            sessionToken: sessionToken
        )

        let signer = SigV4Signer(
            credential: signerCredentials,
            serviceName: "transcribe",
            region: region
        )

        var components = URLComponents()
        components.scheme = "wss"
        components.host = "transcribestreaming.\(region).amazonaws.com"
        components.port = 8443
        components.path = "/stream-transcription-websocket"

        components.queryItems = [
            .init(name: "media-encoding", value: input.mediaEncoding.rawValue),
            .init(name: "language-code", value: input.languageCode.rawValue),
            .init(name: "sample-rate", value: String(input.mediaSampleRateHertz))
        ]

        guard let url = components.url else {
            throw PredictionsError.client(.invalidRegion)
        }

        let signedURL = signer.sign(
            url: url,
            expires: 300
        )

        let webSocket = WebSocketSession()

        webSocket.onSocketOpened {
            let headers: [String: EventStream.HeaderValue] = [
                ":content-type": "audio/wav",
                ":message-type": "event",
                ":event-type": "AudioEvent"
            ]

            let chunkSize = 4_096
            let audioDataSize = input.audioStream.count
            var currentStart = 0
            var currentEnd = min(chunkSize, audioDataSize - currentStart)

            while currentStart < audioDataSize {
                let dataChunk = input.audioStream[currentStart..<currentEnd]
                let encodedChunk = EventStream.Encoder().encode(payload: dataChunk, headers: headers)

                webSocket.send(message: .data(encodedChunk), onError: { _ in })
                currentStart = currentEnd
                currentEnd = min(currentStart + chunkSize, audioDataSize)
            }

            let endFrame = EventStream.Encoder().encode(
                payload: Data("".utf8),
                headers: [
                    ":message-type": "event",
                    ":event-type": "AudioEvent"
                ]
            )
            webSocket.send(message: .data(endFrame), onError: { _ in })
        }

        let stream = AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error> { continuation in
            Task {
                webSocket.onMessageReceived { result in
                    switch result {
                    case .success(.data(let data)):
                        do {
                            let transcribeddMessage = try EventStream.Decoder().decode(
                                data: data
                            )

                            let transcribedPayload = try JSONDecoder().decode(
                                TranscribeStreamingClientTypes.TranscriptEvent.self,
                                from: transcribeddMessage.payload
                            )

                            continuation.yield(transcribedPayload)
                            let isPartial = transcribedPayload.transcript?.results?.map(\.isPartial) ?? []
                            let shouldContinue = isPartial.allSatisfy { $0 }
                            return shouldContinue
                        } catch {
                            return true
                        }
                    case .success(.string):
                        return true
                    case .failure(let error):
                        continuation.finish(throwing: error)
                        return false
                    @unknown default:
                        return true
                    }
                }
            }
        }

        webSocket.open(url: signedURL)

        return stream
    }
}

extension TranscribeStreamingClientTypes.TranscriptEvent: Codable {
    private enum CodingKeys: String, CodingKey {
        case transcript
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            transcript: try container.decode(TranscribeStreamingClientTypes.Transcript?.self, forKey: .transcript)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transcript, forKey: .transcript)
    }
}

extension TranscribeStreamingClientTypes.Transcript: Codable {
    private enum CodingKeys: String, CodingKey {
        case results
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            results: try container.decode([TranscribeStreamingClientTypes.Result]?.self, forKey: .results)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(results, forKey: .results)
    }
}

extension TranscribeStreamingClientTypes.Result: Codable {
    private enum CodingKeys: String, CodingKey {
        case alternatives
        case channelId
        case endTime
        case isPartial
        case languageCode
        case languageIdentification
        case resultId
        case startTime
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            alternatives: try container.decode([TranscribeStreamingClientTypes.Alternative]?.self, forKey: .alternatives),
            channelId: try container.decode(String?.self, forKey: .channelId),
            endTime: try container.decode(Double.self, forKey: .endTime),
            isPartial: try container.decode(Bool.self, forKey: .isPartial),
            languageCode: try container.decode(TranscribeStreamingClientTypes.LanguageCode?.self, forKey: .languageCode),
            languageIdentification: try container.decode([TranscribeStreamingClientTypes.LanguageWithScore]?.self, forKey: .languageIdentification),
            resultId: try container.decode(String?.self, forKey: .resultId),
            startTime: try container.decode(Double.self, forKey: .startTime)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(alternatives, forKey: .alternatives)
        try container.encode(channelId, forKey: .channelId)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(isPartial, forKey: .isPartial)
        try container.encode(languageCode, forKey: .languageCode)
        try container.encode(languageIdentification, forKey: .languageIdentification)
        try container.encode(resultId, forKey: .resultId)
        try container.encode(startTime, forKey: .startTime)
    }
}

extension TranscribeStreamingClientTypes.Alternative: Codable {
    private enum CodingKeys: String, CodingKey {
        case entities
        case items
        case transcript
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            entities: try container.decode([TranscribeStreamingClientTypes.Entity]?.self, forKey: .entities),
            items: try container.decode([TranscribeStreamingClientTypes.Item]?.self, forKey: .items),
            transcript: try container.decode(String?.self, forKey: .transcript)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entities, forKey: .entities)
        try container.encode(items, forKey: .items)
        try container.encode(transcript, forKey: .transcript)
    }
}

extension TranscribeStreamingClientTypes.Entity: Codable {
    private enum CodingKeys: String, CodingKey {
        case category
        case confidence
        case content
        case endTime
        case startTime
        case type
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            category: try container.decode(String?.self, forKey: .category),
            confidence: try container.decode(Double?.self, forKey: .confidence),
            content: try container.decode(String?.self, forKey: .content),
            endTime: try container.decode(Double.self, forKey: .endTime),
            startTime: try container.decode(Double.self, forKey: .startTime),
            type: try container.decode(String?.self, forKey: .type)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(content, forKey: .content)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(type, forKey: .type)
    }
}

extension TranscribeStreamingClientTypes.Item: Codable {
    private enum CodingKeys: String, CodingKey {
        case confidence
        case content
        case endTime
        case speaker
        case stable
        case startTime
        case type
        case vocabularyFilterMatch
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            confidence: try container.decode(Double?.self, forKey: .confidence),
            content: try container.decode(String?.self, forKey: .content),
            endTime: try container.decode(Double.self, forKey: .endTime),
            speaker: try container.decode(String?.self, forKey: .speaker),
            stable: try container.decode(Bool?.self, forKey: .stable),
            startTime: try container.decode(Double.self, forKey: .startTime),
            type: try container.decode(TranscribeStreamingClientTypes.ItemType?.self, forKey: .type),
            vocabularyFilterMatch: try container.decode(Bool.self, forKey: .vocabularyFilterMatch)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(content, forKey: .content)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(speaker, forKey: .speaker)
        try container.encode(stable, forKey: .stable)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(type, forKey: .type)
        try container.encode(vocabularyFilterMatch, forKey: .vocabularyFilterMatch)
    }
}

extension TranscribeStreamingClientTypes.ItemType: Codable {
    private enum CodingKeys: String, CodingKey {
        case rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .rawValue)
        self = TranscribeStreamingClientTypes.ItemType(rawValue: rawValue) ?? .sdkUnknown(rawValue)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.rawValue, forKey: .rawValue)
    }
}

extension TranscribeStreamingClientTypes.LanguageCode: Codable {
    private enum CodingKeys: String, CodingKey {
        case rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .rawValue)
        self = TranscribeStreamingClientTypes.LanguageCode(rawValue: rawValue) ?? .sdkUnknown(rawValue)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.rawValue, forKey: .rawValue)
    }
}

extension TranscribeStreamingClientTypes.LanguageWithScore: Codable {
    private enum CodingKeys: String, CodingKey {
        case languageCode
        case score
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            languageCode: try container.decode(TranscribeStreamingClientTypes.LanguageCode?.self, forKey: .languageCode),
            score: try container.decode(Double.self, forKey: .score)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(languageCode, forKey: .languageCode)
        try container.encode(score, forKey: .score)
    }
}
