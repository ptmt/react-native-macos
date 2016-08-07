//
//  ComponentData.swift
//  UIExplorerGtk
//
//  Created by Dmitriy Loktev on 5/7/16.
//
//

import Foundation

public class ComponentData {
    var managerClass: BridgeModule.Type
    var bridge: Bridge
    var name: String { return String(managerClass) }
    var manager: ViewManager { return bridge.moduleDataByName[String(managerClass)]!.instance as! ViewManager }
//    @property (nonatomic, readonly) Class managerClass;
//    @property (nonatomic, copy, readonly) NSString *name;
//    @property (nonatomic, weak, readonly) RCTViewManager *manager;

    init(withManagerClass: BridgeModule.Type, withBridge: Bridge) {
        managerClass = withManagerClass
        bridge = withBridge
    }
//    - (instancetype)initWithManagerClass:(Class)managerClass
//    bridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;
//
//    - (UIView *)createViewWithTag:(NSNumber *)tag;
//    - (RCTShadowView *)createShadowViewWithTag:(NSNumber *)tag;
//    - (void)setProps:(NSDictionary<NSString *, id> *)props forView:(id<RCTComponent>)view;
//    - (void)setProps:(NSDictionary<NSString *, id> *)props forShadowView:(RCTShadowView *)shadowView;
//
//    - (NSDictionary<NSString *, id> *)viewConfig;
//
//    - (RCTViewManagerUIBlock)uiBlockToAmendWithShadowViewRegistry:(NSDictionary<NSNumber *, RCTShadowView *> *)registry;

}