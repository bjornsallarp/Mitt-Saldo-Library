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

#import "MSLRikskortetServiceDescription.h"
#import "MSLTicketRikskortetServiceProxy.h"

@implementation MSLRikskortetServiceDescription

- (NSString *)serviceIdentifier
{
    return @"Rikskortet";
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSLTicketRikskortetServiceProxy proxyWithUsername:username andPassword:password];
}

- (BOOL)isValidUsernameForService:(NSString *)username validationMessage:(NSString **)message
{
    // Not sure what is required..
    if ([username length] > 2)
        return YES;
    
    *message = @"Du har angivet ett väldigt kort användarnamn, kontrollera att du angett rätt värde.";
    return NO;
}

- (BOOL)isValidPasswordForService:(NSString *)password validationMessage:(NSString **)message
{
    // Not sure what is required..
    if ([password length] > 2)
        return YES;
    
    *message = @"Du har angivet ett väldigt kort lösenord, kontrollera att du angett rätt värde.";
    return NO;
}

@end
