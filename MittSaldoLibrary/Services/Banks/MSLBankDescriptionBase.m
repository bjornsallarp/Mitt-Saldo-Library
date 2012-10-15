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

#import "MSLBankDescriptionBase.h"

@implementation MSLBankDescriptionBase

- (NSString *)serviceIdentifier
{
    NSLog(@"Not implemented metod: serviceIdentifier");
    exit(1);
}

- (NSString *)serviceName
{
    return [self serviceIdentifier];
}

- (BOOL)isBank
{
    return YES;
}

- (BOOL)isCard
{
    return NO;
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
    if (password.length > 3) {
        return YES;
    }
    
    *message = @"Ett lösenord bör ha fler än 3 siffror eller bokstäver. Kontrollera att du angivit rätt lösenord.";
    return NO;
}

- (NSString *)usernameCaption
{
    return @"Personnr";
}

- (NSString *)passwordCaption
{
    return @"Pers.kod";    
}

@end
