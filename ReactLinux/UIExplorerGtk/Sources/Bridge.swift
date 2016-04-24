import JavaScriptCore
import Foundation

public class Bridge {

    public var context: JSContext
    var pendingCalls: [dispatch_block_t]
    var moduleDataByID: [AnyObject]
    var valid: Bool
    var loading: Bool
    var bundleURL: NSURL

    init(withURL: NSURL) {

        context = JSContext()
        pendingCalls = []
        moduleDataByID = []
        loading = true
        valid = true
        bundleURL = withURL

        start()
        print("Bridge initialized")
    }

    func start() {

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

        var config: String = ""
        dispatch_group_enter(initModulesAndLoadSource)

        dispatch_async(bridgeQueue, {
            let setupJSExecutorAndModuleConfig:dispatch_group_t = dispatch_group_create()

            // Asynchronously initialize the JS executor
//            dispatch_group_async(setupJSExecutorAndModuleConfig, bridgeQueue, ^{
//                 setupExecutor()
//            });

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

    func initModules(withDispatchGroup: dispatch_group_t) {
        print("initModules:withDispatchGroup")
    }

    func loadSource(onSourceLoad: (NSError?, NSData?) -> ()) {
        javaScriptLoader_loadBundleAtURL(url: bundleURL, completion: onSourceLoad)
    }

    func execute(sourceCode: NSData) {
        if !valid {
            return
        }
        print("executeSourceCode")
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
        })
    }

    func enqueueApplicationScript(script: NSData, url: NSURL, onComplete: (NSError?) -> ()) {
        //assert(onComplete != nil, "onComplete block passed in should be non-nil")
        executor_executeApplicationScript(script: script, sourceURL: url, onComplete: { (scriptLoadError) in

        })
//        [_javaScriptExecutor executeApplicationScript:script sourceURL:url onComplete:^(NSError *scriptLoadError) {
//            RCTProfileEndFlowEvent();
//            RCTAssertJSThread();
//
//            if (scriptLoadError) {
//            onComplete(scriptLoadError);
//            return;
//            }
//
//            RCT_PROFILE_BEGIN_EVENT(0, @"FetchApplicationScriptCallbacks", nil);
//            [_javaScriptExecutor flushedQueue:^(id json, NSError *error)
//            {
//            RCT_PROFILE_END_EVENT(0, @"js_call,init", @{
//            @"json": RCTNullIfNil(json),
//            @"error": RCTNullIfNil(error),
//            });
//            
//            [self handleBuffer:json batchEnded:YES];
//            
//            onComplete(error);
//            }];
//            }];
    }

    func stopLoading(withError: NSError) {
        print("stopLoading withError", withError.description)
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

    func injectJSONConfiguration(config: String, onComplete:(NSError?) -> ()) {
        print("injectJSONConfiguration")
        onComplete(nil)
    }

    func moduleConfig() -> String {
//        let config: [[AnyObject]]
//        for (RCTModuleData *moduleData in _moduleDataByID) {
//            if (self.executorClass == [RCTJSCExecutor class]) {
//                [config addObject:@[moduleData.name]];
//            } else {
//                [config addObject:RCTNullIfNil(moduleData.config)];
//            }
//        }
//
//        return RCTJSONStringify(@{
//            @"remoteModuleConfig": config,
//        }, NULL);
        return "not implemented"
    }

    func executor_evaluateScript(script: String) -> JSValue? {
      return context.evaluateScript(
          "var a = 1; var b = 2; a + b"
      )
    }

    func executor_executeApplicationScript(script: NSData, sourceURL: NSURL, onComplete: NSError? -> ()) {
        executor_executeBlockOnJavaScriptQueue(block: {
            if (!self.valid) {
                return
            }
            if let str = String(data: script, encoding: NSUTF8StringEncoding) {
                self.context.evaluateScript(_: str, withSourceURL: sourceURL)
                if self.context.exception != nil {
                    print(self.context.exception.toString())
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
}
