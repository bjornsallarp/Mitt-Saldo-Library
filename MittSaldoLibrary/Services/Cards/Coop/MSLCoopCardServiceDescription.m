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

#import "MSLCoopCardServiceDescription.h"
#import "MSLCoopCardServiceProxy.h"

@implementation MSLCoopCardServiceDescription

- (NSString *)serviceIdentifier
{
    return @"Coop-kortet";
}

- (NSString *)serviceName
{
    return @"Coop";
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSLCoopCardServiceProxy proxyWithUsername:username andPassword:password];
}

- (BOOL)isValidUsernameForService:(NSString *)username validationMessage:(NSString **)message
{
    if ([username length] > 3)
        return YES;
    
    *message = @"Du har angivet ett kort användarnamn, kontrollera att du angett rätt värde.";
    return NO;
}

- (BOOL)isValidPasswordForService:(NSString *)password validationMessage:(NSString **)message
{
    if ([password length] >= 6)
        return YES;
    
    *message = @"Ett lösenord bör vara åtminstone 6 tecken. Kontroller att du angett rätt värde.";
    return NO;
}

@end
