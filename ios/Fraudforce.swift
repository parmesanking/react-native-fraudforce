@objc(Fraudforce)
class Fraudforce: NSObject {
    
    override init() {
        FraudForce.start()        
    }

    @objc
    func blackbox(_ resolve: RCTPromiseResolveBlock,
                   reject: RCTPromiseRejectBlock)  {
        let str = FraudForce.blackbox()
        print(str)
        resolve(str)
    }
    
    //this component must be already instanced before any JS object rendered
      @objc
      static func requiresMainQueueSetup() -> Bool{
        return true
      }
      
    
}
