//
//  UtilsModule.swift
//  LxMusicMobile
//
//  Created by Doubao.
//

import Foundation
import UIKit
import Network
import CoreTelephony
import React

@objc(UtilsModule)
class UtilsModule: NSObject, RCTBridgeModule {
    static func moduleName() -> String! {
        return "UtilsModule"
    }

    @objc func exitApp() {
        // iOS 不允许主动退出 App，退到后台
        DispatchQueue.main.async {
            UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        }
    }

    @objc func getSupportedAbis(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(["arm64"])
    }

    @objc func installApk(_ filePath: String, fileProviderAuthority: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        reject("UNSUPPORTED", "iOS does not support APK installation", nil)
    }

    @objc func screenkeepAwake() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    @objc func screenUnkeepAwake() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    @objc func getWIFIIPV4Address(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        var address = ""
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr!.pointee.ifa_next }
                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, 0, NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        resolve(address)
    }

    @objc func getDeviceName(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let device = UIDevice.current
        resolve("\(device.systemName) \(device.model)")
    }

    @objc func isNotificationsEnabled(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            resolve(settings.authorizationStatus == .authorized)
        }
    }

    @objc func openNotificationPermissionActivity(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
                resolve(true)
            } else {
                resolve(false)
            }
        }
    }

    @objc func shareText(_ shareTitle: String, title: String, text: String) {
        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { return }
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            activityVC.title = title
            rootVC.present(activityVC, animated: true)
        }
    }

    @objc func getSystemLocales(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let locale = Locale.current
        let language = locale.languageCode ?? "en"
        let country = locale.regionCode ?? ""
        if country.isEmpty {
            resolve(language.lowercased())
        } else {
            resolve("\(language.lowercased())_\(country.lowercased())")
        }
    }

    @objc func getWindowSize(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            let scale = UIScreen.main.scale
            let bounds = UIScreen.main.bounds
            // JS 端会再除以 scale，所以这里返回像素
            resolve([
                "width": Int(bounds.width * scale),
                "height": Int(bounds.height * scale)
            ])
        }
    }

    @objc func getStatusBarHeight(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            let height = UIApplication.shared.statusBarFrame.size.height
            resolve(Int(height))
        }
    }

    @objc func getSafeAreaInsets(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            var top: CGFloat = 0
            var bottom: CGFloat = 0
            if #available(iOS 11.0, *), let window = UIApplication.shared.keyWindow {
                top = window.safeAreaInsets.top
                bottom = window.safeAreaInsets.bottom
            }
            resolve([
                "top": Int(top),
                "bottom": Int(bottom)
            ])
        }
    }

    @objc func isIgnoringBatteryOptimization(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(false)
    }

    @objc func requestIgnoreBatteryOptimization(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(false)
    }
}
