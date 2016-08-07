import Foundation

public class UIManager: BridgeModule, BridgeModuleWithConstants, BridgeModuleWithBridge, BridgeModuleWithBatchMethods {

    var shadowQueue: dispatch_queue_t

    public var moduleName: String { return "UIManager" }
    public var methodQueue: dispatch_queue_t { return shadowQueue }
    var componentDataByName: [String: AnyObject?] = [:]
    var bridge: Bridge? = nil {
        didSet {
            for moduleClass in bridge!.moduleClasses {
                if moduleClass is ViewManager.Type {
                //                    RCTComponentData *componentData = [[RCTComponentData alloc] initWithManagerClass:moduleClass
                //                        bridge:_bridge];
                //                    componentDataByName[componentData.name] = componentData;
                }
            }
        }
    }


    required public init() {
        let queueName = "com.facebook.react.ShadowQueue"
        shadowQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL)
        dispatch_set_target_queue(shadowQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
    }

    var methodsToExport: [AnyObject] { get {
        return []
        }
    }

    var constantsToExport: [String: AnyObject] {
        get {
            var allJSConstants = [String: AnyObject]()
            var directEvents = [String: AnyObject]()
            var bubblingEvents = [String: AnyObject]()
            //            [_componentDataByName enumerateKeysAndObjectsUsingBlock:
            //                ^(NSString *name, RCTComponentData *componentData, __unused BOOL *stop) {
            //
            //                NSMutableDictionary<NSString *, id> *constantsNamespace =
            //                [NSMutableDictionary dictionaryWithDictionary:allJSConstants[name]];
            //
            //                // Add manager class
            //                constantsNamespace[@"Manager"] = RCTBridgeModuleNameForClass(componentData.managerClass);
            //
            //                // Add native props
            //                NSDictionary<NSString *, id> *viewConfig = [componentData viewConfig];
            //                constantsNamespace[@"NativeProps"] = viewConfig[@"propTypes"];
            //
            //                // Add direct events
            //                for (NSString *eventName in viewConfig[@"directEvents"]) {
            //                if (!directEvents[eventName]) {
            //                directEvents[eventName] = @{
            //                @"registrationName": [eventName stringByReplacingCharactersInRange:(NSRange){0, 3} withString:@"on"],
            //                };
            //                }
            //                if (RCT_DEBUG && bubblingEvents[eventName]) {
            //                RCTLogError(@"Component '%@' re-registered bubbling event '%@' as a "
            //                "direct event", componentData.name, eventName);
            //                }
            //                }
            //
            //                // Add bubbling events
            //                for (NSString *eventName in viewConfig[@"bubblingEvents"]) {
            //                if (!bubblingEvents[eventName]) {
            //                NSString *bubbleName = [eventName stringByReplacingCharactersInRange:(NSRange){0, 3} withString:@"on"];
            //                bubblingEvents[eventName] = @{
            //                @"phasedRegistrationNames": @{
            //                @"bubbled": bubbleName,
            //                @"captured": [bubbleName stringByAppendingString:@"Capture"],
            //                }
            //                };
            //                }
            //                if (RCT_DEBUG && directEvents[eventName]) {
            //                RCTLogError(@"Component '%@' re-registered direct event '%@' as a "
            //                "bubbling event", componentData.name, eventName);
            //                }
            //            }
            //
            //            allJSConstants[name] = constantsNamespace;
            //            }];

            //            [allJSConstants addEntriesFromDictionary:@{
            //                @"customBubblingEventTypes": bubblingEvents,
            //                @"customDirectEventTypes": directEvents,
            //                "Dimensions": exportedDimensions()
            //            }];
            allJSConstants["customBubblingEventTypes"] = bubblingEvents
            allJSConstants["customDirectEventTypes"] = directEvents
            allJSConstants["Dimensions"] = exportedDimensions()
            
            return allJSConstants
        }
    }
    
    func exportedDimensions() -> AnyObject {
        //RCTAssertMainThread();
        return [
                   "window": [
                                 "width": 100,
                                 "height": 200,
                                 "scale": 1,
            ]
        ]
    }
    
    func batchDidComplete() -> () {
        
    }
    
    func partialBatchDidFlush() -> () {
        
    }
}