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
#import "MSLServiceProxyBase.h"

@interface MSLCoopCardServiceProxy : MSLServiceProxyBase
+ (MSLCoopCardServiceProxy *)proxyWithUsername:(NSString *)username andPassword:(NSString *)password;
- (void)fetchRefundSummary:(void (^)(NSDictionary *response))success failure:(MSLServiceFailureBlock)failure;
@property (nonatomic, strong) NSString *authenticationToken;
@property (nonatomic, strong) NSNumber *userId;
@end
