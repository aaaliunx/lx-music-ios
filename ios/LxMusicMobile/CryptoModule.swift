//
//  CryptoModule.swift
//  LxMusicMobile
//
//  Created by Doubao.
//

import Foundation
import React
import CommonCrypto

@objc(CryptoModule)
class CryptoModule: NSObject, RCTBridgeModule {
    override static func moduleName() -> String! {
        return "CryptoModule"
    }

    override static func requiresMainQueueSetup() -> Bool {
        return false
    }

    // MARK: - RSA

    @objc func generateRsaKey(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            reject("RSA_ERROR", "Failed to generate key pair", error?.takeRetainedValue())
            return
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            reject("RSA_ERROR", "Failed to get public key", nil)
            return
        }

        // Export keys as base64
        var error2: Unmanaged<CFError>?
        guard let privateData = SecKeyCopyExternalRepresentation(privateKey, &error2) as Data?,
              let publicData = SecKeyCopyExternalRepresentation(publicKey, &error2) as Data? else {
            reject("RSA_ERROR", "Failed to export keys", nil)
            return
        }

        resolve([
            "publicKey": publicData.base64EncodedString(),
            "privateKey": privateData.base64EncodedString()
        ])
    }

    @objc func rsaEncrypt(_ text: String, key: String, padding: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        // Base64 decode the key
        guard let keyData = Data(base64Encoded: key) else {
            reject("RSA_ERROR", "Invalid key", nil)
            return
        }

        // Create public key from data
        guard let publicKey = SecKeyCreateWithData(keyData as CFData, [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ] as CFDictionary, nil) else {
            reject("RSA_ERROR", "Failed to create key", nil)
            return
        }

        let data = Data(text.utf8)
        var error: Unmanaged<CFError>?
        let secPadding: SecKeyAlgorithm = (padding.contains("OAEP")) ? .rsaEncryptionOAEPSHA1 : .rsaEncryptionRaw

        guard let encrypted = SecKeyCreateEncryptedData(publicKey, secPadding, data as CFData, &error) as Data? else {
            reject("RSA_ERROR", "Encryption failed", error?.takeRetainedValue())
            return
        }

        resolve(encrypted.base64EncodedString())
    }

    @objc func rsaDecrypt(_ text: String, key: String, padding: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let keyData = Data(base64Encoded: key),
              let encryptedData = Data(base64Encoded: text) else {
            reject("RSA_ERROR", "Invalid input", nil)
            return
        }

        guard let privateKey = SecKeyCreateWithData(keyData as CFData, [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ] as CFDictionary, nil) else {
            reject("RSA_ERROR", "Failed to create key", nil)
            return
        }

        var error: Unmanaged<CFError>?
        let secPadding: SecKeyAlgorithm = (padding.contains("OAEP")) ? .rsaEncryptionOAEPSHA1 : .rsaEncryptionRaw

        guard let decrypted = SecKeyCreateDecryptedData(privateKey, secPadding, encryptedData as CFData, &error) as Data? else {
            reject("RSA_ERROR", "Decryption failed", error?.takeRetainedValue())
            return
        }

        resolve(String(data: decrypted, encoding: .utf8))
    }

    // MARK: - AES

    @objc func aesEncrypt(_ text: String, key: String, iv: String, mode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let result = aesOperation(text: text, key: key, iv: iv, mode: mode, encrypt: true)
        if result == nil {
            reject("AES_ERROR", "Encryption failed", nil)
        } else {
            resolve(result)
        }
    }

    @objc func aesDecrypt(_ text: String, key: String, iv: String, mode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let result = aesOperation(text: text, key: key, iv: iv, mode: mode, encrypt: false)
        if result == nil {
            reject("AES_ERROR", "Decryption failed", nil)
        } else {
            resolve(result)
        }
    }

    func aesOperation(text: String, key: String, iv: String, mode: String, encrypt: Bool) -> String? {
        let keyData = Data(key.utf8)
        let ivData = Data(iv.utf8)
        let data: Data

        if encrypt {
            data = Data(text.utf8)
        } else {
            guard let decoded = Data(base64Encoded: text) else { return nil }
            data = decoded
        }

        let keyLength = keyData.count
        guard keyLength == 16 || keyLength == 24 || keyLength == 32 else { return nil }

        var buffer = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        var numBytesEncrypted = 0

        let options: CCOptions = (mode.contains("ECB")) ? CCOptions(kCCOptionECBMode) : CCOptions(kCCOptionPKCS7Padding)
        let operation: CCOperation = encrypt ? CCOperation(kCCEncrypt) : CCOperation(kCCDecrypt)

        let ivPtr: UnsafePointer<UInt8>? = ivData.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: UInt8.self) }

        let status = data.withUnsafeBytes { dataBuffer in
            keyData.withUnsafeBytes { keyBuffer in
                CCCrypt(
                    operation,
                    CCAlgorithm(kCCAlgorithmAES128),
                    options,
                    keyBuffer.baseAddress,
                    keyLength,
                    ivPtr,
                    dataBuffer.baseAddress,
                    data.count,
                    &buffer,
                    buffer.count,
                    &numBytesEncrypted
                )
            }
        }

        guard status == kCCSuccess else { return nil }

        let resultData = Data(bytes: buffer, count: numBytesEncrypted)
        return encrypt ? resultData.base64EncodedString() : String(data: resultData, encoding: .utf8)
    }

    // MARK: - SHA1

    @objc func sha1(_ input: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let data = Data(input.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA1(buffer.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexString = digest.map { String(format: "%02x", $0) }.joined()
        resolve(hexString)
    }
}
