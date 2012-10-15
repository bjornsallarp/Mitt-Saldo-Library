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

#import "MSLParsedAccount.h"

@implementation MSLParsedAccount

- (NSNumber *)stringToNumber:(NSString *)stringValue
{
    NSMutableString *strippedAmountString = [NSMutableString string];
    for (int i = 0; i < [stringValue length]; i++) {
        if (isdigit([stringValue characterAtIndex:i]) || [stringValue characterAtIndex:i] == ',' || [stringValue characterAtIndex:i] == '-') {
            [strippedAmountString appendFormat:@"%c", [stringValue characterAtIndex:i]];
        }
    }
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    [f setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"sv_SE"]];
    
    return [f numberFromString:strippedAmountString];    
}

- (void)setAmountWithString:(NSString *)stringValue
{
    self.amount = [self stringToNumber:stringValue];
}

- (void)setAvailableAmountWithString:(NSString *)stringValue
{
    self.availableAmount = [self stringToNumber:stringValue];
}

@end
