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

#import "MSLLansforsakringarAccountParser.h"
#import "NSScanner+MSLScannerHtmlHelper.h"
#import "MSLParsedAccount.h"

@interface MSLLansforsakringarAccountParser()
- (NSArray *)parseAccountTableRowsFromHtml:(NSString *)html error:(NSError *)error;
@end

@implementation MSLLansforsakringarAccountParser

- (BOOL)parseXMLData:(NSData *)XMLMarkup parseError:(NSError **)error
{
    self.parsedAccounts = [NSMutableArray array];
    
    NSString *html = [[NSString alloc] initWithData:XMLMarkup encoding:NSUTF8StringEncoding];
    NSError *regexError = nil;
    
    NSArray *rowsHtml = [self parseAccountTableRowsFromHtml:html error:regexError];
    
    if (regexError != nil) {
        *error = regexError;
        return NO;
    }
    
    int count = 0;
    for (NSString *rowHtml in rowsHtml) {
        
        NSScanner *scanner = [NSScanner scannerWithString:rowHtml];
        [scanner skipIntoTag:@"a"];
        
        NSString *name;
        [scanner scanUpToString:@"<" intoString:&name];
        
        [scanner skipIntoTag:@"td"];
        [scanner skipIntoTag:@"td"];
        
        NSString *availaleAmount;
        [scanner scanUpToString:@"<" intoString:&availaleAmount];
        
        [scanner skipIntoTag:@"td"];
        
        NSString *amount;
        [scanner scanUpToString:@"<" intoString:&amount];
        
        MSLParsedAccount *account = [[MSLParsedAccount alloc] init];
        account.accountId = @(count);
        account.accountName = name;
        account.amount = [self parseAmountFromString:amount];
        account.availableAmount = [self parseAmountFromString:availaleAmount];

        debug_NSLog(@"Name: %@, Amount: %@, AvailableAmount: %@", name, amount, availaleAmount);
        [self.parsedAccounts addObject:account];
        
        count++;
    }
    
    return YES;
}

- (NSArray *)parseAccountTableRowsFromHtml:(NSString *)html error:(NSError *)error
{
    NSRegularExpression *tableRegex = [NSRegularExpression regularExpressionWithPattern:@"<tbody[\\d\\D]*?accountListDataTable[\\d\\D]*?>[\\d\\D]*?(<tr[\\d\\D]*?>[\\d\\D]*?</tr>)</tbody>" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [tableRegex firstMatchInString:html
                                                         options:0
                                                           range:NSMakeRange(0, [html length])];
    
    NSString *tableRows = [html substringWithRange:[match rangeAtIndex:1]];
    
    NSRegularExpression *rowRegex = [NSRegularExpression regularExpressionWithPattern:@"<tr[\\d\\D]*?>[\\d\\D]*?</tr>" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *rowMatches = [rowRegex matchesInString:tableRows options:0 range:NSMakeRange(0, [tableRows length])];
    
    NSMutableArray *rowsHtml = [NSMutableArray array];
    [rowMatches enumerateObjectsUsingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop) {
        [rowsHtml addObject:[tableRows substringWithRange:[match range]]];
    }];
    
    return rowsHtml;
}

- (NSNumber *)parseAmountFromString:(NSString *)string
{
    NSString *amountString = [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t\n "]];
    amountString = [amountString stringByReplacingOccurrencesOfString:@" " withString:@""];
    amountString = [amountString stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    [f setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"sv_SE"]];
    
    return [f numberFromString:amountString];
}

@end
