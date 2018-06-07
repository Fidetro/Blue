//
//  BlueManager.swift
//  Blue
//
//  Created by Fidetro on 2018/6/4.
//  Copyright © 2018年 Fidetro. All rights reserved.
//

import UIKit
import CoreBluetooth

func printDebugLog<T>(_ message: T,
                      file: String = #file,
                      method: String = #function,
                      line: Int = #line)
{
    #if DEBUG
    print("\(file)[\(line)], \(method): \(message)")
    #endif
}




extension CBCentralManager {
    public var centralManagerState: CBCentralManagerState  {
        get {
            return CBCentralManagerState(rawValue: state.rawValue) ?? .unknown
        }
    }
}


public class BlueManager: NSObject,CBCentralManagerDelegate,CBPeripheralDelegate {
    public var tag : Int {
        get{
            _tag += 1
            return _tag
        }
        set(value){
            _tag = value
        }
    }
    private var _tag : Int = 0
    public static let share = BlueManager()
    public let centralManager = CBCentralManager()
    
    public var blues = [Blue]()
    
    func scan(_ services:[CBUUID]?=nil) {
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: services, options: nil)
    }
    
    public func currentState() -> CBCentralManagerState {
        return centralManager.centralManagerState
    }
    

}



// MARK: - CBCentralManagerDelegate
extension BlueManager {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        NotificationCenter.default.post(name: .kCentralManagerDidUpdateState, object: central)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        NotificationCenter.default.post(name: .kDidDiscoverPeripheral, object: (central,peripheral,advertisementData,RSSI))
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        NotificationCenter.default.post(name: .kDidConnectPeripheral, object: peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error { printDebugLog(error) }
        NotificationCenter.default.post(name: .kDidFailToConnectPeripheral, object: peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error { printDebugLog(error) }
        NotificationCenter.default.post(name: .kDidDisconnectPeripheral, object: peripheral)
    }
}

extension BlueManager {
    //discover services
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error { printDebugLog(error) }
        NotificationCenter.default.post(name: .kDidDiscoverServices, object: peripheral)
    }
    
    //discover characteristics
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error { printDebugLog(error) }
        NotificationCenter.default.post(name: .kDidDiscoverCharacteristics, object: (peripheral,service))
    }
    
    
    //didUpdateNotificationState
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            printDebugLog("订阅失败: \(error)")
            return
        }
        if characteristic.isNotifying {
            printDebugLog("订阅成功")
        } else {
            printDebugLog("取消订阅")
        }
    }
    
    //update value for characteristic
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        NotificationCenter.default.post(name: .kDidUpdateValueForCharacteristic, object: (peripheral,characteristic))
    }
    
}

