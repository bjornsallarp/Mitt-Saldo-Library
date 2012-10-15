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

@interface MSLLansforsakringarServiceProxy : MSLServiceProxyBase
+ (id)proxyWithUsername:(NSString *)username andPassword:(NSString *)password;
@property (nonatomic, strong) NSData *authenticatedResponse;
@property (nonatomic, strong) NSURL *authenticatedURL;
@end
