//
//  UserApiModule.swift
//  LxMusicMobile
//
//  Created by Doubao.
//

import Foundation
import React
import JavaScriptCore

@objc(UserApiModule)
class UserApiModule: RCTEventEmitter {
    override static func moduleName() -> String! {
        return "UserApiModule"
    }

    var jsContext: JSContext?
    var hasListeners: Bool = false

    override static func requiresMainQueueSetup() -> Bool {
        return false
    }

    override func supportedEvents() -> [String]! {
        return ["api-action"]
    }

    override func startObserving() {
        hasListeners = true
    }

    override func stopObserving() {
        hasListeners = false
    }

    @objc func loadScript(_ data: NSDictionary) {
        destroy()

        let script = data["script"] as? String ?? ""
        let infoId = data["id"] as? String ?? ""
        let infoName = data["name"] as? String ?? ""

        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else { return }

            let context = JSContext()!
            context.name = "UserApiContext"

            context.exceptionHandler = { ctx, exception in
                let err = exception?.toString() ?? "unknown"
                self.sendEvent(action: "log", data: ["error", "JS Exception: \(err)"])
            }

            // window object
            let window = JSValue(newObjectIn: context)!
            context.setObject(window, forKeyedSubscript: "window" as NSString)

            // userApi object
            let userApi = JSValue(newObjectIn: context)!

            // userApi.sendRequest(requestKey, url, options)
            userApi.setObject({ (requestKey: String, url: String, options: JSValue) -> Void in
                let opts = options.toDictionary() as? [String: Any] ?? [:]
                self.sendEvent(action: "request", data: [
                    "requestKey": requestKey,
                    "url": url,
                    "options": [
                        "method": opts["method"] as? String ?? "GET",
                        "data": opts["data"] ?? [:],
                        "timeout": opts["timeout"] as? Int ?? 15000,
                        "headers": opts["headers"] ?? [:],
                        "binary": opts["binary"] as? Bool ?? false,
                    ]
                ])
            }, forKeyedSubscript: "sendRequest" as NSString)

            // userApi.cancelRequest(requestKey)
            userApi.setObject({ (requestKey: String) -> Void in
                self.sendEvent(action: "cancelRequest", data: requestKey)
            }, forKeyedSubscript: "cancelRequest" as NSString)

            // userApi.log(msg)
            userApi.setObject({ (msg: String) -> Void in
                self.sendEvent(action: "log", data: msg)
            }, forKeyedSubscript: "log" as NSString)

            // userApi.init(status, errorMessage, info)
            userApi.setObject({ (status: Bool, errorMessage: String, info: JSValue) -> Void in
                var infoDict: [String: Any] = ["id": infoId, "name": infoName]
                if let infoObj = info.toDictionary() as? [String: Any] {
                    infoDict.merge(infoObj) { _, new in new }
                }
                self.sendEvent(action: "init", data: [
                    "status": status,
                    "errorMessage": errorMessage,
                    "info": infoDict
                ])
            }, forKeyedSubscript: "init" as NSString)

            // userApi.showUpdateAlert(name, log, updateUrl)
            userApi.setObject({ (name: String, log: String, updateUrl: String) -> Void in
                self.sendEvent(action: "showUpdateAlert", data: [
                    "name": name, "log": log, "updateUrl": updateUrl
                ])
            }, forKeyedSubscript: "showUpdateAlert" as NSString)

            window.setObject(userApi, forKeyedSubscript: "userApi" as NSString)
            context.setObject(userApi, forKeyedSubscript: "userApi" as NSString)

            // Run user script
            context.evaluateScript(script)

            self.jsContext = context
        }
    }

    @objc func sendAction(_ action: String, info: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let context = self.jsContext else {
            resolve(false)
            return
        }

        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else { resolve(false); return }

            if action == "response" {
                guard let data = info.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    resolve(false)
                    return
                }

                let requestKey = json["requestKey"] as? String ?? ""
                let error: Any = json["error"] as? String ?? NSNull()
                let response: Any = json["response"] ?? NSNull()

                let userApi = context.objectForKeyedSubscript("userApi")
                let callback = userApi?.objectForKeyedSubscript("_handleResponse")
                if let cb = callback, cb.isFunction {
                    cb.call(withArguments: [requestKey, error, response])
                }
            }

            resolve(true)
        }
    }

    @objc func destroy() {
        DispatchQueue.global(qos: .default).async { [weak self] in
            self?.jsContext = nil
        }
    }

    func sendEvent(action: String, data: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.hasListeners else { return }
            var body: [String: Any] = ["action": action]
            if let dataStr = data as? String {
                body["data"] = dataStr
            } else if let jsonData = try? JSONSerialization.data(withJSONObject: data),
                      let jsonStr = String(data: jsonData, encoding: .utf8) {
                body["data"] = jsonStr
            }
            self.sendEvent(withName: "api-action", body: body)
        }
    }
}
