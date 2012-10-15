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

#import "MSIcaCardServiceDescription.h"
#import "MSLICACardServiceProxy.h"

@implementation MSICACardServiceDescription

- (NSString *)serviceIdentifier
{
    return @"ICA Kortet";
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSLICACardServiceProxy proxyWithUsername:username andPassword:password];
}

- (NSString *)usernameCaption
{
    return @"Personnr";
}

- (BOOL)isNumericOnlyUsername
{
    return YES;
}

- (BOOL)isValidUsernameForService:(NSString *)username validationMessage:(NSString **)message
{
    int length = username.length;
    
    if (length == 10 || length == 12) {
        return YES;
    }
    
    *message = @"Ett personummer är antingen 10 eller 12 siffor. Kontrollera att det du angivit verkigen är korrekt.";
    return NO;
}


- (BOOL)isValidPasswordForService:(NSString *)password validationMessage:(NSString **)message
{
    if ([password length] >= 3)
        return YES;
    
    *message = @"Lösenordet bör vara minst 3 tecken långt. Kontrollera att du angivit rätt.";
    return NO;
}

@end
