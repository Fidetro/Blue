# swift链式调用蓝牙框架  
## 特点：  
1. 链式调用;
2. 函数有序,例如我们需要在扫描连接设备后，正常情况下，通过代理获取连接成功后的状态，但是现在只需要： 
```
    let blue = Blue()
        blue.scan(discoverSave: { (_,p,data,_) in
            if p.name == "YUNMAI-SIGNAL-CW" {
            //过滤外设，返回你要搜索到的外设
            return p
            }
            return nil
        }).connect().discoverServices([CBUUID.init(string: "FFE0"),CBUUID.init(string: "FFE5")], forServices: { (_, service) -> (CBService) in
                //返回你要发现特征的服务
                return service
            }).discoverCharacteristics(readFor: { (characteristic) -> (CBCharacteristic?) in
                return nil
            }, setNotify: { (characteristic) -> (CBCharacteristic?) in
                if characteristic.uuid.uuidString == "FFE4" {
                    //返回你要监听的特征
                    return characteristic
                }
                return nil
            }, writeFor: { (characteristic) -> (CBCharacteristic?) in
                if characteristic.uuid.uuidString == "FFE9" {
                    return characteristic
                }
                return nil
            }).stopScan().update { [weak self](_,data) in
                guard let data = data else {return}
                //得到监听和读取特征的value
        }
```
3. 支持多设备连接 
对应一个Blue对象管理一个外设  
![](https://github.com/Fidetro/Blue/tree/master/src/1.jpeg)  
4. 链式异步等待  
例如简单的一个发现设备，连接设备之后停止扫描
```
    let blue = Blue()
        blue.scan(discoverSave: { (_,p,data,_) in
            if p.name == "YUNMAI-SIGNAL-CW" {
            //过滤外设，返回你要搜索到的外设
            return p
            }
            return nil
        }).connect().stopScan()
```
# 安装
## CocoaPod
SwiftFFDB 可以通过Cocoapod集成到你的工程中：
```
$ vim Podfile
```
在podfile中增加下面的内容:
```
platform :ios, '8.0'
target 'YouApp' do
use_frameworks!
pod 'Blue'
end
```