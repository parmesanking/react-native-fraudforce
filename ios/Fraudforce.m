#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>


@interface RCT_EXTERN_MODULE(Fraudforce, NSObject)


RCT_EXTERN_METHOD(blackbox:(RCTPromiseResolveBlock)resolve
    reject:(RCTPromiseRejectBlock)reject)

@end
