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

#import "MSLSEBServiceDescription.h"
#import "MSLSEBServiceProxy.h"

@implementation MSLSEBServiceDescription

- (NSString *)serviceIdentifier
{
    return @"SEB";
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSLSEBServiceProxy proxyWithUsername:username andPassword:password];
}

@end
