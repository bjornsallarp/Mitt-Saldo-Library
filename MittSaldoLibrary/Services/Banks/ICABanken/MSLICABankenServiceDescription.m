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

#import "MSLICABankenServiceDescription.h"
#import "MSLICABankenServiceProxy.h"

@implementation MSLICABankenServiceDescription

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
    return [MSLICABankenServiceProxy proxyWithUsername:username andPassword:password];
}

- (BOOL)isValidUsernameForService:(NSString *)username validationMessage:(NSString **)message
{
    int length = username.length;
    
    if (length == 12) {
        return YES;
    }
    
    *message = @"ICA Banken kräver personnummer i formatet: ÅÅÅÅMMDDXXXX. Kontrollera att det du angivit verkligen är korrekt.";
    return NO;
}

- (NSString *)passwordCaption
{
    return @"Lösenord";
}

@end
