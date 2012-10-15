//
//  Created by Björn Sållarp
//  NO Copyright. NO rights reserved.
//
//  Use this code any way you like. If you do like it, please
//  link to my blog and/or write a friendly comment. Thank you!
//
//  Read my blog @ http://blog.sallarp.com
//  Follow me @bjornsallarp
//  Fork me @ http://github.com/bjornsallarp
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

typedef enum {
    MSFormURLParameterEncoding,
    MSJSONParameterEncoding,
} MSHTTPClientParameterEncoding;

@interface MSLNetworkingClient : NSObject
@property (nonatomic, strong) NSString *userAgent;

+ (MSLNetworkingClient *)sharedClient;

- (void)enqueueRequest:(NSMutableURLRequest *)request cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block;

- (void)postRequestWithURL:(NSURL *)url andParameters:(NSDictionary *)parameters cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block;

- (void)getRequestWithURL:(NSURL *)url cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block;

- (void)postSoapRequestWithURL:(NSURL *)url andSoapAction:(NSString *)soapAction soapBody:(NSString *)soapBody cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block;

- (void)postJSONRequestWithURL:(NSURL *)url andParameters:(NSDictionary *)parameters cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block;

- (void)postJSONRequestWithURL:(NSURL *)url userAgent:(NSString *)userAgent parameters:(NSDictionary *)parameters cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block;

@end
