//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation
import AWSCloudWatchEvents
import ClientRuntime

extension AWSCloudWatchEvents.PutEventsInput: AmplifyStringConvertible {
    private enum CodingKeys: String, CodingKey {
        case entries
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            entries: try container.decode([CloudWatchEventsClientTypes.PutEventsRequestEntry]?.self, forKey: .entries)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entries, forKey: .entries)
    }
}

extension CloudWatchEventsClientTypes.PutEventsResultEntry: Codable {
    private enum CodingKeys: String, CodingKey {
        case errorCode
        case errorMessage
        case eventId
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            errorCode: try container.decode(String?.self, forKey: .errorCode),
            errorMessage: try container.decode(String?.self, forKey: .errorMessage),
            eventId: try container.decode(String?.self, forKey: .eventId)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(errorCode, forKey: .errorCode)
        try container.encode(errorMessage, forKey: .errorMessage)
        try container.encode(eventId, forKey: .eventId)
    }
}

extension AWSCloudWatchEvents.PutEventsOutput: Codable {
    private enum CodingKeys: String, CodingKey {
        case entries
        case failedEntryCount
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            entries: try container.decode([CloudWatchEventsClientTypes.PutEventsResultEntry]?.self, forKey: .entries),
            failedEntryCount: try container.decode(Swift.Int.self, forKey: .failedEntryCount)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entries, forKey: .entries)
        try container.encode(failedEntryCount, forKey: .failedEntryCount)
    }
}

extension PinpointClientTypes.ChannelType: Codable {
    private enum CodingKeys: String, CodingKey {
        case rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .rawValue)
        if let value = PinpointClientTypes.ChannelType(rawValue: rawValue) {
            self = value
        } else {
            self = .sdkUnknown(rawValue)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.rawValue, forKey: .rawValue)
    }
}

extension PinpointClientTypes.EndpointRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case address
        case attributes
        case channelType
        case demographic
        case effectiveDate
        case endpointStatus
        case location
        case metrics
        case optOut
        case requestId
        case user
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            address: try container.decode(String?.self, forKey: .address),
            attributes: try container.decode([String: [String]]?.self, forKey: .attributes),
            channelType: try container.decode(PinpointClientTypes.ChannelType?.self, forKey: .channelType),
            demographic: try container.decode(PinpointClientTypes.EndpointDemographic?.self, forKey: .demographic),
            effectiveDate: try container.decode(String?.self, forKey: .effectiveDate),
            endpointStatus: try container.decode(String?.self, forKey: .endpointStatus),
            location: try container.decode(PinpointClientTypes.EndpointLocation?.self, forKey: .location),
            metrics: try container.decode([String: Double]?.self, forKey: .metrics),
            optOut: try container.decode(String?.self, forKey: .optOut),
            requestId: try container.decode(String?.self, forKey: .requestId),
            user: try container.decode(PinpointClientTypes.EndpointUser?.self, forKey: .user)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(channelType, forKey: .channelType)
        try container.encode(demographic, forKey: .demographic)
        try container.encode(effectiveDate, forKey: .effectiveDate)
        try container.encode(endpointStatus, forKey: .endpointStatus)
        try container.encode(location, forKey: .location)
        try container.encode(metrics, forKey: .metrics)
        try container.encode(optOut, forKey: .optOut)
        try container.encode(requestId, forKey: .requestId)
        try container.encode(user, forKey: .user)
    }
}

extension UpdateEndpointInput: AmplifyStringConvertible {
    private enum CodingKeys: String, CodingKey {
        case applicationId
        case endpointId
        case endpointRequest
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            applicationId: try container.decode(String?.self, forKey: .applicationId),
            endpointId: try container.decode(String?.self, forKey: .endpointId),
            endpointRequest: try container.decode(PinpointClientTypes.EndpointRequest?.self, forKey: .endpointRequest)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(applicationId, forKey: .applicationId)
        try container.encode(endpointId, forKey: .endpointId)
        try container.encode(endpointRequest, forKey: .endpointRequest)
    }
}

extension PinpointClientTypes.MessageBody: Codable {
    private enum CodingKeys: String, CodingKey {
        case message
        case requestID
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            message: try container.decode(String?.self, forKey: .message),
            requestID: try container.decode(String?.self, forKey: .requestID)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encode(requestID, forKey: .requestID)
    }
}

extension UpdateEndpointOutput: Codable {
    private enum CodingKeys: String, CodingKey {
        case messageBody
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            messageBody: try container.decode(PinpointClientTypes.MessageBody?.self, forKey: .messageBody)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageBody, forKey: .messageBody)
    }
}

extension CloudWatchEventsClientTypes.PutEventsRequestEntry: Codable {
    private enum CodingKeys: String, CodingKey {
        case detail
        case detailType
        case eventBusName
        case resources
        case source
        case time
        case traceHeader
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            detail: try container.decode(String?.self, forKey: .detail),
            detailType: try container.decode(String?.self, forKey: .detailType),
            eventBusName: try container.decode(String?.self, forKey: .eventBusName),
            resources: try container.decode([String]?.self, forKey: .resources),
            source: try container.decode(String?.self, forKey: .source),
            time: try container.decode(Date.self, forKey: .time),
            traceHeader: try container.decode(String?.self, forKey: .traceHeader)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(detail, forKey: .detail)
        try container.encode(detailType, forKey: .detailType)
        try container.encode(eventBusName, forKey: .eventBusName)
        try container.encode(resources, forKey: .resources)
        try container.encode(source, forKey: .source)
        try container.encode(time, forKey: .time)
        try container.encode(traceHeader, forKey: .traceHeader)
    }
}
