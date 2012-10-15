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

#import "MSLVasttrafikCardServiceDescription.h"
#import "MSLVasttrafikCardServiceProxy.h"

@implementation MSLVasttrafikCardServiceDescription

- (NSString *)serviceIdentifier
{
    return @"Västtrafikkortet";
}

- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [MSLVasttrafikCardServiceProxy proxyWithUsername:username andPassword:password];
}

- (BOOL)isValidUsernameForService:(NSString *)username validationMessage:(NSString **)message
{
    int length = username.length;
    
    if (length >= 4 && length <= 16) {
        NSString *lowercaseUsername = [username lowercaseString];
        for (int i = 0; i < length; i++) {
            char c = [lowercaseUsername characterAtIndex:i];
            if ((isdigit(c) || (c > 97 && c < 122) || c == '.') == NO) {
                *message = @"Användarnamnet bör innehålla små och stora bokstäver (a-z), siffror och '.'";
                return NO;
            }
        }
        
        return YES;
    }
    
    *message = @"Användarnamnet måste innehålla minst 4 tecken, max 16 tecken och får bara innehålla små och stora bokstäver, siffror och '.'";
    return NO;
}

- (BOOL)isValidPasswordForService:(NSString *)password validationMessage:(NSString **)message
{
    int length = password.length;
    
    if (length >= 7 && length <= 12) {
        
        BOOL hasUppercase, hasDigit, hasLowercase = NO;
        for (int i = 0; i < length; i++) {
            
            BOOL isUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[password characterAtIndex:i]];
            if (isUppercase == YES)
                hasUppercase = YES;
            else
                hasLowercase = YES;
            
            if (isdigit([password characterAtIndex:i]))
                hasDigit = YES;
        }
        
        if (!hasDigit || !hasUppercase || !hasLowercase) {
            *message = @"Ett lösenord bör ha minst en stor bokstav, minst en liten bokstav, minst en siffra.";
            return NO;
        }
        
        return YES;
    }
    
    *message = @"Ett lösenord bör ha minst 7 tecken, max 12 tecken, minst en stor bokstav, minst en liten bokstav, minst en siffra.";
    return NO;
}

@end

