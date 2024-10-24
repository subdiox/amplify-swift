//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum AuthFactorType: String {

    /// An auth factor that uses password
    case password

    /// An auth factor that uses SRP protocol
    case passwordSRP

    /// An auth factor that uses SMS OTP
    case smsOTP

    /// An auth factor that uses Email OTP
    case emailOTP

    /// An auth factor that uses WebAuthn
    case webAuthn
}
