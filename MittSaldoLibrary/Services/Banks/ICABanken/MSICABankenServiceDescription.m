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

#import "MSICABankenServiceDescription.h"
#import "MSICABankenServiceProxy.h"

@implementation MSICABankenServiceDescription

- (NSString *)serviceIdentifier
{
    return @"ICA";
}

- (NSString *)serviceName
{
    return @"ICABanken";
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSICABankenServiceProxy proxyWithUsername:username andPassword:password];
}

- (NSString *)passwordCaption
{
    return @"Lösenord";
}

@end
