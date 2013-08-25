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

#import "MSLSLAccessCardServiceDescription.h"
#import "MSLSLAccessCardServiceProxy.h"

@implementation MSLSLAccessCardServiceDescription

- (NSString *)serviceIdentifier
{
    return @"SL Access";
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSLSLAccessCardServiceProxy proxyWithUsername:username andPassword:password];
}

- (NSString *)usernameCaption
{
    return @"Anv.namn";
}

- (BOOL)isNumericOnlyUsername
{
    return NO;
}

- (BOOL)isValidUsernameForService:(NSString *)username validationMessage:(NSString **)message;
{
    if ([username length] >= 4 && [username length] <= 45)
        return YES;
    
    *message = @"Tänk på att användarnamnet är skiftlägeskänsligt. Användarnamnet måste innehålla mellan 4 och 45 tecken.";
    return NO;
}

- (BOOL)isValidPasswordForService:(NSString *)password validationMessage:(NSString **)message
{
    if ([password length] >= 6)
        return YES;
 
    *message = @"Lösenordet måste ha minst 6 tecken och innehålla minst en versal (A-Z), en gemen (a-z) samt en siffra (0-9). Även tecknen @._- är tillåtna.";
    return NO;
}

@end
