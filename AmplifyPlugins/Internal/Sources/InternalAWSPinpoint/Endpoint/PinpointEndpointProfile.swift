//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

@_spi(InternalAWSPinpoint)
public struct PinpointEndpointProfile: Codable {
    typealias DeviceToken = String

    var applicationId: String
    var endpointId: String
    var deviceToken: DeviceToken?
    var effectiveDate: Date
    var isDebug: Bool
    var isOptOut: Bool
    var location: PinpointClientTypes.EndpointLocation
    var demographic: PinpointClientTypes.EndpointDemographic
    private(set) var user: PinpointClientTypes.EndpointUser
    private(set) var attributes: [String: [String]] = [:]
    private(set) var metrics: [String: Double] = [:]

    init(applicationId: String,
         endpointId: String,
         deviceToken: DeviceToken? = nil,
         effectiveDate: Date = Date(),
         isDebug: Bool = false,
         isOptOut: Bool = false,
         location: PinpointClientTypes.EndpointLocation = .init(),
         demographic: PinpointClientTypes.EndpointDemographic = .init(),
         user: PinpointClientTypes.EndpointUser = .init()) {
        self.applicationId = applicationId
        self.endpointId = endpointId
        self.deviceToken = deviceToken
        self.effectiveDate = effectiveDate
        self.isDebug = isDebug
        self.isOptOut = isOptOut
        self.location = location
        self.demographic = demographic
        self.user = user
    }

    public mutating func addUserId(_ userId: String) {
        user.userId = userId
    }

    public mutating func addUserProfile(_ userProfile: UserProfile) {
        if let email = userProfile.email {
            setCustomProperty(email, forKey: Constants.AttributeKeys.email)
        }

        if let name = userProfile.name {
            setCustomProperty(name, forKey: Constants.AttributeKeys.name)
        }

        if let plan = userProfile.plan {
            setCustomProperty(plan, forKey: Constants.AttributeKeys.plan)
        }

        addCustomProperties(userProfile.customProperties)
        if let pinpointUser = userProfile as? PinpointUserProfile {
            addUserAttributes(pinpointUser.userAttributes)
            if let optedOutOfMessages = pinpointUser.optedOutOfMessages {
                isOptOut = optedOutOfMessages
            }
        }

        if let userLocation = userProfile.location {
            location.update(with: userLocation)
        }
    }

    public mutating func setAPNsToken(_ apnsToken: Data) {
        deviceToken = apnsToken.asHexString()
    }

    private mutating func addCustomProperties(_ properties: [String: UserProfilePropertyValue]?) {
        guard let properties = properties else { return }
        for (key, value) in properties {
            setCustomProperty(value, forKey: key)
        }
    }

    private mutating func addUserAttributes(_ attributes: [String: [String]]?) {
        guard let attributes = attributes else { return }
        let userAttributes = user.userAttributes ?? [:]
        user.userAttributes = userAttributes.merging(
            attributes,
            uniquingKeysWith: { _, new in new }
        )
    }

    private mutating func setCustomProperty(_ value: UserProfilePropertyValue,
                                   forKey key: String) {
        if let value = value as? String {
            attributes[key] = [value]
        } else if let values = value as? [String] {
            attributes[key] = values
        } else if let value = value as? Bool {
            attributes[key] = [String(value)]
        } else if let value = value as? Int {
            metrics[key] = Double(value)
        } else if let value = value as? Double {
            metrics[key] = value
        }
    }
}

extension Optional where Wrapped == PinpointEndpointProfile.DeviceToken {
    var isNotEmpty: Bool {
        guard let self = self else { return false }
        return !self.isEmpty
    }
}

extension PinpointEndpointProfile {
    struct Constants {
        struct AttributeKeys {
            static let email = "email"
            static let name = "name"
            static let plan = "plan"
        }
    }
}

extension PinpointClientTypes.EndpointLocation: Codable {
    private enum CodingKeys: String, CodingKey {
        case city
        case country
        case latitude
        case longitude
        case postalCode
        case region

    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            city: try container.decode(String?.self, forKey: .city),
            country: try container.decode(String?.self, forKey: .country),
            latitude: try container.decode(Double.self, forKey: .latitude),
            longitude: try container.decode(Double.self, forKey: .longitude),
            postalCode: try container.decode(String.self, forKey: .postalCode),
            region: try container.decode(String.self, forKey: .region)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(postalCode, forKey: .postalCode)
        try container.encode(region, forKey: .region)
    }
}

extension PinpointClientTypes.EndpointDemographic: Codable {
    private enum CodingKeys: String, CodingKey {
        case appVersion
        case locale
        case make
        case model
        case modelVersion
        case platform
        case platformVersion
        case timezone
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            appVersion: try container.decode(String?.self, forKey: .appVersion),
            locale: try container.decode(String?.self, forKey: .locale),
            make: try container.decode(String?.self, forKey: .make),
            model: try container.decode(String?.self, forKey: .model),
            modelVersion: try container.decode(String?.self, forKey: .modelVersion),
            platform: try container.decode(String?.self, forKey: .platform),
            platformVersion: try container.decode(String?.self, forKey: .platformVersion),
            timezone: try container.decode(String?.self, forKey: .timezone)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(locale, forKey: .locale)
        try container.encode(make, forKey: .make)
        try container.encode(model, forKey: .model)
        try container.encode(modelVersion, forKey: .modelVersion)
        try container.encode(platform, forKey: .platform)
        try container.encode(platformVersion, forKey: .platformVersion)
        try container.encode(timezone, forKey: .timezone)
    }
}

extension PinpointClientTypes.EndpointUser: Codable {
    private enum CodingKeys: String, CodingKey {
        case userAttributes
        case userId
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            userAttributes: try container.decode([String: [String]]?.self, forKey: .userAttributes),
            userId: try container.decode(String?.self, forKey: .userId)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userAttributes, forKey: .userAttributes)
        try container.encode(userId, forKey: .userId)
    }
}
