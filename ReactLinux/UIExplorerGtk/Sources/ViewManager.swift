import Foundation

public class View {

}

public class ShadowView {

}

public class ViewManager: BridgeModule, BridgeModuleWithConstants, BridgeModuleWithBridge {
    required public init() {
        //    let queueName = "com.facebook.react.ShadowQueue"
        //    shadowQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL)
        //    dispatch_set_target_queue(shadowQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
    }

    public var moduleName: String { return "UIManager" }
    public var methodQueue: dispatch_queue_t { return bridge!.uiManager!.methodQueue }

    var bridge: Bridge? = nil {
        didSet {

        }
    }

    var view: View { return View() }
    var shadowView: ShadowView { return ShadowView() }

    var customBubblingEventTypes: [String] {
        return [
            // Generic events
            "press",
            "change",
            "focus",
            "blur",
            "submitEditing",
            "endEditing",
            "keyPress",

            // Touch events
            "touchStart",
            "touchMove",
            "touchCancel",
            "touchEnd",
        ]
    }

    var constantsToExport: [String : AnyObject] {
        return [:]
    }

    var methodsToExport: [AnyObject] {
        return []
    }

 }