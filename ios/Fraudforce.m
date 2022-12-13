#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
@import PerimeterX_SDK;

@interface RCT_EXTERN_MODULE(Fraudforce , NSObject)

RCT_EXTERN_METHOD(blackbox:(RCTPromiseResolveBlock)resolve
    reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(startPerimeterX:
                  (NSString)appId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXPORT_METHOD(getPerimeterXHeaders:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSDictionary<NSString *, NSString *> *headers = [PerimeterX headersForURLRequestForAppId:nil];
    NSData *data = [NSJSONSerialization dataWithJSONObject:headers options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    resolve(@[json]);
}

RCT_EXPORT_METHOD(handleResponse:(NSString *)response code:(NSInteger)code url:(NSString *)url) {
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:url] statusCode:code HTTPVersion:nil headerFields:nil];
    [PerimeterX handleResponseForAppId:nil data:data response:httpURLResponse];
}

@end
