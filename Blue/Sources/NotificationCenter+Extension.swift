//
//  NotificationCenter+Extension.swift
//  Blue
//
//  Created by Fidetro on 2018/6/5.
//  Copyright © 2018年 Fidetro. All rights reserved.
//

import Foundation

enum BlueToothNotification: String {
    case kCentralManagerDidUpdateState = "kCentralManagerDidUpdateState"
    case kDidDiscoverPeripheral = "kDidDiscoverPeripheral"
    case kDidConnectPeripheral = "kDidConnectPeripheral"
    case kDidFailToConnectPeripheral = "kDidFailToConnectPeripheral"
    case kDidDisconnectPeripheral = "kDidDisconnectPeripheral"
    case kDidDiscoverServices = "kDidDiscoverServices"
    case kDidDiscoverCharacteristics = "kDidDiscoverCharacteristics"
    case kDidUpdateValueForCharacteristic = "kDidUpdateValueForCharacteristic"
    var notificationName : Notification.Name  {
        return Notification.Name(rawValue: self.rawValue )
    }
}

extension NotificationCenter {
    func post(name: BlueToothNotification, object: Any? = nil) {
        NotificationCenter.default.post(name: name.notificationName, object: object)
    }
    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: BlueToothNotification, object anObject: Any?) {
        NotificationCenter.default.addObserver(self, selector: aSelector, name: aName.notificationName, object: anObject)
    }
    
    func addObserver(forName name: BlueToothNotification, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name.notificationName, object: obj, queue: queue, using: block)
    }
    
    
}
