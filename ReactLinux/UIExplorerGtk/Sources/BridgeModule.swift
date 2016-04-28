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
    func methodsToExport() -> [AnyObject]
    func constantsToExport() -> [String: Any]
    func batchDidComplete() -> ()
    func partialBatchDidFlush() -> ()
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

    var name: String { get { return String(moduleClass) }}

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
            let constants = (instance as! BridgeModuleWithConstants).constantsToExport()
            print(constants)
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

    func methodsToExport() -> [AnyObject] {
        return []
    }

    func constantsToExport() -> [String: Any] {
        return [:]
    }

    func batchDidComplete() -> () {

    }
    
    func partialBatchDidFlush() -> () {

    }
}