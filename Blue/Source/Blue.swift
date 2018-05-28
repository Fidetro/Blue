//
//  Blue.swift
//  Blue
//
//  Created by Fidetro on 2018/5/18.
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
public typealias UpdateValueForCharacteristic = ((_ value:Data?)->())
public typealias Operation = (()->())
public typealias Done = (()->())
class Blue:NSObject,CBCentralManagerDelegate,CBPeripheralDelegate {
    private var savePeripherals = [String:CBPeripheral]()
    private var scanWithServices : ScanWithServices?=nil
    private var discoverSave : DiscoverSave?=nil
    private var discoverConnect : DiscoverConnect?=nil
    private var discoverServices : DiscoverServices?=nil
    private var discoverForServices : DiscoverForServices?=nil
    private var readValueForCharacteristics : ReadValueForCharacteristics?=nil
    private var setNotifyForCharacteristics : SetNotifyForCharacteristics?=nil
    private var writeForCharacteristics : WriteForCharacteristics?=nil
    private var updateValueForCharacteristic : UpdateValueForCharacteristic?=nil
    
    /// 读取特征的数组
    private var readCharacteristicsArray = [(peripheral:CBPeripheral,characteristic:CBCharacteristic)]()
    /// 监听特征的数组
    private var notifyCharacteristicsArray = [(peripheral:CBPeripheral,characteristic:CBCharacteristic)]()
    /// 写入特征的数组
    private var writeCharacteristicsArray = [(peripheral:CBPeripheral,characteristic:CBCharacteristic)]()
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.fidetro.Blue", qos: .utility, attributes: .concurrent)
    let group = DispatchGroup()
    private let sleepSeond = TimeInterval(5)
    
    
    public static let share = Blue()
    private let centralManager = CBCentralManager()
    
    
    private override init() {
        super.init()
        
    }
    
    
    private func async(_ operation:Operation?=nil) {
        group.enter()
        queue.async(group: group,flags: .barrier) {
            self.lock.lock(before: Date.init(timeIntervalSince1970: Date().timeIntervalSince1970+self.sleepSeond))
            
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
    
    /// 扫描外设
    @discardableResult
    public func scan(_ services:[CBUUID]?=nil, discoverSave:DiscoverSave?=nil) -> Blue {
        self.centralManager.delegate = self
        if self.centralManager.state == .poweredOn {
            self.centralManager.scanForPeripherals(withServices: services, options: nil)
        }else{
            scanWithServices = { [weak self](central) in
                self?.centralManager.scanForPeripherals(withServices: services, options: nil)
            }
        }
        self.discoverSave = discoverSave
        
        return self
    }
    /// 连接设备
    @discardableResult
    public func connect() -> Blue {
        async {
            self.discoverConnect = { [weak self](peripheral) in
                
                self?.centralManager.connect(peripheral, options: nil)
            }
            
        }
        
        
        return self
    }
    /// 发现服务
    @discardableResult
    public func discoverServices(_ servicesUUIDs:[CBUUID]?,forServices:DiscoverForServices?=nil) -> Blue {
        async {
            self.discoverServices = { [weak self] (peripheral) in
                peripheral.delegate = self
                peripheral.discoverServices(servicesUUIDs)
                self?.discoverForServices = forServices
            }
            
        }
        return self
    }
    
    /// 这个地方发现特征，没有做UUID过滤
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
        for tuple in writeCharacteristicsArray {
            if tuple.characteristic.uuid.uuidString == characteristicUUID.uuidString {
                tuple.peripheral.writeValue(data, for: tuple.characteristic, type: .withResponse)
                return true
            }
        }
        return false
    }
    
    @discardableResult
    public func stopScan() -> Blue {
        async {
            self.centralManager.stopScan()
            self.lock.unlock()
        }
        
        return self
    }
    
    
}

// MARK: - CBCentralManagerDelegate
extension Blue {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
            if let scanWithServices = scanWithServices {
                scanWithServices(central)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let discoverSave = discoverSave {
            let save = discoverSave(central,peripheral,advertisementData,RSSI)
            //得到过滤之后的外设
            if let save = save {
                //将外设保存
                savePeripherals[save.key] = save.peripheral
                if let discoverConnect = discoverConnect {
                    discoverConnect(save.peripheral)
                }
                
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.lock.unlock()
        if let discoverServices = discoverServices {
            discoverServices(peripheral)
        }
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.lock.unlock()
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.lock.unlock()
    }
    
}

extension Blue {
    
    
    
    //发现服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services  = peripheral.services  else { return  }
        
        for service in services {
            if let discoverForServices = discoverForServices {
                let service = discoverForServices(peripheral,service)
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        self.lock.unlock()
    }
    //发现特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else { return  }
        for characteristic in characteristics {
            print(characteristic.uuid.uuidString)
            //拿到过滤后的characteristic，读取
            if let readValueForCharacteristics = readValueForCharacteristics {
                if let readCharacteristic = readValueForCharacteristics(characteristic) {
                    peripheral.readValue(for: readCharacteristic)
                    var isFind = false
                    for tuple in readCharacteristicsArray {
                        if tuple.peripheral.name == peripheral.name && tuple.characteristic.uuid.uuidString == readCharacteristic.uuid.uuidString {
                            isFind = true
                            break
                        }
                    }
                    if isFind == false {
                        readCharacteristicsArray.append((peripheral: peripheral, characteristic: readCharacteristic))
                    }
                }
            }
            
            //拿到过滤后的characteristic，设置监听
            if let setNotifyForCharacteristics = setNotifyForCharacteristics {
                var isFind = false
                if let setCharacteristic = setNotifyForCharacteristics(characteristic) {
                    peripheral.setNotifyValue(true, for: setCharacteristic)
                    for tuple in notifyCharacteristicsArray {
                        if tuple.peripheral.name == peripheral.name && tuple.characteristic.uuid.uuidString == setCharacteristic.uuid.uuidString {
                            isFind = true
                            break
                        }
                    }
                    if isFind == false {
                        notifyCharacteristicsArray.append((peripheral: peripheral, characteristic: setCharacteristic))
                    }
                }
            }
            
            //拿到过滤后的characteristic，保存写入特征
            if let writeForCharacteristics = writeForCharacteristics {
                var isFind = false
                
                if let writeCharacteristic = writeForCharacteristics(characteristic) {
                    for tuple in writeCharacteristicsArray {
                        if tuple.peripheral.name == peripheral.name && tuple.characteristic.uuid.uuidString == writeCharacteristic.uuid.uuidString {
                            isFind = true
                            break
                        }
                    }
                    if isFind == false {
                        writeCharacteristicsArray.append((peripheral: peripheral, characteristic: writeCharacteristic))
                    }
                }
            }
        }
        self.lock.unlock()
    }
    
    //获取监听的特征值
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            debugPrint("订阅失败: \(error)")
            return
        }
        if characteristic.isNotifying {
            debugPrint("订阅成功")
        } else {
            debugPrint("取消订阅")
        }
        
        
        
    }
    //获取读取的特征值
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let updateValueForCharacteristic = updateValueForCharacteristic {
            updateValueForCharacteristic(characteristic.value)
        }
        
    }
}
