import Foundation

protocol BridgeModule: class {
    init()
    var moduleName: String { get }
    var methodQueue: dispatch_queue_t { get }
    var methodsToExport: [AnyObject] { get }
}

protocol BridgeModuleWithBridge: class {
    var bridge: Bridge? { get set }
}

protocol BridgeModuleWithConstants: class {
    var constantsToExport: [String: AnyObject] { get }
}

protocol BridgeModuleWithBatchMethods: class {
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
            moduleMethods.append(instance!.methodsToExport)
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
