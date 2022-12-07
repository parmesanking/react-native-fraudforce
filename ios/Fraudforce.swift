@objc(Fraudforce)
class Fraudforce: RCTEventEmitter, PerimeterXDelegate {
    
    private var hasListeners:Bool = false
    private var perimeterXStarted:Bool = false
    private var perimeterXStartAttempt:Int16 = 0
    let PX_MAX_START_ATTEMPTS = 10
    func perimeterxDidRequestBlocked(forAppId appId: String) {
        print("Request Blocked Event")
        if (self.hasListeners){
            let data: [String: Any] = [ "appId": appId]
            self.sendEvent(withName: "onPerimeterXRequestBlocked", body: data)
        }
    }
    
    
    func perimeterxDidChallengeSolved(forAppId appId: String) {
        print("Challenge Solved Event")
        if (self.hasListeners){
            let data: [String: Any] = [ "appId": appId]
            self.sendEvent(withName: "onPerimeterXChallengeSolved", body: data)
        }
    }
    
    func perimeterxDidChallengeCancelled(forAppId appId: String) {
        print("Challenge Cancelled Event")
        if (self.hasListeners){
            let data: [String: Any] = [ "appId": appId]
            self.sendEvent(withName: "onPerimeterXChallengeCancelled", body: data)
        }
    }
    
    
    override init() {
        FraudForce.start()
        super.init()
    }
    
    @objc
    func startPerimeterX(_ appId: String,
                           resolve: @escaping RCTPromiseResolveBlock,
                           reject: @escaping  RCTPromiseRejectBlock){
        print("Starting PerimeterX...")
        if (!self.perimeterXStarted && perimeterXStartAttempt < PX_MAX_START_ATTEMPTS ) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                PerimeterX.start(appId: appId, delegate: self, enableDoctorCheck: false) { success, error in
                    self.perimeterXStartAttempt+=1
                    if (self.perimeterXStartAttempt >= self.PX_MAX_START_ATTEMPTS){
                        reject("PX Start error", "Unable to start PerimeterX", error)
                    }else{
                        if !success {
                            // make sure to start the sdk again when it fails (network issue, etc.)
                            print("PerimeterX not started...")
                            self.startPerimeterX(appId, resolve: resolve, reject: reject)
                        }else{
                            print("PerimeterX started...")
                            self.perimeterXStarted = true
                            resolve(nil)
                        }
                    }
                }
            }
        }
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
    override static func requiresMainQueueSetup() -> Bool{
        return true
      }
      
    override func supportedEvents() -> [String]! {
        return ["onPerimeterXRequestBlocked", "onPerimeterXChallengeSolved", "onPerimeterXChallengeCancelled"]
    }
    
    override func startObserving() {
        self.hasListeners = true
    }
    override func stopObserving() {
        self.hasListeners = false
    }
    
   
}
