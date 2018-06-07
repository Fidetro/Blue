//
//  Blue.swift
//  Blue
//
//  Created by Fidetro on 2018/6/4.
//  Copyright © 2018年 Fidetro. All rights reserved.
//

import UIKit
import CoreBluetooth

public typealias ScanWithServices = ((_ central: CBCentralManager)->())
public typealias DiscoverSave = ((_ central: CBCentralManager, _ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ RSSI: NSNumber)->((key:String,peripheral:CBPeripheral)?))
public typealias DiscoverConnect = ((_ peripheral:CBPeripheral)->())

public typealias DiscoverServices = ((_ peripheral:CBPeripheral)->())
public typealias DiscoverForServices = ((_ peripheral: CBPeripheral, _ service:CBService)->(CBService))
public typealias ReadValueForCharacteristics = ((_ characteristic:CBCharacteristic)->(CBCharacteristic?))
public typealias SetNotifyForCharacteristics = ((_ characteristic:CBCharacteristic)->(CBCharacteristic?))
public typealias WriteForCharacteristics = ((_ characteristic:CBCharacteristic)->(CBCharacteristic?))
public typealias UpdateValueForCharacteristic = ((_ characteristic:CBCharacteristic,_ value:Data?)->())

public typealias DidConnect = ((_ peripheral:CBPeripheral)->())
public typealias DidFailConnect = ((_ peripheral:CBPeripheral)->())
public typealias DidDisconnect = ((_ peripheral:CBPeripheral)->())

public typealias Operation = (()->())
public typealias Done = (()->())

public class Blue: NSObject {
    
    private var scanWithServices : ScanWithServices?=nil
    private var discoverSave : DiscoverSave?=nil
    private var discoverConnect : DiscoverConnect?=nil
    private var discoverServices : DiscoverServices?=nil
    private var discoverForServices : DiscoverForServices?=nil
    private var readValueForCharacteristics : ReadValueForCharacteristics?=nil
    private var setNotifyForCharacteristics : SetNotifyForCharacteristics?=nil
    private var writeForCharacteristics : WriteForCharacteristics?=nil
    private var updateValueForCharacteristic : UpdateValueForCharacteristic?=nil
    
    private var didConnect : DidConnect?=nil
    private var didFailConnect : DidFailConnect?=nil
    private var didDisconnect : DidDisconnect?=nil
    
    /// 读取特征的数组
    private var readCharacteristicsArray = [CBCharacteristic]()
    /// 监听特征的数组
    private var notifyCharacteristicsArray = [CBCharacteristic]()
    /// 写入特征的数组
    private var writeCharacteristicsArray = [CBCharacteristic]()
    
    
    public var connectPeripheral : CBPeripheral?
    
    private var localeChangeObserver:NSObjectProtocol! = nil
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.fidetro.Blue"+"."+"\(BlueManager.share.tag)", qos: .utility, attributes: .concurrent)
    private let group = DispatchGroup()
    private let sleepUnLock = TimeInterval(5)
    
    
    public override init() {
        super.init()
        
        register()
    }
    
    private func async(_ operation:Operation?=nil) {
        group.enter()
        queue.async(group: group,flags: .barrier) {
            self.lock.lock(before: Date.init(timeIntervalSince1970: Date().timeIntervalSince1970+self.sleepUnLock))
            
            if let operation = operation {
                operation()
                self.group.leave()
            }
        }
    }
    
    
    
    public func done(_ done:Done?=nil) -> Blue {
        async {
            if let done = done {
                done()
                self.lock.unlock()
            }
        }
        return self
    }
    
    public func scan(discoverSave: DiscoverSave?=nil) -> Blue {
        if BlueManager.share.centralManager.state == .poweredOn {
            BlueManager.share.scan()
        }else{
            scanWithServices = { (central) in
                BlueManager.share.scan()
            }
        }
        self.discoverSave = discoverSave
        
        return self
    }
    
    /// 连接设备
    @discardableResult
    public func connect() -> Blue {
        async {
            self.discoverConnect = { (peripheral) in
                BlueManager.share.centralManager.connect(peripheral, options: nil)
            }
        }
        return self
    }
    
    /// 发现服务
    @discardableResult
    public func discoverServices(_ servicesUUIDs:[CBUUID]?,forServices:DiscoverForServices?=nil) -> Blue {
        async {
            self.discoverServices = { [weak self] (peripheral) in
                peripheral.discoverServices(servicesUUIDs)
                self?.discoverForServices = forServices
            }
            
        }
        return self
    }
    
    /// 发现特征
    @discardableResult
    public func discoverCharacteristics(readFor:ReadValueForCharacteristics?=nil,setNotify:SetNotifyForCharacteristics?=nil,writeFor:WriteForCharacteristics?=nil) -> Blue {
        async {
            self.readValueForCharacteristics = readFor
            self.setNotifyForCharacteristics = setNotify
            self.writeForCharacteristics = writeFor
        }
        return self
    }
    
    @discardableResult
    public func update(value:UpdateValueForCharacteristic?=nil) -> Blue {
        self.updateValueForCharacteristic = value
        return self
    }
    
    public func write(data:Data,characteristicUUID:CBUUID) -> Bool {
        for characteristic in writeCharacteristicsArray {
            if characteristic.uuid.uuidString == characteristicUUID.uuidString {
                connectPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
                return true
            }
        }
        return false
    }
    
    @discardableResult
    public func stopScan() -> Blue {
        async {
            BlueManager.share.centralManager.stopScan()
            self.lock.unlock()
        }
        
        return self
    }
    
}

extension Blue {
    
    func register() {
        BlueManager.share.blues.append(self)
        self.localeChangeObserver = NotificationCenter.default.addObserver(forName: .kCentralManagerDidUpdateState, object: nil, queue: .main) { (notification) in
            guard let central = notification.object as? CBCentralManager else { assertionFailure(); return }            
            switch central.state {
            case .unknown:
                break
            case .resetting:
                break
            case .unsupported:
                break
            case .unauthorized:
                break
            case .poweredOff:
                break
            case .poweredOn:
                break
            }
        }
        
        self.localeChangeObserver = NotificationCenter.default.addObserver(forName: .kDidDiscoverPeripheral, object: nil, queue: .main) { (notification) in
            guard let tuple = notification.object as? (central: CBCentralManager,peripheral: CBPeripheral,advertisementData: [String : Any],RSSI: NSNumber) else { assertionFailure(); return }
            if let discoverSave = self.discoverSave {
                let save = discoverSave(tuple.central,tuple.peripheral,tuple.advertisementData,tuple.RSSI)
                //得到过滤之后的外设
                if let save = save {
                    //将外设保存
                    self.connectPeripheral = save.peripheral
                    if let discoverConnect = self.discoverConnect {
                        discoverConnect(save.peripheral)
                    }
                    
                }
            }
        }
        
        self.localeChangeObserver = NotificationCenter.default.addObserver(forName: .kDidConnectPeripheral, object: nil, queue: .main) { (notification) in
            guard let peripheral = notification.object as? CBPeripheral,peripheral == self.connectPeripheral else { return }
            if let discoverServices = self.discoverServices {
                discoverServices(peripheral)
            }
            if let didConnect = self.didConnect {
                didConnect(peripheral)
            }
            self.lock.unlock()
        }
        
        self.localeChangeObserver = NotificationCenter.default.addObserver(forName: .kDidFailToConnectPeripheral, object: nil, queue: .main) { (notification) in
            guard let peripheral = notification.object as? CBPeripheral,peripheral == self.connectPeripheral else { assertionFailure(); return }
            if let didFailConnect = self.didFailConnect {
                didFailConnect(peripheral)
            }
            self.lock.unlock()
        }
        
        self.localeChangeObserver = NotificationCenter.default.addObserver(forName: .kDidDisconnectPeripheral, object: nil, queue: .main) { (notification) in
            guard let peripheral = notification.object as? CBPeripheral,peripheral == self.connectPeripheral else { return }
            if let didDisconnect = self.didDisconnect {
                didDisconnect(peripheral)
            }
            self.lock.unlock()
        }
        
        self.localeChangeObserver = NotificationCenter.default.addObserver(forName: .kDidDiscoverServices, object: nil, queue: .main) { (notification) in
            guard let peripheral = notification.object as? CBPeripheral,peripheral == self.connectPeripheral else { return }
            guard let services  = peripheral.services  else { return }
            
            for service in services {
                if let discoverForServices = self.discoverForServices {
                    let service = discoverForServices(peripheral,service)
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            self.lock.unlock()
        }
        
        self.localeChangeObserver = NotificationCenter.default.addObserver(forName: .kDidDiscoverCharacteristics, object: nil, queue: .main) { (notification) in
            guard let tuple = notification.object as? (peripheral: CBPeripheral,service: CBService),tuple.peripheral == self.connectPeripheral else { assertionFailure(); return }
            guard let characteristics = tuple.service.characteristics else { return  }
            for characteristic in characteristics {
                //拿到过滤后的characteristic，读取
                if let readValueForCharacteristics = self.readValueForCharacteristics {
                    if let readCharacteristic = readValueForCharacteristics(characteristic) {
                        tuple.peripheral.readValue(for: readCharacteristic)
                        var isFind = false
                        for characteristic in self.readCharacteristicsArray {
                            if characteristic.uuid.uuidString == readCharacteristic.uuid.uuidString {
                                isFind = true
                                break
                            }
                        }
                        if isFind == false {
                            self.readCharacteristicsArray.append(readCharacteristic)
                        }
                    }
                }
                
                //拿到过滤后的characteristic，设置监听
                if let setNotifyForCharacteristics = self.setNotifyForCharacteristics {
                    var isFind = false
                    if let setCharacteristic = setNotifyForCharacteristics(characteristic) {
                        tuple.peripheral.setNotifyValue(true, for: setCharacteristic)
                        for characteristic in self.notifyCharacteristicsArray {
                            if characteristic.uuid.uuidString == setCharacteristic.uuid.uuidString {
                                isFind = true
                                break
                            }
                        }
                        if isFind == false {
                            self.notifyCharacteristicsArray.append(setCharacteristic)
                        }
                    }
                }
                
                //拿到过滤后的characteristic，保存写入特征
                if let writeForCharacteristics = self.writeForCharacteristics {
                    var isFind = false
                    
                    if let writeCharacteristic = writeForCharacteristics(characteristic) {
                        for characteristic in self.writeCharacteristicsArray {
                            if characteristic.uuid.uuidString == writeCharacteristic.uuid.uuidString {
                                isFind = true
                                break
                            }
                        }
                        if isFind == false {
                            self.writeCharacteristicsArray.append(writeCharacteristic)
                        }
                    }
                }
            }
            self.lock.unlock()
        }
        
        self.localeChangeObserver = NotificationCenter.default.addObserver(forName: .kDidUpdateValueForCharacteristic, object: nil, queue: .main) { (notification) in
            guard let tuple = notification.object as? (peripheral: CBPeripheral,characteristic: CBCharacteristic) else { assertionFailure(); return }
            if let updateValueForCharacteristic = self.updateValueForCharacteristic {
                updateValueForCharacteristic(tuple.characteristic,tuple.characteristic.value)
            }
        }
        
    }
}
