
var perimeterXStarted:Bool = false
var perimeterXStartAttempt:Int16 = 0

@objc(Fraudforce)
class Fraudforce: RCTEventEmitter, PerimeterXDelegate {
    
    private var hasListeners:Bool = false

    let PX_MAX_START_ATTEMPTS = 10
    
    
    func perimeterxDidRequestBlocked(url: URL?, appId: String) {
        print("Request Blocked Event")
        if (self.hasListeners){
            let data: [String: Any] = [ "appId": appId, "url": url?.absoluteString]
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
    
    func perimeterxHeadersWereUpdated(headers: [String : String], forAppId appId: String) {
        print("New headers available")
        if (self.hasListeners){
            let data: [String: Any] = headers
            self.sendEvent(withName: "onPerimeterXHeadersUpdated", body: data)
        }
    }
    
    
    override init() {
        FraudForce.start()
        super.init()
    }
    
    @objc
    func startPerimeterX(_ appId: String,
                           forDomains:[String],
                           resolve: @escaping RCTPromiseResolveBlock,
                           reject: @escaping  RCTPromiseRejectBlock){
        print("Starting PerimeterX...")
        let policy = PXPolicy()
        // configure the policy instance
        policy.doctorCheckEnabled = false
        policy.urlRequestInterceptionType = PerimeterX_SDK.PXPolicyUrlRequestInterceptionType.none
        policy.set(domains: Set(forDomains), forAppId: appId)
        
        if (perimeterXStarted){
            resolve(nil)
        }else if (perimeterXStartAttempt < PX_MAX_START_ATTEMPTS ) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                do{
                    try PerimeterX.start(appId: appId, delegate: self, policy:policy)
                    
                    print("PerimeterX started...")
                    perimeterXStarted = true
                    resolve(nil)
                    
                } catch {
                    print("Unexpected error: \(error).")
                    perimeterXStartAttempt+=1
                    if (perimeterXStartAttempt >= self.PX_MAX_START_ATTEMPTS){
                        reject("PX Start error", "Unable to start PerimeterX", error)
                    }else{
                        // make sure to start the sdk again when it fails (network issue, etc.)
                        print("PerimeterX not started...")
                        self.startPerimeterX(appId, forDomains: forDomains, resolve: resolve, reject: reject)
                    }
                }
                
            }
        }else{
            reject("PX Start error", "Unable to start PerimeterX",  NSError(domain: "PXError", code: 0, userInfo: ["message":"Too many start attempts"]))
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
        return ["onPerimeterXRequestBlocked", "onPerimeterXChallengeSolved", "onPerimeterXChallengeCancelled","onPerimeterXHeadersUpdated"]
    }
    
    override func startObserving() {
        self.hasListeners = true
    }
    override func stopObserving() {
        self.hasListeners = false
    }
    
   
}
