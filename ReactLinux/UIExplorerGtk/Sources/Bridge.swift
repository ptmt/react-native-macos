import JavaScriptCore
import Foundation

typealias JavaScriptCallback = (AnyObject?, NSError?) -> ()

class Block<T>: NSObject {
    let f : T
    init (_ f: T) { self.f = f }
}

public class Bridge {

    private(set) var context: JSContext
    var pendingCalls: [dispatch_block_t] = []
    var moduleClasses: [BridgeModule.Type] = []
    var moduleDataByID: [ModuleData] = []
    var moduleDataByName: [String: ModuleData] = [:]
    var valid: Bool = true
    var loading: Bool = true
    var bundleURL: NSURL

    private var jsTimer: NSTimer
    private var wasBatchActive: Bool = false

    init(withURL: NSURL) {

        context = JSContext()
        bundleURL = withURL
        jsTimer = NSTimer()

        start()
        print("Bridge initialized")
    }

    func start() {

        jsTimer = NSTimer(timeInterval: 0.02, target: self, selector: #selector(Bridge.jsThreadUpdate), userInfo: nil, repeats: true)
        let bridgeQueue: dispatch_queue_t = dispatch_queue_create("com.facebook.react.RCTBridgeQueue", DISPATCH_QUEUE_CONCURRENT)
        let initModulesAndLoadSource: dispatch_group_t = dispatch_group_create()

         // Asynchronously load source code
        dispatch_group_enter(initModulesAndLoadSource)

        var sourceCode: NSData? = nil
        loadSource(onSourceLoad: {
            (error, source) -> () in
            if error != nil {
                dispatch_async(dispatch_get_main_queue(), {
                    print(error?.description)
                });
            }
            sourceCode = source
            dispatch_group_leave(initModulesAndLoadSource)
        })

        // Synchronously initialize all native modules that cannot be loaded lazily
        initModules(withDispatchGroup: initModulesAndLoadSource)

        var config: AnyObject! = nil
        dispatch_group_enter(initModulesAndLoadSource)

        dispatch_async(bridgeQueue, {
            let setupJSExecutorAndModuleConfig:dispatch_group_t = dispatch_group_create()

            // Asynchronously initialize the JS executor
            dispatch_group_async(setupJSExecutorAndModuleConfig, bridgeQueue, {
                 self.executor_setup()
            });

             // Asynchronously gather the module config
            dispatch_group_async(setupJSExecutorAndModuleConfig, bridgeQueue, {
                if self.valid {
                    config = self.moduleConfig()
                }
            });

            dispatch_group_notify(setupJSExecutorAndModuleConfig, bridgeQueue, {
                 // We're not waiting for this to complete to leave dispatch group, since
                 // injectJSONConfiguration and executeSourceCode will schedule operations
                 // on the same queue anyway.

                self.injectJSONConfiguration(config:config, onComplete: { (error) in
                     if let err = error {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.stopLoading(withError: err)
                        })
                    }
                })
                dispatch_group_leave(initModulesAndLoadSource);
            });
        });

        dispatch_group_notify(initModulesAndLoadSource, bridgeQueue, {
            if self.loading {
                if let sourceData = sourceCode {
                    self.execute(sourceCode:sourceData)
                }
            }
        });
    }

    // Do compile-time check instead of conformsToProtocol:
    func registerModule(moduleClass: BridgeModule.Type) {
        moduleClasses.append(moduleClass)
    }

    func initModules(withDispatchGroup: dispatch_group_t) {
        print("TODO: Init extra modules")
        print("TODO: Check for unregistered modules")

        // Temporary we register modules right here:
        registerModule(moduleClass: UIManager.self)

        for moduleClass in moduleClasses {
            let moduleName: String = String(moduleClass)
            var moduleData = moduleDataByName[moduleName]
            if moduleData != nil {
                print("TODO: Check if moduleData correctly initialized")
            }
            moduleData = ModuleData(withModuleClass:moduleClass, withBridge: self)
            moduleDataByID.append(moduleData!)
            moduleDataByName[moduleName] = moduleData!
        }

        print("TODO: setup executor & dispatch module init onto main thread")

        var modulesOnMainThreadCount = 0

        for moduleData in moduleDataByID {
            if moduleData.requiresMainThreadSetup {
                dispatch_group_async(withDispatchGroup, dispatch_get_main_queue(), {
                    if (self.valid) {
                        moduleData.setupInstanceAndBridge()
                        moduleData.gatherConstants()
                    }
                })
                modulesOnMainThreadCount += 1
            } else if moduleData.hasConstantsToExport {
                moduleData.setupInstanceAndBridge()
                dispatch_group_async(withDispatchGroup, dispatch_get_main_queue(), {
                    if (self.valid) {
                        moduleData.gatherConstants()
                    }
                });
                modulesOnMainThreadCount += 1
            }
        }

    }

    func loadSource(onSourceLoad: (NSError?, NSData?) -> ()) {
        javaScriptLoader_loadBundleAtURL(url: bundleURL, completion: onSourceLoad)
    }

    func execute(sourceCode: NSData) {
        if !valid {
            return
        }
        enqueueApplicationScript(script: sourceCode, url: bundleURL, onComplete: {
            (loadingError: NSError?) in
            if !self.valid {
                return;
            }

            if let error = loadingError {
                dispatch_async(dispatch_get_main_queue(), {
                    self.stopLoading(withError: error)
                })
                return;
            }

            let targetRunLoop = NSRunLoop.current()
            targetRunLoop.add(_: self.jsTimer, forMode: NSRunLoopCommonModes)
            print("execute(sourceCode: NSData) targetRunLoop")
        })
    }

    func enqueueApplicationScript(script: NSData, url: NSURL, onComplete: (NSError?) -> ()) {
        // this assert is no longer needed
        // assert(onComplete != nil, "onComplete block passed in should be non-nil")
        executor_executeApplicationScript(script: script, sourceURL: url, onComplete: { (scriptLoadError) in
            if scriptLoadError != nil {
                return onComplete(scriptLoadError)
            }
            self.executor_flushedQueue(onComplete: { (json, error) in
                self.handleBuffer(buffer: json, batchEnded:true)
                onComplete(error);
            })

        })
    }

    @objc(jsThreadUpdate)
    func jsThreadUpdate() {
        print(".")
    }

    func stopLoading(withError: NSError) {
        print("stopLoading withError", withError.description)
    }

    func handleBuffer(buffer: AnyObject?, batchEnded: Bool) {
        if let bufferData = buffer {
            wasBatchActive = true
            handleBuffer(buffer: bufferData)
            //[self partialBatchDidFlush];
        }

        if batchEnded {
            if wasBatchActive {
              //[self batchDidComplete];
            }
            wasBatchActive = false
        }

    }

    func handleBuffer(buffer: AnyObject) {
        print("handleBuffer", buffer)
    }

    func javaScriptLoader_loadBundleAtURL(url: NSURL, completion: (NSError?, NSData?) -> ()) {

        NSURLSession.shared().dataTask(with:  url, completionHandler: { (data, response, error) in
            if error != nil {
                let description = "Could not connect to development server.\n\nEnsure the following:\n- Node server is running and available on the same network - run 'npm start' from react-native root\n- Node server URL is correctly set in AppDelegate\n\nURL: " + url.absoluteString
                let userInfo: [String: AnyObject] = [
                    NSLocalizedDescriptionKey: description,
                    NSLocalizedFailureReasonErrorKey: error!.localizedDescription,
                    NSUnderlyingErrorKey: error!,
                ]
                completion(NSError.init(domain: "JSServer", code: error!.code, userInfo: userInfo), data)
            } else {
                if (response as! NSHTTPURLResponse).statusCode != 200 {
                    completion(NSError.init(domain: "JSServer", code: (response as! NSHTTPURLResponse).statusCode, userInfo: [:]), data)
                }
                completion(nil, data)
            }

            }).resume()
    }

    func injectJSONConfiguration(config: AnyObject?, onComplete:(NSError?) -> ()) {
        if let json = config {
            executor_injectJSON(json:json, asGlobalObjectNamed:"__fbBatchedBridgeConfig", callback:onComplete)
        }
    }

    func moduleConfig() -> AnyObject {
        let config = moduleDataByID.map {
            return [$0.name]
        }

        return [
            "remoteModuleConfig": config,
            "localModulesConfig": []
        ]
    }

    func config(forModuleName moduleName: String) -> [AnyObject]? {
        if let moduleData = moduleDataByName[moduleName] {
            return moduleData.config
        } else if let moduleData = moduleDataByName["RCT\(moduleName)"] {
            return moduleData.config
        }
        return nil;
    }

    func registerModuleForFrameUpdates(instance: BridgeModule, withModuleData: ModuleData) {
        print("TODO: registerModuleForFrameUpdates")
    }
    
    func executor_evaluateScript(script: String) -> JSValue? {
      return context.evaluateScript(script)
    }

    func executor_injectJSON(json: AnyObject, asGlobalObjectNamed: String, callback:(NSError?) -> ()) {
        executor_executeBlockOnJavaScriptQueue(block: {
            self.context.setObject(json, forKeyedSubscript: asGlobalObjectNamed)
            callback(nil)
        })
    }

    func executor_setup() {
        let log : @convention(block) (String, NSNumber) -> Void = {
            message, logLevel in
            print("console.log -> ", message)
        }
        let noop : @convention(block) () -> Void = {
            print("noop")
        }
        let nativeRequireModuleConfig: @convention(block) (String) -> String = {
            moduleName in
            print("nativeRequireModuleConfig", moduleName)
//            if (!strongSelf.valid) {
//                return nil;
//            }
//
//            RCT_PROFILE_BEGIN_EVENT(0, @"nativeRequireModuleConfig", nil);
            if let config = self.config(forModuleName: moduleName) {
                let result = JSONStringify(jsonObject: config)
                print("nativeRequireModuleConfig", result)
                return result
            }
            return ""
        }
        executor_addSynchronousHook(withName: "noop", usingBlock:unsafeBitCast(_: noop, to: AnyObject.self))
        executor_addSynchronousHook(withName: "nativeLoggingHook", usingBlock:unsafeBitCast(_: log, to: AnyObject.self))
        executor_addSynchronousHook(withName: "nativeRequireModuleConfig", usingBlock:unsafeBitCast(_: nativeRequireModuleConfig, to: AnyObject.self))
        executor_addSynchronousHook(withName: "nativeFlushQueueImmediate", usingBlock:unsafeBitCast(_: noop, to: AnyObject.self))
        executor_addSynchronousHook(withName: "nativeInjectHMRUpdate", usingBlock:unsafeBitCast(_: noop, to: AnyObject.self))
    }

    func executor_addSynchronousHook(withName name: String, usingBlock block:AnyObject) {
        context.setObject(block, forKeyedSubscript: name)
    }

    func executor_executeApplicationScript(script: NSData, sourceURL: NSURL, onComplete: NSError? -> ()) {
        executor_executeBlockOnJavaScriptQueue(block: {
            if (!self.valid) {
                return
            }
            if let str = String(data: script, encoding: NSUTF8StringEncoding) {
                self.context.evaluateScript(_: str, withSourceURL: sourceURL)
                if self.context.exception != nil {
                    onComplete(NSError(domain: "JSError", code: 2, userInfo: ["description":self.context.exception.toString() ]))
                }
                onComplete(nil);

            }
        })

    }

    func executor_executeBlockOnJavaScriptQueue(block: dispatch_block_t)
    {
        print("TODO: Execute block() on JavaScript Thread")
        block()
    }

    func executor_flushedQueue(onComplete: JavaScriptCallback) {
        executor_executeJSCall(method: "flushedQueue", arguments:[], callback:onComplete)
    }

    func executor_executeJSCall(method: String, arguments:[AnyObject], callback: JavaScriptCallback) {
        let jsonArguments = JSONStringify(jsonObject: arguments)
        let script =  "__fbBatchedBridge.\(method).apply(null, \(jsonArguments))"
        let result = self.context.evaluateScript(_: script)
        if let err = self.context.exception {
            print(err)
            callback(result, nil)
        } else {
            callback(result, nil)
        }
//        
//        if let bridge = context.objectForKeyedSubscript("__fbBatchedBridge") {
//
//
//        } else {
//            print("Unable to execute JS call: __fbBatchedBridge is undefined")
//            let userInfo = ["description": "Unable to execute JS call: __fbBatchedBridge is undefined"]
//            callback(nil, NSError(domain: "", code: 1, userInfo: userInfo))
//        }
    }
}
