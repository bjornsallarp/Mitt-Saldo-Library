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

#import "MSLSkanetrafikenServiceDescription.h"
#import "MSLSkanetrafikenServiceProxy.h"

@implementation MSLSkanetrafikenServiceDescription

- (NSString *)serviceIdentifier
{
    return @"Skånetrafiken";
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSLSkanetrafikenServiceProxy proxyWithUsername:username andPassword:password];
}

- (BOOL)isValidUsernameForService:(NSString *)username validationMessage:(NSString **)message
{
    if ([username length] >= 6 && [username length] <= 20)
        return YES;
    
    *message = @"Användarnamnet bör vara 6-20 tecken långt. Kontrollera att du angivit rätt.";
    return NO;
}

- (BOOL)isValidPasswordForService:(NSString *)password validationMessage:(NSString **)message
{
    if ([password length] >= 6 && [password length] <= 20)
        return YES;
    
    *message = @"Lösenordet bör vara 6-20 tecken långt. Kontrollera att du angivit rätt.";
    return NO;
}

@end
