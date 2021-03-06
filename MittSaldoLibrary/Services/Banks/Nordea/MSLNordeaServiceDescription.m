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

#import "MSLNordeaServiceDescription.h"
#import "MSLNordeaServiceProxy.h"

@implementation MSLNordeaServiceDescription

- (NSString *)serviceIdentifier
{
    return @"Nordea";
}

- (BOOL)isValidUsernameForService:(NSString *)username validationMessage:(NSString **)message
{
    int length = username.length;
    
    if (length == 12) {
        return YES;
    }
    
    *message = @"Nordea kräver personnummer i formatet: ÅÅÅÅMMDDXXXX. Kontrollera att det du angivit verkligen är korrekt.";
    return NO;
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSLNordeaServiceProxy proxyWithUsername:username andPassword:password];
}

@end
