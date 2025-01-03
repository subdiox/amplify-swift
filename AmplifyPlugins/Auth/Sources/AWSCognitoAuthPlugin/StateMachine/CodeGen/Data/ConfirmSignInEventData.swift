//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import typealias Amplify.AuthUIPresentationAnchor
#endif
import Foundation

struct ConfirmSignInEventData {

    let answer: String
    let attributes: [String: String]
    let metadata: [String: String]?
    let friendlyDeviceName: String?
    let presentationAnchor: AuthUIPresentationAnchor?

}

extension ConfirmSignInEventData: Equatable { }

extension ConfirmSignInEventData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "answer": answer.masked(),
            "attributes": attributes,
            "metadata": metadata ?? [:]
        ]
    }
}
extension ConfirmSignInEventData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
