# swift链式调用蓝牙框架  
特点：  
1. 链式调用;
2. 函数有序,例如我们需要在扫描连接设备后，正常情况下，通过代理获取连接成功后的状态，但是现在只需要： 
```
Blue.share.scan(nil, discoverSave: { (_,p,data,_) in
            if p.name == "外设名字" {
                return p
            }else{
            }
            return nil
        }).connect().stopScan()
```
这一点通过锁实现  

目前还有很多可以优化的点，如果你需要多设备同时连接，不建议使用这个库  

