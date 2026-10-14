//
//  CacheModule.swift
//  LxMusicMobile
//
//  Created by Doubao.
//

import Foundation
import React

@objc(CacheModule)
class CacheModule: NSObject, RCTBridgeModule {
    static func moduleName() -> String! {
        return "CacheModule"
    }

    static func requiresMainQueueSetup() -> Bool {
        return false
    }

    @objc func getAppCacheSize(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let size = directorySize(path: cacheDir.path)
        resolve(size)
    }

    @objc func clearAppCache(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: cacheDir.path)
            for item in contents {
                try FileManager.default.removeItem(atPath: "\(cacheDir.path)/\(item)")
            }
            resolve(nil)
        } catch {
            reject("CACHE_ERROR", "Failed to clear cache", error)
        }
    }

    func directorySize(path: String) -> UInt64 {
        var size: UInt64 = 0
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            for item in contents {
                let fullPath = "\(path)/\(item)"
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDir) {
                    if isDir.boolValue {
                        size += directorySize(path: fullPath)
                    } else {
                        let attrs = try fileManager.attributesOfItem(atPath: fullPath)
                        size += attrs[.size] as? UInt64 ?? 0
                    }
                }
            }
        } catch {}
        return size
    }
}
