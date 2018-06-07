//
//  ViewController.swift
//  Blue
//
//  Created by Fidetro on 2018/5/25.
//  Copyright © 2018年 Fidetro. All rights reserved.
//

import UIKit
import CoreBluetooth
class ViewController: UIViewController {
    let blue = Blue()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard BlueManager.share.currentState() == .poweredOn else {
            print("请打开蓝牙")
            return
        }
        
        blue.scan(discoverSave: { (_,p,data,_) in
            if p.name == "YUNMAI-SIGNAL-CW" {
                print("找到了")
                return ("称",p)
            }else{
                print(p.name ?? "")
            }
            return nil
        }).connect().done{
            print("连接结束")
            }.discoverServices([CBUUID.init(string: "FFE0"),CBUUID.init(string: "FFE5")], forServices: { (_, service) -> (CBService) in
                return service
            }).done{
                print("发现结束")
            }.discoverCharacteristics(readFor: { (characteristic) -> (CBCharacteristic?) in
                return nil
            }, setNotify: { (characteristic) -> (CBCharacteristic?) in
                if characteristic.uuid.uuidString == "FFE4" {
                    return characteristic
                }
                return nil
            }, writeFor: { (characteristic) -> (CBCharacteristic?) in
                if characteristic.uuid.uuidString == "FFE9" {
                    return characteristic
                }
                return nil
            }).stopScan().update { (_,data) in
                print("data")
                guard let _ = data else {return}
                
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

