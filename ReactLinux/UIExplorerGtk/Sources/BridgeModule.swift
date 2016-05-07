import Foundation

protocol BridgeModule: class {
    init()
    var moduleName: String { get }
    var methodQueue: dispatch_queue_t { get }
}

protocol BridgeModuleWithBridge: class {
    var bridge: Bridge? { get set }
}

protocol BridgeModuleWithConstants: class {
    var methodsToExport: [AnyObject] { get }
    var constantsToExport: [String: AnyObject] { get }
    func batchDidComplete() -> ()
    func partialBatchDidFlush() -> ()
}

protocol BridgeMethod {

}

public class ModuleData {
    private(set) var requiresMainThreadSetup: Bool = true
    private(set) var hasConstantsToExport: Bool = true
    private(set) var implementsBatchDidComplete: Bool = true
    private(set) var instance: BridgeModule? = nil

    private var moduleClass: BridgeModule.Type
    private var bridge: Bridge
    private var _instance: BridgeModule?
    private var setupIsComplete: Bool = false
    private var constantsToExport: [String: AnyObject]? = nil
    private var _config: [AnyObject]? = nil

    var name: String { get { return String(moduleClass) }}

    // feels not swifty
    var config: [AnyObject]? {
        get {
            if _config == nil {
                return getConfig()
            }
            return _config
        }
    }

    init(withModuleClass: BridgeModule.Type, withBridge: Bridge) {
        bridge = withBridge
        moduleClass = withModuleClass
        self.setup()
    }

    func setup() {
        print("TODO: ModuleData:setup()")
    }

    func setupInstanceAndBridge() {
        print("TODO: ModuleData: instance init on main thread if required")
        print("TODO: ModuleData: instance lock")
        if instance == nil {
            instance = moduleClass.init()
            setupBridgeForInstance()
            setupMethodQueue()
            finishSetupForInstance()
        }
    }

    func gatherConstants() {
        if instance is BridgeModuleWithConstants {
            constantsToExport = (instance as! BridgeModuleWithConstants).constantsToExport
        }
    }

    func setupBridgeForInstance() {
        if instance is BridgeModuleWithBridge {
            (instance as! BridgeModuleWithBridge).bridge = bridge
        }
    }

    func setupMethodQueue() {
        print("TODO: setupMethodQueue")
//        let queueName = String("com.facebook.react.\(self.name)Queue")
//        let methodQueue = dispatch_queue_create((queueName as NSString).utf8String, DISPATCH_QUEUE_SERIAL)
//        instance!.methodQueue = methodQueue
    }

    func finishSetupForInstance() {
        if instance != nil {
            setupIsComplete = true
            bridge.registerModuleForFrameUpdates(instance:instance!, withModuleData:self)
            print("TODO: post notification about module initialized")
//            [[NSNotificationCenter defaultCenter] postNotificationName:RCTDidInitializeModuleNotification
//                object:_bridge
//                userInfo:@{@"module": _instance}];
        }
    }

    func getMethods() -> [AnyObject]? {
        print("TODO: BridgeData getMethods()")
        var moduleMethods: [AnyObject] = []

        //    NSMutableArray<id<RCTBridgeMethod>> *moduleMethods = [NSMutableArray new];

        if moduleClass is BridgeModuleWithConstants {
            moduleMethods.append(contentsOf: (instance as! BridgeModuleWithConstants).methodsToExport)
        }
        let methods = Mirror(reflecting: moduleClass)
        print("mirror: ", methods.description)
        for case let (label?, value) in methods.children {
            print ("mirror: children", label, value)
        }
//
//            unsigned int methodCount;
//            Method *methods = class_copyMethodList(object_getClass(_moduleClass), &methodCount);
//
//            for (unsigned int i = 0; i < methodCount; i++) {
//                Method method = methods[i];
//                SEL selector = method_getName(method);
//                if ([NSStringFromSelector(selector) hasPrefix:@"__rct_export__"]) {
//                    IMP imp = method_getImplementation(method);
//                    NSArray<NSString *> *entries =
//                        ((NSArray<NSString *> *(*)(id, SEL))imp)(_moduleClass, selector);
//                    id<RCTBridgeMethod> moduleMethod =
//                        [[RCTModuleMethod alloc] initWithMethodSignature:entries[1]
//                            JSMethodName:entries[0]
//                            moduleClass:_moduleClass];
//                    
//                    [moduleMethods addObject:moduleMethod];
//                }
//            }
        return moduleMethods
    }
    

    func getConfig() -> [AnyObject]? {
        if constantsToExport == nil {
            gatherConstants()
        }

        if (constantsToExport == nil) {
            return nil
        }

        var methods: [String] = [] //self.methods.count ? [NSMutableArray new] : nil;
        var asyncMethods: [String] = []
        var config: [AnyObject] = []

        for method in getMethods()! {
            print(method)
        }
//        for (id<RCTBridgeMethod> method in self.methods) {
//            if (method.functionType == RCTFunctionTypePromise) {
//            if (!asyncMethods) {
//            asyncMethods = [NSMutableArray new];
//            }
//            [asyncMethods addObject:@(methods.count)];
//            }
//            [methods addObject:method.JSMethodName];
//        }
//
//        NSMutableArray *config = [NSMutableArray new];
        config.append(name)
        config.append(constantsToExport!)
//        [config addObject:self.name];
//        if (constants.count) {
//        [config addObject:constants];
//        }
//        if (methods) {
//        [config addObject:methods];
//        if (asyncMethods) {
//        [config addObject:asyncMethods];
//        }
//        }

        _config = config
        return _config;
    }
}

public class UIManager: BridgeModule, BridgeModuleWithConstants, BridgeModuleWithBridge {

    var shadowQueue: dispatch_queue_t

    var moduleName: String { return "UIManager" }
    var bridge: Bridge? = nil
    var methodQueue: dispatch_queue_t { return shadowQueue }

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
//            NSMutableDictionary<NSString *, NSDictionary *> *allJSConstants = [NSMutableDictionary new];
//            NSMutableDictionary<NSString *, NSDictionary *> *directEvents = [NSMutableDictionary new];
//            NSMutableDictionary<NSString *, NSDictionary *> *bubblingEvents = [NSMutableDictionary new];

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