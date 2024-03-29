#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
@import PerimeterX_SDK;

@interface RCT_EXTERN_MODULE(Fraudforce , NSObject)

RCT_EXTERN_METHOD(blackbox:(RCTPromiseResolveBlock)resolve
    reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(startPerimeterX:(NSString)appId
                  forDomains:(NSArray*)forDomains
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXPORT_METHOD(getPerimeterXHeaders:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSDictionary<NSString *, NSString *> *headers = [PerimeterX headersForURLRequestForAppId:nil];
    resolve(headers);
}


RCT_EXPORT_METHOD(handleResponse:(NSString *)response code:(NSInteger)code url:(NSString *)url                     resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:url] statusCode:code HTTPVersion:nil headerFields:nil];
    BOOL isHandledByPX = [PerimeterX handleResponseWithResponse:httpURLResponse data:data forAppId:nil callback:^(enum PerimeterXChallengeResult result) {
        BOOL handled = result == PerimeterXChallengeResultSolved ? true : false;
        NSLog(@">>>>>> PX handleResponse result %d", handled );
    }];
    NSNumber *result = [NSNumber numberWithBool:isHandledByPX];
    resolve(result);
    
}

@end
