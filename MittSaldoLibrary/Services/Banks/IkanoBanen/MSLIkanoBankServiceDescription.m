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

#import "MSLIkanoBankServiceDescription.h"
#import "MSLIkanoBankServiceProxy.h"

@implementation MSLIkanoBankServiceDescription

- (NSString *)serviceIdentifier
{
    return @"Ikano";
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSLIkanoBankServiceProxy proxyWithUsername:username andPassword:password];
}

@end
