//
//  LFTests.m
//  MittSaldoLibrary
//
//  Created by Sållarp on 7/15/13.
//  Copyright (c) 2013 Björn Sållarp. All rights reserved.
//

#import "LFTests.h"
#import "MSLHiddenInputsParser.h"
#import "MSLLansforsakringarAccountParser.h"
#import "NSString+MSLHtmlStripScriptTag.h"
#import "MSLParsedAccount.h"

@implementation LFTests

- (void)testLFLoginParser
{
    MSLHiddenInputsParser *parser = [[MSLHiddenInputsParser alloc] init];
    
    NSError *error = nil;
    
    NSData *htmlData = [self dataForFileWithName:@"lansforsakringar-login"];
    
    [parser parseXMLData:htmlData parseError:&error];
    
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"__EVENTTARGET"], @"a", nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"__EVENTARGUMENT"], @"b", nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"__LASTFOCUS"], @"c", nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"__VIEWSTATE"], @"/wEPDwUKLTU0MzMxMjEyMA9kFgICAQ9kFhICAQ8PFgIeBFRleHQFEUxPR0dBIElOIC0gUFJJVkFUZGQCAg8QZBAVBQlMw7ZzZW5vcmQHUElOLWtvZAZCYW5rSUQNTW9iaWx0IEJhbmtJRA5Tw6RrZXJoZXRzZG9zYRUFCUzDtnNlbm9yZAdQSU4ta29kBkJhbmtJRA1Nb2JpbHQgQmFua0lEDlPDpGtlcmhldHNkb3NhFCsDBWdnZ2dnFgECAWQCAw8PZBYCHgVzdHlsZQUjcG9zaXRpb246YWJzb2x1dGU7bGVmdDowcHg7dG9wOjBweDtkAgUPZBYEAgEPDxYCHwAFB1BJTi1rb2RkZAIDDw8WAh4JTWF4TGVuZ3RoAgRkZAIHDw8WAh4ISW1hZ2VVcmwFEEltYWdlcy9sb2dpbi5naWZkZAIIDw8WAh8AZWRkAgkPDxYCHgdWaXNpYmxlaGRkAgoPDxYCHwRoZGQCDA8PFgIfBGhkFgJmDw8WAh8EaGRkGAEFHl9fQ29udHJvbHNSZXF1aXJlUG9zdEJhY2tLZXlfXxYCBQhidG5CcmVhawUIYnRuTG9nSW7i/INEhLYbQo9dUDcyEjIFLg0vpg==", nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"__EVENTVALIDATION"], @"/wEWCwLCg7HHAgKGuPWKBwLB+rn+CALLkY7KBQL5otCBCgK1iuL+BAK/xbqjAgLQ+aSTDwKMxJ/ICwKfkv3hAwLigsKtAfK66kKF2Mh/Obxvolxdw1XDF5oZ", nil);
}

- (void)testLFAccountParser
{
    NSData *htmlData = [self dataForFileWithName:@"lansforsakringar-accounts"];
    NSError *error = nil;
    
    MSLLansforsakringarAccountParser *parser = [[MSLLansforsakringarAccountParser alloc] init];
    [parser parseXMLData:htmlData parseError:&error];
    
    STAssertEquals([parser.parsedAccounts count], 4U, @"There should be 4 accounts");
    
    __block MSLParsedAccount *account;
    [parser.parsedAccounts enumerateObjectsUsingBlock:^(MSLParsedAccount *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.accountName isEqualToString:@"Aktielikvid"]) {
            account = obj;
            *stop = YES;
        }
    }];
    
    STAssertNotNil(account, @"There should be an account named Aktielikvid");
    STAssertEqualObjects(account.amount, @(1000.23), nil);
    STAssertEqualObjects(account.availableAmount, @(900.23), nil);
}

- (NSData *)dataForFileWithName:(NSString *)file
{
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    return htmlData;
}

@end
